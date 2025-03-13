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
ime: bool = false,

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

const OperandName = enum {
    af,
    bc,
    de,
    hl,
    a,
    b,
    c,
    d,
    e,
    h,
    l,
    sp,
    pc,
    a16,
    n8,
};

const Operand = union {
    r8: *u8,
    r16: *u16,
    a16: u8,
    n8: u8,
};

fn op(self: *CPU, comptime name: OperandName) Operand {
    return switch (name) {
        .a => Operand{ .r8 = &self.af.parts.a },
        .b => Operand{ .r8 = &self.bc.parts.hi },
        .c => Operand{ .r8 = &self.bc.parts.lo },
        .d => Operand{ .r8 = &self.de.parts.hi },
        .e => Operand{ .r8 = &self.de.parts.lo },
        .h => Operand{ .r8 = &self.hl.parts.hi },
        .l => Operand{ .r8 = &self.hl.parts.lo },
        .a16 => Operand{ .a16 = self.readMem(self.popPC(u16)) },
        .n8 => Operand{ .n8 = self.popPC(u8) },
        .af => Operand{ .r16 = &self.af.whole },
        .bc => Operand{ .r16 = &self.bc.whole },
        .de => Operand{ .r16 = &self.de.whole },
        .hl => Operand{ .r16 = &self.hl.whole },
        .sp => Operand{ .r16 = &self.sp },
        .pc => Operand{ .r16 = &self.pc },
    };
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

fn clearFlags(cpu: *CPU) void {
    cpu.af.parts.z = 0;
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
    cpu.af.parts.c = 0;
}

fn ld_sp_n16(cpu: *CPU) void {
    cpu.sp = cpu.popPC(u16);
}

fn ld_sp_hl(cpu: *CPU) void {
    cpu.sp = cpu.hl.whole;
}

fn ld_a_p_a16(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(cpu.popPC(u16));
}

fn xor(cpu: *CPU, dest: *u8, src: u8) void {
    clearFlags(cpu);
    dest.* = dest.* ^ src;
    cpu.af.parts.z = @intFromBool(dest.* == 0);
}

fn xor_r8_r8(dest_name: OperandName, src_name: OperandName) OpHandler {
    return struct {
        fn xor_r8(cpu: *CPU) void {
            const dest = cpu.op(dest_name).r8;
            const src = cpu.op(src_name).r8;
            xor(cpu, dest, src.*);
        }
    }.xor_r8;
}

fn xor_a_n8(cpu: *CPU) void {
    xor(cpu, cpu.op(.a).r8, cpu.popPC(u8));
}

fn xor_a_p_hl(cpu: *CPU) void {
    xor(cpu, cpu.op(.a).r8, cpu.readMem(cpu.hl.whole));
}

fn or_a_p_hl(cpu: *CPU) void {
    clearFlags(cpu);
    cpu.op(.a).r8.* |= cpu.readMem(cpu.hl.whole);
    cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
}

fn or_a_a(cpu: *CPU) void {
    clearFlags(cpu);
    cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
}

fn or_a_c(cpu: *CPU) void {
    clearFlags(cpu);
    cpu.op(.a).r8.* |= cpu.op(.c).r8.*;
    cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
}

fn and_a_n8(cpu: *CPU) void {
    clearFlags(cpu);
    cpu.op(.a).r8.* &= cpu.popPC(u8);
    cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
    cpu.af.parts.h = 1;
}

fn ld_bc_n16(cpu: *CPU) void {
    cpu.bc.whole = cpu.popPC(u16);
}

fn ld_de_n16(cpu: *CPU) void {
    cpu.de.whole = cpu.popPC(u16);
}

fn ld_hl_n16(cpu: *CPU) void {
    cpu.hl.whole = cpu.popPC(u16);
}

fn ld_p_bc_a(cpu: *CPU) void {
    cpu.writeMem(cpu.bc.whole, cpu.op(.a).r8.*);
}

fn ld_p_de_a(cpu: *CPU) void {
    cpu.writeMem(cpu.de.whole, cpu.op(.a).r8.*);
}

fn ld_p_hld_a(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.a).r8.*);
    cpu.hl.whole -%= 1;
}

