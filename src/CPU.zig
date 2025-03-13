const CPU = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const sm83 = @import("sm83.zig");
const MMU = @import("MMU.zig");

const CPUError = error{
    UnhandledOpCode,
    UnhandledOperand,
    UnexpectedEnd,
    ProgramCounterOutOfBounds,
};

alloc: Allocator,

// Registers
af: AFRegister = AFRegister.init(),
bc: Register = Register.init(),
de: Register = Register.init(),
hl: Register = Register.init(),
sp: u16 = 0,
pc: u16 = 0,

/// The MMU allows reading and writing to memory and I/O devices.
mmu: *MMU,

/// Whether a PREFIX instruction was encountered on the last step, indicating
/// that the next opcode fetched belongs to the extended instruction set.
prefixed: bool = false,

/// Number of cycles caused by the last executed instruction.
cycles: u8 = 0,

pub fn init(alloc: Allocator, mmu: *MMU) !*CPU {
    const cpu = try alloc.create(CPU);
    errdefer alloc.destroy(cpu);

    cpu.* = .{
        .alloc = alloc,
        .mmu = mmu,
    };

    return cpu;
}

pub fn deinit(self: *CPU) void {
    self.alloc.destroy(self);
}

pub fn step(self: *CPU) u8 {
    self.cycles = 0;

    const opcode = self.popPC(u8);

    if (self.prefixed) {
        self.prefixed = false;
        prefixed_instructions[opcode](self);
    } else {
        instructions[opcode](self);
    }

    return self.cycles;
}

pub fn peekNext(self: *CPU, buf: *[3]u8) struct { sm83.Instruction, []u8 } {
    var pc = self.pc;
    var opcode = self.peekMem(pc);
    var instr = sm83.unprefixed[opcode];
    var num_bytes = instr.bytes;
    if (instr.mnemonic == sm83.Mnemonic.PREFIX) {
        pc += 1;
        opcode = self.peekMem(pc);
        instr = sm83.cbprefixed[opcode];
        num_bytes = instr.bytes - 1;
    }

    buf[0] = opcode;
    for (1..num_bytes) |i| {
        pc += 1;
        buf[i] = self.peekMem(pc);
    }

    return .{ instr, buf[0..num_bytes] };
}

fn printInstruction(self: *CPU, instr: sm83.Instruction) void {
    std.debug.print("{s}", .{
        @tagName(instr.mnemonic),
    });
    for (0..instr.bytes - 1) |i| {
        std.debug.print(" ${x:0>2}", .{self.peekMem(self.pc) + i});
    }
    std.debug.print("\n", .{});
}

fn popPC(self: *CPU, t: anytype) t {
    switch (t) {
        u8 => {
            const val = self.readMem(self.pc);
            self.pc += 1;
            return val;
        },
        u16 => {
            const low = @as(u16, self.readMem(self.pc));
            const high = @as(u16, self.readMem(self.pc + 1));
            self.pc += 2;
            return (high << 8) | low;
        },
        i8 => {
            const val: i8 = @bitCast(self.readMem(self.pc));
            self.pc += 1;
            return val;
        },
        else => @compileError("invalid type"),
    }
}

pub fn dump(self: *CPU, writer: anytype) !void {
    // TODO this is a monstrosity
    try dumpReg(writer, "a", self.af.parts.a);
    try writer.print(", ", .{});
    try dumpReg(writer, "b", self.bc.parts.hi);
    try writer.print(", ", .{});
    try dumpReg(writer, "c", self.bc.parts.lo);
    try writer.print(", ", .{});
    try dumpReg(writer, "d", self.de.parts.hi);
    try writer.print(", ", .{});
    try dumpReg(writer, "e", self.de.parts.lo);
    try writer.print(", ", .{});
    try dumpReg(writer, "h", self.hl.parts.hi);
    try writer.print(", ", .{});
    try dumpReg(writer, "l", self.hl.parts.lo);
    try writer.print(", ", .{});
    try dumpReg(writer, "flag_z", self.af.parts.z);
    try writer.print(", ", .{});
    try dumpReg(writer, "flag_n", self.af.parts.n);
    try writer.print(", ", .{});
    try dumpReg(writer, "flag_h", self.af.parts.h);
    try writer.print(", ", .{});
    try dumpReg(writer, "flag_c", self.af.parts.c);
    try writer.print(", ", .{});
    try dumpReg(writer, "pc", self.pc);
    try writer.print(", ", .{});
    try dumpReg(writer, "sp", self.sp);
    try writer.print("\n", .{});
}

fn dumpReg(writer: anytype, name: []const u8, value: anytype) !void {
    switch (@TypeOf(value)) {
        u1 => try writer.print("{s}={d}", .{ name, value }),
        u8 => try writer.print("{s}=${x:0>2}", .{ name, value }),
        u16 => try writer.print("{s}=${x:0>4}", .{ name, value }),
        else => try writer.print("{s}={d}", .{ name, value }),
    }
}