fn ld_p_hl_a(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.a).r8.*);
}

fn ld_p_hl_b(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.b).r8.*);
}

fn ld_p_hl_c(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.c).r8.*);
}

fn ld_p_hl_d(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.d).r8.*);
}
fn ld_p_hl_e(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.e).r8.*);
}

fn ld_p_hl_h(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.h).r8.*);
}

fn ld_p_hl_l(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.l).r8.*);
}

fn ld_p_a16_a(cpu: *CPU) void {
    cpu.writeMem(cpu.popPC(u16), cpu.op(.a).r8.*);
}

fn ld_a_n8(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.popPC(u8);
}

fn ld_d_n8(cpu: *CPU) void {
    cpu.op(.d).r8.* = cpu.popPC(u8);
}

fn ld_e_n8(cpu: *CPU) void {
    cpu.op(.e).r8.* = cpu.popPC(u8);
}

fn ld_h_n8(cpu: *CPU) void {
    cpu.op(.h).r8.* = cpu.popPC(u8);
}

fn ld_l_n8(cpu: *CPU) void {
    cpu.op(.l).r8.* = cpu.popPC(u8);
}

fn ld_r8_r8(dest: OperandName, src: OperandName) OpHandler {
    return struct {
        fn ld(cpu: *CPU) void {
            cpu.op(dest).r8.* = cpu.op(src).r8.*;
        }
    }.ld;
}

fn ld_p_a16_sp(cpu: *CPU) void {
    const addr = cpu.popPC(u16);
    cpu.writeMem(addr, @truncate(cpu.sp));
    cpu.writeMem(addr, @truncate(cpu.sp >> 8));
}

fn ld_a_p_de(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(cpu.de.whole);
}

fn ld_c_n8(cpu: *CPU) void {
    cpu.op(.c).r8.* = cpu.popPC(u8);
}

fn ldh_p_c_a(cpu: *CPU) void {
    cpu.writeMem(0xFF00 + @as(u16, cpu.op(.c).r8.*), cpu.op(.a).r8.*);
}

fn ldh_p_a8_a(cpu: *CPU) void {
    cpu.writeMem(0xFF00 + @as(u16, cpu.popPC(u8)), cpu.op(.a).r8.*);
}

fn ldh_a_p_a8(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(0xFF00 + @as(u16, cpu.popPC(u8)));
}

fn ld_b_p_hl(cpu: *CPU) void {
    cpu.op(.b).r8.* = cpu.readMem(cpu.hl.whole);
}

fn ld_c_p_hl(cpu: *CPU) void {
    cpu.op(.c).r8.* = cpu.readMem(cpu.hl.whole);
}

fn ld_d_p_hl(cpu: *CPU) void {
    cpu.op(.d).r8.* = cpu.readMem(cpu.hl.whole);
}

fn ld_l_p_hl(cpu: *CPU) void {
    cpu.op(.l).r8.* = cpu.readMem(cpu.hl.whole);
}

fn ld_a_p_hli(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(cpu.hl.whole);
    cpu.hl.whole +%= 1;
}

fn ld_p_hli_a(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.op(.a).r8.*);
    cpu.hl.whole +%= 1;
}

fn ld_b_n8(cpu: *CPU) void {
    cpu.op(.b).r8.* = cpu.popPC(u8);
}

fn prefix(cpu: *CPU) void {
    cpu.prefixed = true;
}

fn bit_7_h(cpu: *CPU) void {
    cpu.bit_test(7, cpu.op(.h).r8.*);
}

fn inc_r8(cpu: *CPU, r8: *u8) void {
    cpu.af.parts.h = @intFromBool(r8.* & 0x0F == 0x0F);
    r8.* +%= 1;
    cpu.af.parts.z = @intFromBool(r8.* == 0);
    cpu.af.parts.n = 0;
}

fn inc_a(cpu: *CPU) void {
    inc_r8(cpu, &cpu.op(.a).r8.*);
}

fn inc_b(cpu: *CPU) void {
    inc_r8(cpu, &cpu.op(.b).r8.*);
}

fn inc_c(cpu: *CPU) void {
    inc_r8(cpu, &cpu.op(.c).r8.*);
}

fn inc_d(cpu: *CPU) void {
    inc_r8(cpu, &cpu.op(.d).r8.*);
}

fn inc_e(cpu: *CPU) void {
    inc_r8(cpu, &cpu.op(.e).r8.*);
}

fn inc_h(cpu: *CPU) void {
    inc_r8(cpu, &cpu.op(.h).r8.*);
}

fn inc_l(cpu: *CPU) void {
    inc_r8(cpu, &cpu.op(.l).r8.*);
}

fn inc_bc(cpu: *CPU) void {
    cpu.bc.whole +%= 1;
}

fn inc_de(cpu: *CPU) void {
    cpu.de.whole +%= 1;
}

fn inc_hl(cpu: *CPU) void {
    cpu.hl.whole +%= 1;
}

fn dec_r8(cpu: *CPU, r8: *u8) void {
    cpu.af.parts.h = @intFromBool(r8.* & 0x0F == 0);
    cpu.af.parts.n = 1;
    r8.* -%= 1;
    cpu.af.parts.z = @intFromBool(r8.* == 0);
}

fn dec_r16(name: OperandName) OpHandler {
    return struct {
        fn dec(cpu: *CPU) void {
            cpu.op(name).r16.* -= 1;
        }
    }.dec;
}

fn dec_a(cpu: *CPU) void {
    dec_r8(cpu, &cpu.op(.a).r8.*);
}

fn dec_b(cpu: *CPU) void {
    dec_r8(cpu, &cpu.op(.b).r8.*);
}

fn dec_c(cpu: *CPU) void {
    dec_r8(cpu, &cpu.op(.c).r8.*);
}

fn dec_d(cpu: *CPU) void {
    dec_r8(cpu, &cpu.op(.d).r8.*);
}

fn dec_e(cpu: *CPU) void {
    dec_r8(cpu, &cpu.op(.e).r8.*);
}

fn dec_h(cpu: *CPU) void {
    dec_r8(cpu, &cpu.op(.h).r8.*);
}

fn dec_l(cpu: *CPU) void {
    dec_r8(cpu, &cpu.op(.l).r8.*);
}

fn dec_p_hl(cpu: *CPU) void {
    const val = cpu.readMem(cpu.hl.whole);
    cpu.af.parts.h = @intFromBool(val & 0x0F == 0);
    cpu.af.parts.n = 1;
    cpu.writeMem(cpu.hl.whole, val -% 1);
    cpu.af.parts.z = @intFromBool(val == 0);
}

fn add_a_r8(name: OperandName) OpHandler {
    return struct {
        fn add(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            cpu.af.parts.h = @intFromBool((cpu.op(.a).r8.* & 0x0F) + (r8.* & 0x0F) > 0x0F);
            const result = @addWithOverflow(cpu.op(.a).r8.*, r8.*);
            cpu.op(.a).r8.* = result[0];
            cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
            cpu.af.parts.n = 0;
            cpu.af.parts.c = result[1];
        }
    }.add;
}

fn add_a(cpu: *CPU, val: u8) void {
    cpu.af.parts.h = @intFromBool((cpu.op(.a).r8.* & 0x0F) + (val & 0x0F) > 0x0F);
    const result = @addWithOverflow(cpu.op(.a).r8.*, val);
    cpu.op(.a).r8.* = result[0];
    cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
    cpu.af.parts.n = 0;
    cpu.af.parts.c = result[1];
}

fn add_a_n8(cpu: *CPU) void {
    add_a(cpu, cpu.popPC(u8));
}