fn xor(self: *CPU, dest: *u8, v1: u8, v2: u8) void {
    dest.* = v1 ^ v2;
    self.af.parts.z = @intFromBool(dest.* == 0);
    self.af.parts.n = 0;
    self.af.parts.h = 0;
    self.af.parts.c = 0;
}

fn bit_test(self: *CPU, bit: u3, register: u8) void {
    self.af.parts.z = @intFromBool((@as(u8, 1) << bit) & register == 0);
    self.af.parts.n = 0;
    self.af.parts.h = 1;
}

fn writeMem(self: *CPU, pointer: u16, val: u8) void {
    self.cycles += 4;
    self.mmu.writeMem(pointer, val);
}

fn readMem(self: *CPU, pointer: u16) u8 {
    self.cycles += 4;
    return self.mmu.readMem(pointer);
}

fn peekMem(self: *CPU, pointer: u16) u8 {
    return self.mmu.readMem(pointer);
}

const Register = extern union {
    whole: u16,
    parts: packed struct {
        lo: u8,
        hi: u8,
    },

    fn init() Register {
        return Register{ .whole = 0 };
    }
};

const AFRegister = extern union {
    whole: u16,
    parts: packed struct {
        z: u1,
        n: u1,
        h: u1,
        c: u1,
        _: u4,
        a: u8,
    },
    fn init() AFRegister {
        return AFRegister{ .whole = 0 };
    }
};

fn noop(_: *CPU) void {}

fn ld_sp_n16(cpu: *CPU) void {
    cpu.sp = cpu.popPC(u16);
}

fn xor_a_a(cpu: *CPU) void {
    cpu.xor(&cpu.af.parts.a, cpu.af.parts.a, cpu.af.parts.a);
}

fn ld_de_n16(cpu: *CPU) void {
    cpu.de.whole = cpu.popPC(u16);
}

fn ld_hl_n16(cpu: *CPU) void {
    cpu.hl.whole = cpu.popPC(u16);
}

fn ld_p_hld_a(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.af.parts.a);
    cpu.hl.whole -%= 1;
}

fn ld_p_a16_a(cpu: *CPU) void {
    cpu.af.parts.a = cpu.readMem(cpu.popPC(u16));
}

fn ld_a_n8(cpu: *CPU) void {
    cpu.af.parts.a = cpu.popPC(u8);
}

fn ld_d_n8(cpu: *CPU) void {
    cpu.de.parts.hi = cpu.popPC(u8);
}

fn ld_e_n8(cpu: *CPU) void {
    cpu.de.parts.lo = cpu.popPC(u8);
}

fn ld_l_n8(cpu: *CPU) void {
    cpu.hl.parts.lo = cpu.popPC(u8);
}

fn ld_a_p_de(cpu: *CPU) void {
    cpu.af.parts.a = cpu.readMem(cpu.de.whole);
}

fn ld_c_n8(cpu: *CPU) void {
    cpu.bc.parts.lo = cpu.popPC(u8);
}

fn ld_c_a(cpu: *CPU) void {
    cpu.bc.parts.lo = cpu.af.parts.a;
}

fn ld_a_b(cpu: *CPU) void {
    cpu.af.parts.a = cpu.bc.parts.hi;
}

fn ld_a_e(cpu: *CPU) void {
    cpu.af.parts.a = cpu.de.parts.lo;
}

fn ld_a_h(cpu: *CPU) void {
    cpu.af.parts.a = cpu.hl.parts.hi;
}

fn ld_a_l(cpu: *CPU) void {
    cpu.af.parts.a = cpu.hl.parts.lo;
}

fn ld_d_a(cpu: *CPU) void {
    cpu.de.parts.hi = cpu.af.parts.a;
}

fn ld_h_a(cpu: *CPU) void {
    cpu.hl.parts.hi = cpu.af.parts.a;
}

fn ldh_p_c_a(cpu: *CPU) void {
    cpu.writeMem(0xFF00 + @as(u16, cpu.bc.parts.lo), cpu.af.parts.a);
}

fn ldh_p_a8_a(cpu: *CPU) void {
    cpu.writeMem(0xFF00 + @as(u16, cpu.popPC(u8)), cpu.af.parts.a);
}

fn ldh_a_p_a8(cpu: *CPU) void {
    cpu.af.parts.a = cpu.readMem(0xFF00 + @as(u16, cpu.popPC(u8)));
}

fn ld_p_hl_a(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.af.parts.a);
}

fn ld_p_hli_a(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.af.parts.a);
    cpu.hl.whole +%= 1;
}