fn add_a_p_hl(cpu: *CPU) void {
    add_a(cpu, cpu.readMem(cpu.hl.whole));
}

fn adc_a_n8(cpu: *CPU) void {
    add_a(cpu, cpu.popPC(u8) +% cpu.af.parts.c);
}

fn sub(cpu: *CPU, dest: *u8, less: u8) void {
    cpu.af.parts.c = @intFromBool(less > dest.*);
    cpu.af.parts.h = @intFromBool((dest.* & 0x0F) < (less & 0x0F));
    dest.* -%= less;
    cpu.af.parts.z = @intFromBool(dest.* == 0);
    cpu.af.parts.n = 1;
}

fn sub_a_n8(cpu: *CPU) void {
    sub(cpu, &cpu.op(.a).r8.*, cpu.popPC(u8));
}

fn sub_a_b(cpu: *CPU) void {
    sub(cpu, &cpu.op(.a).r8.*, cpu.op(.b).r8.*);
}

fn rla(cpu: *CPU) void {
    const old_carry = cpu.af.parts.c;
    cpu.af.parts.c = @truncate(cpu.op(.a).r8.* >> 7);
    cpu.op(.a).r8.* <<= 1;
    cpu.op(.a).r8.* |= old_carry;
    cpu.af.parts.z = 0;
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn rra(cpu: *CPU) void {
    const old_carry: u8 = cpu.af.parts.c;
    cpu.af.parts.c = @truncate(cpu.op(.a).r8.*);
    cpu.op(.a).r8.* >>= 1;
    cpu.op(.a).r8.* |= old_carry << 7;
    cpu.af.parts.z = 0;
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn rl_r8(name: OperandName) OpHandler {
    return struct {
        fn rl(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            clearFlags(cpu);
            const old_carry = cpu.af.parts.c;
            cpu.af.parts.c = @truncate(r8.* >> 7);
            r8.* <<= 1;
            r8.* |= old_carry;
            cpu.af.parts.z = @intFromBool(r8.* == 0);
        }
    }.rl;
}

fn rlc_r8(name: OperandName) OpHandler {
    return struct {
        fn rlc(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            clearFlags(cpu);
            const msb = r8.* >> 7;
            cpu.af.parts.c = @truncate(msb);
            r8.* <<= 1;
            r8.* = (r8.* & 0b11111110) | msb;
            cpu.af.parts.z = @intFromBool(r8.* == 0);
        }
    }.rlc;
}

fn rr_r8(cpu: *CPU, r8: *u8) void {
    clearFlags(cpu);
    const old_carry = cpu.af.parts.c;
    cpu.af.parts.c = @truncate(r8.*);
    r8.* >>= 1;
    r8.* |= @as(u8, old_carry) << 7;
    cpu.af.parts.z = @intFromBool(cpu.op(.c).r8.* == 0);
}

fn rr_a(cpu: *CPU) void {
    rr_r8(cpu, &cpu.op(.a).r8.*);
}

fn rr_b(cpu: *CPU) void {
    rr_r8(cpu, &cpu.op(.b).r8.*);
}

fn rr_c(cpu: *CPU) void {
    rr_r8(cpu, &cpu.op(.c).r8.*);
}

fn rr_d(cpu: *CPU) void {
    rr_r8(cpu, &cpu.op(.d).r8.*);
}

fn rr_e(cpu: *CPU) void {
    rr_r8(cpu, &cpu.op(.e).r8.*);
}

fn rr_h(cpu: *CPU) void {
    rr_r8(cpu, &cpu.op(.h).r8.*);
}

fn rr_l(cpu: *CPU) void {
    rr_r8(cpu, &cpu.op(.l).r8.*);
}

fn srl_r8(cpu: *CPU, r8: *u8) void {
    clearFlags(cpu);
    cpu.af.parts.c = @truncate(r8.*);
    r8.* >>= 1;
    cpu.af.parts.z = @intFromBool(r8.* == 0);
}

fn srl_b(cpu: *CPU) void {
    srl_r8(cpu, &cpu.op(.b).r8.*);
}

fn sra_r8(name: OperandName) OpHandler {
    return struct {
        fn sra(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            clearFlags(cpu);
            cpu.af.parts.c = @truncate(r8.*);
            const sign = r8.* & 0b10000000;
            r8.* >>= 1;
            r8.* |= sign;
            cpu.af.parts.z = @intFromBool(r8.* == 0);
        }
    }.sra;
}

fn call_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, @truncate(cpu.pc >> 8));
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, @truncate(cpu.pc));
    cpu.pc = a16;
}

fn call_nz_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    if (cpu.af.parts.z == 0) {
        cpu.sp -= 1;
        cpu.writeMem(cpu.sp, @truncate(cpu.pc >> 8));
        cpu.sp -= 1;
        cpu.writeMem(cpu.sp, @truncate(cpu.pc));
        cpu.pc = a16;
    }
}

fn push_r16(cpu: *CPU, r16: *u16) void {
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, @truncate(r16.* >> 8));
    cpu.sp -= 1;
    cpu.writeMem(cpu.sp, @truncate(r16.*));
}

fn push_af(cpu: *CPU) void {
    push_r16(cpu, &cpu.af.whole);
}

fn push_bc(cpu: *CPU) void {
    push_r16(cpu, &cpu.bc.whole);
}

fn push_de(cpu: *CPU) void {
    push_r16(cpu, &cpu.de.whole);
}

fn push_hl(cpu: *CPU) void {
    push_r16(cpu, &cpu.hl.whole);
}

fn pop_r16(cpu: *CPU, r16: *u16) void {
    r16.* |= cpu.readMem(cpu.sp);
    cpu.sp += 1;
    r16.* |= @as(u16, cpu.readMem(cpu.sp)) << 8;
    cpu.sp += 1;
}

fn pop_af(cpu: *CPU) void {
    pop_r16(cpu, &cpu.af.whole);
}

fn pop_bc(cpu: *CPU) void {
    pop_r16(cpu, &cpu.bc.whole);
}

fn pop_de(cpu: *CPU) void {
    pop_r16(cpu, &cpu.de.whole);
}

fn pop_hl(cpu: *CPU) void {
    pop_r16(cpu, &cpu.hl.whole);
}

fn jp_a16(cpu: *CPU) void {
    cpu.pc = cpu.popPC(u16);
}

fn jp_hl(cpu: *CPU) void {
    cpu.pc = cpu.hl.whole;
}

fn jr_cc_e8(cpu: *CPU, condition: bool) void {
    const e8 = cpu.popPC(i8);
    if (condition) {
        const pc: i32 = @intCast(cpu.pc);
        cpu.pc = @intCast(pc +% e8);
        cpu.cycles += 4;
    }
}

fn jr_c_e8(cpu: *CPU) void {
    jr_cc_e8(cpu, cpu.af.parts.c == 1);
}

fn jr_nc_e8(cpu: *CPU) void {
    jr_cc_e8(cpu, cpu.af.parts.c == 0);
}

fn jr_nz_e8(cpu: *CPU) void {
    jr_cc_e8(cpu, cpu.af.parts.z == 0);
}

fn jr_z_e8(cpu: *CPU) void {
    jr_cc_e8(cpu, cpu.af.parts.z == 1);
}

fn jr_e8(cpu: *CPU) void {
    const e8 = cpu.popPC(i8);
    const pc: i32 = @intCast(cpu.pc);
    cpu.pc = @intCast(pc +% e8);
    cpu.cycles += 4;
}