fn ld_b_n8(cpu: *CPU) void {
    cpu.bc.parts.hi = cpu.popPC(u8);
}

fn prefix(cpu: *CPU) void {
    cpu.prefixed = true;
}

fn bit_7_h(cpu: *CPU) void {
    cpu.bit_test(7, cpu.hl.parts.hi);
}

fn inc_b(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.bc.parts.hi & 0x0F == 0x0F);
    cpu.bc.parts.hi +%= 1;
    cpu.af.parts.z = @intFromBool(cpu.bc.parts.hi == 0);
    cpu.af.parts.n = 0;
}

fn inc_c(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.bc.parts.lo & 0x0F == 0x0F);
    cpu.bc.parts.lo +%= 1;
    cpu.af.parts.z = @intFromBool(cpu.bc.parts.lo == 0);
    cpu.af.parts.n = 0;
}

fn inc_h(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.hl.parts.hi & 0x0F == 0x0F);
    cpu.hl.parts.hi +%= 1;
    cpu.af.parts.z = @intFromBool(cpu.hl.parts.hi == 0);
    cpu.af.parts.n = 0;
}

fn inc_de(cpu: *CPU) void {
    cpu.de.whole +%= 1;
}

fn inc_hl(cpu: *CPU) void {
    cpu.hl.whole +%= 1;
}

fn dec_a(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.af.parts.a & 0x0F == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.a -%= 1;
    cpu.af.parts.z = @intFromBool(cpu.af.parts.a == 0);
}

fn dec_b(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.bc.parts.hi & 0x0F == 0);
    cpu.af.parts.n = 1;
    cpu.bc.parts.hi -%= 1;
    cpu.af.parts.z = @intFromBool(cpu.bc.parts.hi == 0);
}

fn dec_c(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.bc.parts.lo & 0x0F == 0);
    cpu.af.parts.n = 1;
    cpu.bc.parts.lo -%= 1;
    cpu.af.parts.z = @intFromBool(cpu.bc.parts.lo == 0);
}

fn dec_d(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.de.parts.hi & 0x0F == 0);
    cpu.af.parts.n = 1;
    cpu.de.parts.hi -%= 1;
    cpu.af.parts.z = @intFromBool(cpu.de.parts.hi == 0);
}

fn dec_e(cpu: *CPU) void {
    cpu.af.parts.h = @intFromBool(cpu.de.parts.lo & 0x0F == 0);
    cpu.af.parts.n = 1;
    cpu.de.parts.lo -%= 1;
    cpu.af.parts.z = @intFromBool(cpu.de.parts.lo == 0);
}

fn add_a_p_hl(cpu: *CPU) void {
    const val = cpu.readMem(cpu.hl.whole);
    cpu.af.parts.h = @intFromBool((cpu.af.parts.a & 0x0F) + (val & 0x0F) > 0x0F);
    const result = @addWithOverflow(cpu.af.parts.a, val);
    cpu.af.parts.a = result[0];
    cpu.af.parts.z = @intFromBool(cpu.af.parts.a == 0);
    cpu.af.parts.n = 0;
    cpu.af.parts.c = result[1];
}

fn sub_a_b(cpu: *CPU) void {
    cpu.af.parts.c = @intFromBool(cpu.bc.parts.hi > cpu.af.parts.a);
    cpu.af.parts.h = @intFromBool((cpu.af.parts.a & 0x0F) < (cpu.bc.parts.hi & 0x0F));
    cpu.af.parts.a -%= cpu.bc.parts.hi;
    cpu.af.parts.z = @intFromBool(cpu.af.parts.a == 0);
    cpu.af.parts.n = 1;
}

fn rla(cpu: *CPU) void {
    const old_carry = cpu.af.parts.c;
    cpu.af.parts.c = @truncate(cpu.af.parts.a >> 7);
    cpu.af.parts.a <<= 1;
    cpu.af.parts.a |= old_carry;
    cpu.af.parts.z = 0;
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn rl_c(cpu: *CPU) void {
    const old_carry = cpu.af.parts.c;
    cpu.af.parts.c = @truncate(cpu.bc.parts.lo >> 7);
    cpu.bc.parts.lo <<= 1;
    cpu.bc.parts.lo |= old_carry;
    cpu.af.parts.z = @intFromBool(cpu.bc.parts.lo == 0);
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn call_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, @truncate(cpu.pc >> 8));
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, @truncate(cpu.pc));
    cpu.pc = a16;
}

fn push_bc(cpu: *CPU) void {
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, cpu.bc.parts.hi);
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, cpu.bc.parts.lo);
}

fn pop_bc(cpu: *CPU) void {
    cpu.bc.parts.lo = cpu.readMem(cpu.sp);
    cpu.sp += 1;
    cpu.bc.parts.hi = cpu.readMem(cpu.sp);
    cpu.sp += 1;
}