fn cp_a_n8(cpu: *CPU) void {
    const n8 = cpu.popPC(u8);
    const result = cpu.op(.a).r8.* -% n8;
    cpu.af.parts.z = @intFromBool(result == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.h = @intFromBool((cpu.op(.a).r8.* & 0x0F) < (n8 & 0x0F));
    cpu.af.parts.c = @intFromBool(cpu.op(.a).r8.* < n8);
}

fn cp_a_p_hl(cpu: *CPU) void {
    const n8 = cpu.readMem(cpu.hl.whole);
    const result = cpu.op(.a).r8.* -% n8;
    cpu.af.parts.z = @intFromBool(result == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.h = @intFromBool((cpu.op(.a).r8.* & 0x0F) < (n8 & 0x0F));
    cpu.af.parts.c = @intFromBool(cpu.op(.a).r8.* < n8);
}

fn ret(cpu: *CPU) void {
    cpu.pc = @as(u16, cpu.readMem(cpu.sp)) | (@as(u16, cpu.readMem(cpu.sp + 1)) << 8);
    cpu.sp += 2;
}

fn ret_nc(cpu: *CPU) void {
    if (cpu.af.parts.c == 0) ret(cpu);
}

fn ret_z(cpu: *CPU) void {
    if (cpu.af.parts.z == 1) ret(cpu);
}

fn di(cpu: *CPU) void {
    cpu.ime = false;
}

const instructions = initInstructions();
const prefixed_instructions = initPrefixedInstructions();

const OpHandler = *const fn (cpu: *CPU) void;

fn initInstructions() [256]OpHandler {
    var instrs = [_]OpHandler{&unhandled} ** 256;

    instrs[0x00] = noop;
    instrs[0x31] = ld_sp_n16;
    instrs[0xAF] = xor_r8_r8(.a, .a);
    instrs[0x21] = ld_hl_n16;
    instrs[0x32] = ld_p_hld_a;
    instrs[0xCB] = prefix;
    instrs[0x20] = jr_nz_e8;
    instrs[0x0E] = ld_c_n8;
    instrs[0x3E] = ld_a_n8;
    instrs[0xE2] = ldh_p_c_a;
    instrs[0x0C] = inc_c;
    instrs[0xE0] = ldh_p_a8_a;
    instrs[0x11] = ld_de_n16;
    instrs[0x1A] = ld_a_p_de;
    instrs[0xCD] = call_a16;
    instrs[0x06] = ld_b_n8;
    instrs[0xC5] = push_bc;
    instrs[0x17] = rla;
    instrs[0xC1] = pop_bc;
    instrs[0x05] = dec_b;
    instrs[0x22] = ld_p_hli_a;
    instrs[0x23] = inc_hl;
    instrs[0xC9] = ret;
    instrs[0x13] = inc_de;
    instrs[0xFE] = cp_a_n8;
    instrs[0xEA] = ld_p_a16_a;
    instrs[0x3D] = dec_a;
    instrs[0x28] = jr_z_e8;
    instrs[0x0D] = dec_c;
    instrs[0x2E] = ld_l_n8;
    instrs[0x18] = jr_e8;
    instrs[0x04] = inc_b;
    instrs[0x1E] = ld_e_n8;
    instrs[0xF0] = ldh_a_p_a8;
    instrs[0x1D] = dec_e;
    instrs[0x24] = inc_h;
    instrs[0x90] = sub_a_b;
    instrs[0x15] = dec_d;
    instrs[0x16] = ld_d_n8;
    instrs[0xBE] = cp_a_p_hl;
    instrs[0x86] = add_a_p_hl;
    instrs[0xC3] = jp_a16;
    instrs[0x47] = ld_r8_r8(.b, .a);
    instrs[0x2A] = ld_a_p_hli;
    instrs[0x12] = ld_p_de_a;
    instrs[0x1C] = inc_e;
    instrs[0x14] = inc_d;
    instrs[0xF3] = di;
    instrs[0xE5] = push_hl;
    instrs[0xE1] = pop_hl;
    instrs[0xF5] = push_af;
    instrs[0xF1] = pop_af;
    instrs[0x01] = ld_bc_n16;
    instrs[0x03] = inc_bc;
    instrs[0x02] = ld_p_bc_a;
    instrs[0xAA] = xor_r8_r8(.a, .d);
    instrs[0xD6] = sub_a_n8;
    instrs[0x30] = jr_nc_e8;
    instrs[0x1F] = rra;
    instrs[0xC6] = add_a_n8;
    instrs[0xD0] = ret_nc;
    instrs[0xC8] = ret_z;
    instrs[0xB6] = or_a_p_hl;
    instrs[0x2D] = dec_l;
    instrs[0x35] = dec_p_hl;
    instrs[0x6E] = ld_l_p_hl;
    instrs[0xB1] = or_a_c;
    instrs[0xFA] = ld_a_p_a16;
    instrs[0xE6] = and_a_n8;
    instrs[0xC4] = call_nz_a16;
    instrs[0x2C] = inc_l;
    instrs[0xA9] = xor_r8_r8(.a, .c);
    instrs[0xCE] = adc_a_n8;
    instrs[0xB7] = or_a_a;
    instrs[0xD5] = push_de;
    instrs[0x46] = ld_b_p_hl;
    instrs[0x4E] = ld_c_p_hl;
    instrs[0x56] = ld_d_p_hl;
    instrs[0xAE] = xor_a_p_hl;
    instrs[0x26] = ld_h_n8;
    instrs[0x38] = jr_c_e8;
    instrs[0x25] = dec_h;
    instrs[0x77] = ld_p_hl_a;
    instrs[0x70] = ld_p_hl_b;
    instrs[0x71] = ld_p_hl_c;
    instrs[0x72] = ld_p_hl_d;
    instrs[0x73] = ld_p_hl_e;
    instrs[0x74] = ld_p_hl_h;
    instrs[0x75] = ld_p_hl_l;
    instrs[0xD1] = pop_de;
    instrs[0xE9] = jp_hl;
    instrs[0xF9] = ld_sp_hl;
    instrs[0x87] = add_a_r8(.a);
    instrs[0x80] = add_a_r8(.b);
    instrs[0x81] = add_a_r8(.c);
    instrs[0x82] = add_a_r8(.d);
    instrs[0x83] = add_a_r8(.e);
    instrs[0x84] = add_a_r8(.h);
    instrs[0x85] = add_a_r8(.l);
    instrs[0x7F] = ld_r8_r8(.a, .a);
    instrs[0x78] = ld_r8_r8(.a, .b);
    instrs[0x79] = ld_r8_r8(.a, .c);
    instrs[0x7A] = ld_r8_r8(.a, .d);
    instrs[0x7B] = ld_r8_r8(.a, .e);
    instrs[0x7C] = ld_r8_r8(.a, .h);
    instrs[0x7D] = ld_r8_r8(.a, .l);
    instrs[0x47] = ld_r8_r8(.b, .a);
    instrs[0x40] = ld_r8_r8(.b, .b);
    instrs[0x41] = ld_r8_r8(.b, .c);
    instrs[0x42] = ld_r8_r8(.b, .d);
    instrs[0x43] = ld_r8_r8(.b, .e);
    instrs[0x44] = ld_r8_r8(.b, .h);
    instrs[0x45] = ld_r8_r8(.b, .l);
    instrs[0x4F] = ld_r8_r8(.c, .a);
    instrs[0x48] = ld_r8_r8(.c, .b);
    instrs[0x49] = ld_r8_r8(.c, .c);
    instrs[0x4A] = ld_r8_r8(.c, .d);
    instrs[0x4B] = ld_r8_r8(.c, .e);
    instrs[0x4C] = ld_r8_r8(.c, .h);
    instrs[0x4D] = ld_r8_r8(.c, .l);
    instrs[0x57] = ld_r8_r8(.d, .a);
    instrs[0x50] = ld_r8_r8(.d, .b);
    instrs[0x51] = ld_r8_r8(.d, .c);
    instrs[0x52] = ld_r8_r8(.d, .d);
    instrs[0x53] = ld_r8_r8(.d, .e);
    instrs[0x54] = ld_r8_r8(.d, .h);
    instrs[0x55] = ld_r8_r8(.d, .l);
    instrs[0x5F] = ld_r8_r8(.e, .a);
    instrs[0x58] = ld_r8_r8(.e, .b);
    instrs[0x59] = ld_r8_r8(.e, .c);
    instrs[0x5A] = ld_r8_r8(.e, .d);
    instrs[0x5B] = ld_r8_r8(.e, .e);
    instrs[0x5C] = ld_r8_r8(.e, .h);
    instrs[0x5D] = ld_r8_r8(.e, .l);
    instrs[0x67] = ld_r8_r8(.h, .a);
    instrs[0x60] = ld_r8_r8(.h, .b);
    instrs[0x61] = ld_r8_r8(.h, .c);
    instrs[0x62] = ld_r8_r8(.h, .d);
    instrs[0x63] = ld_r8_r8(.h, .e);
    instrs[0x64] = ld_r8_r8(.h, .h);
    instrs[0x65] = ld_r8_r8(.h, .l);
    instrs[0x6F] = ld_r8_r8(.l, .a);
    instrs[0x68] = ld_r8_r8(.l, .b);
    instrs[0x69] = ld_r8_r8(.l, .c);
    instrs[0x6A] = ld_r8_r8(.l, .d);
    instrs[0x6B] = ld_r8_r8(.l, .e);
    instrs[0x6C] = ld_r8_r8(.l, .h);
    instrs[0x6D] = ld_r8_r8(.l, .l);
    instrs[0x0B] = dec_r16(.bc);
    instrs[0x1B] = dec_r16(.de);
    instrs[0x2B] = dec_r16(.hl);
    instrs[0x3B] = dec_r16(.sp);
    instrs[0x08] = ld_p_a16_sp;
    instrs[0xEE] = xor_a_n8;

    return instrs;
}

fn initPrefixedInstructions() [256]OpHandler {
    var instrs = [_]OpHandler{&unhandledPrefixed} ** 256;

    instrs[0x7C] = bit_7_h;
    instrs[0x17] = rl_r8(.a);
    instrs[0x10] = rl_r8(.b);
    instrs[0x11] = rl_r8(.c);
    instrs[0x12] = rl_r8(.d);
    instrs[0x13] = rl_r8(.e);
    instrs[0x14] = rl_r8(.h);
    instrs[0x15] = rl_r8(.l);
    instrs[0x38] = srl_b;
    instrs[0x1F] = rr_a;
    instrs[0x18] = rr_b;
    instrs[0x19] = rr_c;
    instrs[0x1A] = rr_d;
    instrs[0x1B] = rr_c;
    instrs[0x1C] = rr_h;
    instrs[0x1D] = rr_l;
    instrs[0x2F] = sra_r8(.a);
    instrs[0x28] = sra_r8(.b);
    instrs[0x29] = sra_r8(.c);
    instrs[0x2A] = sra_r8(.d);
    instrs[0x2B] = sra_r8(.e);
    instrs[0x2C] = sra_r8(.h);
    instrs[0x2D] = sra_r8(.l);
    instrs[0x07] = rlc_r8(.a);
    instrs[0x00] = rlc_r8(.b);
    instrs[0x01] = rlc_r8(.c);
    instrs[0x02] = rlc_r8(.d);
    instrs[0x03] = rlc_r8(.e);
    instrs[0x04] = rlc_r8(.h);
    instrs[0x05] = rlc_r8(.l);

    return instrs;
}

fn unhandled(cpu: *CPU) void {
    std.debug.panic("unhandled opcode: 0x{x:0>2}", .{cpu.peekMem(cpu.pc - 1)});
}

fn unhandledPrefixed(cpu: *CPU) void {
    std.debug.panic("unhandled opcode: (prefix) 0x{x:0>2}", .{cpu.peekMem(cpu.pc - 1)});
}