fn jr_nz_e8(cpu: *CPU) void {
    const e8 = cpu.popPC(i8);
    if (cpu.af.parts.z == 0) {
        const pc: i16 = @intCast(cpu.pc);
        cpu.pc = @intCast(pc +% e8);
        cpu.cycles += 4;
    }
}

fn jr_z_e8(cpu: *CPU) void {
    const e8 = cpu.popPC(i8);
    if (cpu.af.parts.z == 1) {
        const pc: i16 = @intCast(cpu.pc);
        cpu.pc = @intCast(pc +% e8);
        cpu.cycles += 4;
    }
}

fn jr_e8(cpu: *CPU) void {
    const e8 = cpu.popPC(i8);
    const pc: i16 = @intCast(cpu.pc);
    cpu.pc = @intCast(pc +% e8);
}

fn cp_a_n8(cpu: *CPU) void {
    const n8 = cpu.popPC(u8);
    const result = cpu.af.parts.a -% n8;
    cpu.af.parts.z = @intFromBool(result == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.h = @intFromBool((cpu.af.parts.a & 0x0F) < (n8 & 0x0F));
    cpu.af.parts.c = @intFromBool(cpu.af.parts.a < n8);
}

fn cp_a_p_hl(cpu: *CPU) void {
    const n8 = cpu.readMem(cpu.hl.whole);
    const result = cpu.af.parts.a -% n8;
    cpu.af.parts.z = @intFromBool(result == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.h = @intFromBool((cpu.af.parts.a & 0x0F) < (n8 & 0x0F));
    cpu.af.parts.c = @intFromBool(cpu.af.parts.a < n8);
}

fn ret(cpu: *CPU) void {
    cpu.pc = @as(u16, cpu.readMem(cpu.sp)) | (@as(u16, cpu.readMem(cpu.sp + 1)) << 8);
    cpu.sp += 2;
}

const instructions = initInstructions();
const prefixed_instructions = initPrefixedInstructions();

const OpHandler = *const fn (cpu: *CPU) void;

fn initInstructions() [256]OpHandler {
    var instrs = [_]OpHandler{&unhandled} ** 256;

    instrs[0x00] = noop;
    instrs[0x31] = ld_sp_n16;
    instrs[0xAF] = xor_a_a;
    instrs[0x21] = ld_hl_n16;
    instrs[0x32] = ld_p_hld_a;
    instrs[0xCB] = prefix;
    instrs[0x20] = jr_nz_e8;
    instrs[0x0E] = ld_c_n8;
    instrs[0x3E] = ld_a_n8;
    instrs[0xE2] = ldh_p_c_a;
    instrs[0x0C] = inc_c;
    instrs[0x77] = ld_p_hl_a;
    instrs[0xE0] = ldh_p_a8_a;
    instrs[0x11] = ld_de_n16;
    instrs[0x1A] = ld_a_p_de;
    instrs[0xCD] = call_a16;
    instrs[0x4F] = ld_c_a;
    instrs[0x06] = ld_b_n8;
    instrs[0xC5] = push_bc;
    instrs[0x17] = rla;
    instrs[0xC1] = pop_bc;
    instrs[0x05] = dec_b;
    instrs[0x22] = ld_p_hli_a;
    instrs[0x23] = inc_hl;
    instrs[0xC9] = ret;
    instrs[0x13] = inc_de;
    instrs[0x7B] = ld_a_e;
    instrs[0xFE] = cp_a_n8;
    instrs[0xEA] = ld_p_a16_a;
    instrs[0x3D] = dec_a;
    instrs[0x28] = jr_z_e8;
    instrs[0x0D] = dec_c;
    instrs[0x2E] = ld_l_n8;
    instrs[0x18] = jr_e8;
    instrs[0x67] = ld_h_a;
    instrs[0x57] = ld_d_a;
    instrs[0x04] = inc_b;
    instrs[0x1E] = ld_e_n8;
    instrs[0xF0] = ldh_a_p_a8;
    instrs[0x1D] = dec_e;
    instrs[0x24] = inc_h;
    instrs[0x7C] = ld_a_h;
    instrs[0x90] = sub_a_b;
    instrs[0x15] = dec_d;
    instrs[0x16] = ld_d_n8;
    instrs[0xBE] = cp_a_p_hl;
    instrs[0x7D] = ld_a_l;
    instrs[0x78] = ld_a_b;
    instrs[0x86] = add_a_p_hl;

    return instrs;
}

fn initPrefixedInstructions() [256]OpHandler {
    var instrs = [_]OpHandler{&unhandled} ** 256;

    instrs[0x7C] = bit_7_h;
    instrs[0x11] = rl_c;

    return instrs;
}

fn unhandled(_: *CPU) void {
    std.debug.panic("unhandled opcode", .{});
}
