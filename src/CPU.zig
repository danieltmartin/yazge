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

pub const TickCallback = struct {
    context: *anyopaque,
    func: *const fn (*anyopaque, u8) void,

    fn call(self: *const TickCallback, cycles: u8) void {
        return self.func(self.context, cycles);
    }
};

const v_blank_interrupt_handler = 0x40;
const lcd_interrupt_handler = 0x48;
const timer_interrupt_handler = 0x50;
const serial_interrupt_handler = 0x58;
const joypad_interrupt_handler = 0x60;

alloc: Allocator,

// Registers
af: AFRegister = AFRegister.init(),
bc: Register = Register.init(),
de: Register = Register.init(),
hl: Register = Register.init(),
sp: u16 = 0,
pc: u16 = 0,
ime: bool = false,

halted: bool = false,
halt_bug: bool = false,

on_tick: TickCallback,

/// The MMU allows reading and writing to memory and I/O devices.
mmu: *MMU,

/// Whether a PREFIX instruction was encountered on the last step, indicating
/// that the next opcode fetched belongs to the extended instruction set.
prefixed: bool = false,

pub fn init(alloc: Allocator, mmu: *MMU, on_tick: TickCallback) !*CPU {
    const cpu = try alloc.create(CPU);
    errdefer alloc.destroy(cpu);

    cpu.* = .{
        .alloc = alloc,
        .mmu = mmu,
        .on_tick = on_tick,
    };

    return cpu;
}

pub fn deinit(self: *CPU) void {
    self.alloc.destroy(self);
}

pub fn step(self: *CPU) void {
    if (self.halt_bug) {
        self.on_tick.call(4);
        self.halt_bug = false;
        return;
    }

    if (self.ime) {
        if (self.halted) {
            self.halted = false;
        }
        if (self.mmu.nextInterrupt(true)) |interrupt_type| {
            self.ime = false;
            const handler_address: u16 = switch (interrupt_type) {
                .v_blank => v_blank_interrupt_handler,
                .lcd => lcd_interrupt_handler,
                .timer => timer_interrupt_handler,
                .serial => serial_interrupt_handler,
                .joypad => joypad_interrupt_handler,
            };
            self.handleInterrupt(handler_address);
            return;
        }
    } else if (self.halted) {
        if (self.mmu.nextInterrupt(false) != null) {
            self.halted = false;
        }
        self.on_tick.call(4);
        return;
    }

    const opcode = self.popPC(u8);

    if (self.prefixed) {
        self.prefixed = false;
        prefixed_instructions[opcode](self);
    } else {
        instructions[opcode](self);
    }
}

pub fn peekNext(self: *CPU, buf: *[3]u8) struct { sm83.Instruction, []u8 } {
    var pc = self.pc;
    var opcode = self.peekMem(pc);
    var instr = sm83.unprefixed[opcode];
    var num_bytes = instr.bytes;
    if (self.prefixed or instr.mnemonic == sm83.Mnemonic.PREFIX) {
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
            self.pc +%= 1;
            return val;
        },
        u16 => {
            const low = @as(u16, self.readMem(self.pc));
            const high = @as(u16, self.readMem(self.pc +% 1));
            self.pc +%= 2;
            return (high << 8) | low;
        },
        i8 => {
            const val: i8 = @bitCast(self.readMem(self.pc));
            self.pc +%= 1;
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
    self.on_tick.call(4);
    self.mmu.write(pointer, val);
}

pub fn readMem(self: *CPU, pointer: u16) u8 {
    self.on_tick.call(4);
    return self.mmu.read(pointer);
}

pub fn peekMem(self: *CPU, pointer: u16) u8 {
    return self.mmu.read(pointer);
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
        padding: u4,
        c: u1,
        h: u1,
        n: u1,
        z: u1,
        a: u8,
    },
    fn init() AFRegister {
        return AFRegister{ .whole = 0 };
    }
};

fn handleInterrupt(cpu: *CPU, address: u16) void {
    cpu.push_r16(&cpu.pc);
    cpu.pc = address;
    cpu.on_tick.call(12);
}

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

fn ld_hl_sp_plus_e8(cpu: *CPU) void {
    clearFlags(cpu);
    const e8: i8 = @bitCast(cpu.popPC(u8));
    cpu.af.parts.h = @intFromBool((cpu.sp & 0x0F) + (@as(u8, @bitCast(e8)) & 0x0F) > 0x0F);
    cpu.af.parts.c = @intFromBool((cpu.sp & 0xFF) + @as(u8, @bitCast(e8)) > 0xFF);
    const result = @as(i32, @intCast(cpu.sp)) +% e8;
    cpu.hl.whole = @truncate(@as(u32, @bitCast(result)));
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

fn or_a_r8(name: OperandName) OpHandler {
    return struct {
        fn ld(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            clearFlags(cpu);
            cpu.op(.a).r8.* |= r8.*;
            cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
        }
    }.ld;
}

fn or_a_n8(cpu: *CPU) void {
    clearFlags(cpu);
    const n8 = cpu.popPC(u8);
    cpu.af.parts.a |= n8;
    cpu.af.parts.z = @intFromBool(cpu.af.parts.a == 0);
}

fn and_a(cpu: *CPU, val: u8) void {
    clearFlags(cpu);
    cpu.op(.a).r8.* &= val;
    cpu.af.parts.z = @intFromBool(cpu.op(.a).r8.* == 0);
    cpu.af.parts.h = 1;
}

fn and_a_n8(cpu: *CPU) void {
    cpu.and_a(cpu.popPC(u8));
}

fn and_a_p_hl(cpu: *CPU) void {
    cpu.and_a(cpu.readMem(cpu.op(.hl).r16.*));
}

fn and_a_r8(name: OperandName) OpHandler {
    return struct {
        fn and_a_r8(cpu: *CPU) void {
            cpu.and_a(cpu.op(name).r8.*);
        }
    }.and_a_r8;
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

fn ld_p_hl_r8(name: OperandName) OpHandler {
    return struct {
        fn ld(cpu: *CPU) void {
            cpu.writeMem(cpu.hl.whole, cpu.op(name).r8.*);
        }
    }.ld;
}

fn ld_p_hl_n8(cpu: *CPU) void {
    cpu.writeMem(cpu.hl.whole, cpu.popPC(u8));
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

fn ld_r8_p_hl(dest: OperandName) OpHandler {
    return struct {
        fn ld(cpu: *CPU) void {
            cpu.op(dest).r8.* = cpu.readMem(cpu.hl.whole);
        }
    }.ld;
}

fn ld_p_a16_sp(cpu: *CPU) void {
    const addr = cpu.popPC(u16);
    cpu.writeMem(addr, @truncate(cpu.sp));
    cpu.writeMem(addr + 1, @truncate(cpu.sp >> 8));
}

fn ld_a_p_de(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(cpu.de.whole);
}

fn ld_a_p_bc(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(cpu.bc.whole);
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

fn ldh_a_p_c(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(0xFF00 + @as(u16, cpu.op(.c).r8.*));
}

fn ld_a_p_hli(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(cpu.hl.whole);
    cpu.hl.whole +%= 1;
}

fn ld_a_p_hld(cpu: *CPU) void {
    cpu.op(.a).r8.* = cpu.readMem(cpu.hl.whole);
    cpu.hl.whole -%= 1;
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

fn bit_u3_p_hl(bit: u3) OpHandler {
    return struct {
        fn bit_u3_p_hl(cpu: *CPU) void {
            const hl = cpu.op(.hl).r16.*;
            const val = cpu.readMem(hl);
            cpu.bit_test(bit, val);
        }
    }.bit_u3_p_hl;
}

fn bit_u3_r8(bit: u3, name: OperandName) OpHandler {
    return struct {
        fn bit_u3_r8(cpu: *CPU) void {
            const r8 = cpu.op(name).r8.*;
            cpu.bit_test(bit, r8);
        }
    }.bit_u3_r8;
}

fn res_u3_p_hl(bit: u3) OpHandler {
    return struct {
        fn res_u3_r8(cpu: *CPU) void {
            const hl = cpu.op(.hl).r16.*;
            var val = cpu.readMem(hl);
            val &= ~(@as(u8, 1) << bit);
            cpu.writeMem(hl, val);
        }
    }.res_u3_r8;
}

fn res_u3_r8(bit: u3, name: OperandName) OpHandler {
    return struct {
        fn res_u3_r8(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* &= ~(@as(u8, 1) << bit);
        }
    }.res_u3_r8;
}

fn set_u3_p_hl(bit: u3) OpHandler {
    return struct {
        fn set_u3_p_hl(cpu: *CPU) void {
            const hl = cpu.op(.hl).r16.*;
            var val = cpu.readMem(hl);
            val |= (@as(u8, 1) << bit);
            cpu.writeMem(hl, val);
        }
    }.set_u3_p_hl;
}

fn set_u3_r8(bit: u3, name: OperandName) OpHandler {
    return struct {
        fn set_u3_r8(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* |= @as(u8, 1) << bit;
        }
    }.set_u3_r8;
}

fn cpl(cpu: *CPU) void {
    cpu.af.parts.a = ~cpu.af.parts.a;
    cpu.af.parts.n = 1;
    cpu.af.parts.h = 1;
}

fn scf(cpu: *CPU) void {
    cpu.af.parts.c = 1;
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn ccf(cpu: *CPU) void {
    cpu.af.parts.c = ~cpu.af.parts.c;
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn inc_r8(name: OperandName) OpHandler {
    return struct {
        fn inc(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            cpu.af.parts.h = @intFromBool(r8.* & 0x0F == 0x0F);
            r8.* +%= 1;
            cpu.af.parts.z = @intFromBool(r8.* == 0);
            cpu.af.parts.n = 0;
        }
    }.inc;
}

fn inc_r16(name: OperandName) OpHandler {
    return struct {
        fn inc(cpu: *CPU) void {
            const r16 = cpu.op(name).r16;
            r16.* +%= 1;
            cpu.on_tick.call(4);
        }
    }.inc;
}

fn inc_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    const val = cpu.readMem(hl);
    cpu.af.parts.h = @intFromBool(val & 0x0F == 0x0F);
    const out = val +% 1;
    cpu.writeMem(hl, out);
    cpu.af.parts.z = @intFromBool(out == 0);
    cpu.af.parts.n = 0;
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
            cpu.op(name).r16.* -%= 1;
            cpu.on_tick.call(4);
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
    const out = val -% 1;
    cpu.writeMem(cpu.hl.whole, out);
    cpu.af.parts.z = @intFromBool(out == 0);
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

fn add_hl_r16(name: OperandName) OpHandler {
    return struct {
        fn add(cpu: *CPU) void {
            const r16 = cpu.op(name).r16;
            const mask = 0b0000111111111111;
            cpu.af.parts.h = @intFromBool((cpu.op(.hl).r16.* & mask) + (r16.* & mask) > mask);
            const result = @addWithOverflow(cpu.op(.hl).r16.*, r16.*);
            cpu.op(.hl).r16.* = result[0];
            cpu.af.parts.n = 0;
            cpu.af.parts.c = result[1];
            cpu.on_tick.call(4);
        }
    }.add;
}

fn add_sp_e8(cpu: *CPU) void {
    clearFlags(cpu);
    const e8 = cpu.popPC(i8);
    cpu.af.parts.h = @intFromBool((cpu.sp & 0x0F) + (@as(u8, @bitCast(e8)) & 0x0F) > 0x0F);
    cpu.af.parts.c = @intFromBool((cpu.sp & 0xFF) + @as(u8, @bitCast(e8)) > 0xFF);
    const result = @as(i32, @intCast(cpu.sp)) +% e8;
    cpu.sp = @truncate(@as(u32, @bitCast(result)));
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

fn adc(cpu: *CPU, val: u8) void {
    const old_carry = cpu.af.parts.c;
    cpu.af.parts.h = @intFromBool((cpu.af.parts.a & 0x0F) + (val & 0x0F) + old_carry > 0x0F);
    cpu.af.parts.c = @intFromBool(@as(u16, cpu.af.parts.a) + @as(u16, val) + @as(u16, old_carry) > 0xFF);
    cpu.af.parts.a = cpu.af.parts.a +% val +% old_carry;
    cpu.af.parts.z = @intFromBool(cpu.af.parts.a == 0);
    cpu.af.parts.n = 0;
}

fn adc_a_n8(cpu: *CPU) void {
    adc(cpu, cpu.popPC(u8));
}

fn adc_a_p_hl(cpu: *CPU) void {
    cpu.adc(cpu.readMem(cpu.hl.whole));
}

fn adc_a_r8(name: OperandName) OpHandler {
    return struct {
        fn adc_a_r8(cpu: *CPU) void {
            const r8 = cpu.op(name).r8.*;
            adc(cpu, r8);
        }
    }.adc_a_r8;
}

fn sub(cpu: *CPU, dest: *u8, less: u8) void {
    cpu.af.parts.c = @intFromBool(less > dest.*);
    cpu.af.parts.h = @intFromBool((dest.* & 0x0F) < (less & 0x0F));
    dest.* -%= less;
    cpu.af.parts.z = @intFromBool(dest.* == 0);
    cpu.af.parts.n = 1;
}

fn sub_a_n8(cpu: *CPU) void {
    cpu.sub(cpu.op(.a).r8, cpu.popPC(u8));
}

fn sub_a_p_hl(cpu: *CPU) void {
    cpu.sub(cpu.op(.a).r8, cpu.readMem(cpu.op(.hl).r16.*));
}

fn sub_a_r8(name: OperandName) OpHandler {
    return struct {
        fn sub_r8(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            sub(cpu, cpu.op(.a).r8, r8.*);
        }
    }.sub_r8;
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

fn rrc(cpu: *CPU, val: u8) u8 {
    clearFlags(cpu);
    const lsb = val & 1;
    cpu.af.parts.c = @truncate(val);
    var out = val >> 1;
    out |= lsb << 7;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn rrc_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.rrc(cpu.readMem(hl)));
}

fn rrc_r8(name: OperandName) OpHandler {
    return struct {
        fn rrc_r8(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.rrc(r8.*);
        }
    }.rrc_r8;
}

fn rrca(cpu: *CPU) void {
    (comptime rrc_r8(.a))(cpu);
    cpu.af.parts.z = 0;
}

fn rl(cpu: *CPU, val: u8) u8 {
    const old_carry = cpu.af.parts.c;
    clearFlags(cpu);
    cpu.af.parts.c = @truncate(val >> 7);
    var out = val << 1;
    out |= old_carry;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn rl_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.rl(cpu.readMem(hl)));
}

fn rl_r8(name: OperandName) OpHandler {
    return struct {
        fn rl(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.rl(r8.*);
        }
    }.rl;
}

fn rlca(cpu: *CPU) void {
    clearFlags(cpu);
    const msb = cpu.af.parts.a >> 7;
    cpu.af.parts.a <<= 1;
    cpu.af.parts.a |= msb;
    cpu.af.parts.c = @truncate(msb);
}

fn rlc(cpu: *CPU, val: u8) u8 {
    clearFlags(cpu);
    const msb = val >> 7;
    cpu.af.parts.c = @truncate(msb);
    var out = val << 1;
    out = (out & 0b11111110) | msb;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn rlc_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.rlc(cpu.readMem(hl)));
}

fn rlc_r8(name: OperandName) OpHandler {
    return struct {
        fn rlc(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.rlc(r8.*);
        }
    }.rlc;
}

fn rr(cpu: *CPU, val: u8) u8 {
    const old_carry = cpu.af.parts.c;
    clearFlags(cpu);
    cpu.af.parts.c = @truncate(val);
    var out = val >> 1;
    out |= @as(u8, old_carry) << 7;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn rr_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.rr(cpu.readMem(hl)));
}

fn rr_r8(name: OperandName) OpHandler {
    return struct {
        fn rr_r8(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.rr(r8.*);
        }
    }.rr_r8;
}

fn srl(cpu: *CPU, val: u8) u8 {
    clearFlags(cpu);
    cpu.af.parts.c = @truncate(val);
    const out = val >> 1;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn srl_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.srl(cpu.readMem(hl)));
}

fn srl_r8(name: OperandName) OpHandler {
    return struct {
        fn srl(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.srl(r8.*);
        }
    }.srl;
}

fn swap(cpu: *CPU, val: u8) u8 {
    clearFlags(cpu);
    const lsb = val & 0x0F;
    var out = val >> 4;
    out |= lsb << 4;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn swap_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.swap(cpu.readMem(hl)));
}

fn swap_r8(name: OperandName) OpHandler {
    return struct {
        fn swap(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.swap(r8.*);
        }
    }.swap;
}

fn sla(cpu: *CPU, val: u8) u8 {
    clearFlags(cpu);
    cpu.af.parts.c = @truncate(val >> 7);
    const out = val << 1;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn sla_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.sla(cpu.readMem(hl)));
}

fn sla_r8(name: OperandName) OpHandler {
    return struct {
        fn sla(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.sla(r8.*);
        }
    }.sla;
}

fn sra(cpu: *CPU, val: u8) u8 {
    clearFlags(cpu);
    cpu.af.parts.c = @truncate(val);
    const sign = val & 0b10000000;
    var out = val >> 1;
    out |= sign;
    cpu.af.parts.z = @intFromBool(out == 0);
    return out;
}

fn sra_p_hl(cpu: *CPU) void {
    const hl = cpu.op(.hl).r16.*;
    cpu.writeMem(hl, cpu.sra(cpu.readMem(hl)));
}

fn sra_r8(name: OperandName) OpHandler {
    return struct {
        fn sra(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            r8.* = cpu.sra(r8.*);
        }
    }.sra;
}

fn call_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    cpu.sp -%= 1;
    cpu.writeMem(cpu.sp, @truncate(cpu.pc >> 8));
    cpu.sp -%= 1;
    cpu.writeMem(cpu.sp, @truncate(cpu.pc));
    cpu.pc = a16;
}

fn call_cc_a16(cpu: *CPU, condition: bool) void {
    const a16 = cpu.popPC(u16);
    if (condition) {
        cpu.sp -%= 1;
        cpu.writeMem(cpu.sp, @truncate(cpu.pc >> 8));
        cpu.sp -%= 1;
        cpu.writeMem(cpu.sp, @truncate(cpu.pc));
        cpu.pc = a16;
    }
}

fn call_nz_a16(cpu: *CPU) void {
    call_cc_a16(cpu, cpu.af.parts.z == 0);
}

fn call_z_a16(cpu: *CPU) void {
    call_cc_a16(cpu, cpu.af.parts.z == 1);
}

fn call_c_a16(cpu: *CPU) void {
    call_cc_a16(cpu, cpu.af.parts.c == 1);
}

fn call_nc_a16(cpu: *CPU) void {
    call_cc_a16(cpu, cpu.af.parts.c == 0);
}

fn push_r16(cpu: *CPU, r16: *u16) void {
    cpu.sp -%= 1;
    cpu.writeMem(cpu.sp, @truncate(r16.* >> 8));
    cpu.sp -%= 1;
    cpu.writeMem(cpu.sp, @truncate(r16.*));
    cpu.on_tick.call(4);
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
    r16.* = cpu.readMem(cpu.sp);
    cpu.sp +%= 1;
    r16.* = (r16.* & 0x00FF) | (@as(u16, cpu.readMem(cpu.sp)) << 8);
    cpu.sp +%= 1;
    cpu.on_tick.call(4);
}

fn pop_af(cpu: *CPU) void {
    pop_r16(cpu, &cpu.af.whole);
    cpu.af.parts.padding = 0;
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
    cpu.on_tick.call(4);
}

fn jp_hl(cpu: *CPU) void {
    cpu.pc = cpu.hl.whole;
}

fn jp_nz_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    if (cpu.af.parts.z == 0) {
        cpu.pc = a16;
        cpu.on_tick.call(4);
    }
}

fn jp_nc_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    if (cpu.af.parts.c == 0) {
        cpu.pc = a16;
        cpu.on_tick.call(4);
    }
}

fn jp_c_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    if (cpu.af.parts.c == 1) {
        cpu.pc = a16;
        cpu.on_tick.call(4);
    }
}

fn jp_z_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    if (cpu.af.parts.z == 1) {
        cpu.pc = a16;
        cpu.on_tick.call(4);
    }
}

fn jr_cc_e8(cpu: *CPU, condition: bool) void {
    const e8 = cpu.popPC(i8);
    if (condition) {
        const pc: i32 = @intCast(cpu.pc);
        cpu.pc = @intCast(pc +% e8);
        cpu.on_tick.call(4);
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
    cpu.on_tick.call(4);
}

fn cp_a(cpu: *CPU, value: u8) void {
    const result = cpu.op(.a).r8.* -% value;
    cpu.af.parts.z = @intFromBool(result == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.h = @intFromBool((cpu.op(.a).r8.* & 0x0F) < (value & 0x0F));
    cpu.af.parts.c = @intFromBool(cpu.op(.a).r8.* < value);
}

fn cp_a_r8(name: OperandName) OpHandler {
    return struct {
        fn cp(cpu: *CPU) void {
            const r8 = cpu.op(name).r8;
            cp_a(cpu, r8.*);
        }
    }.cp;
}

fn cp_a_n8(cpu: *CPU) void {
    const n8 = cpu.popPC(u8);
    cp_a(cpu, n8);
}

fn cp_a_p_hl(cpu: *CPU) void {
    const n8 = cpu.readMem(cpu.hl.whole);
    const result = cpu.op(.a).r8.* -% n8;
    cpu.af.parts.z = @intFromBool(result == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.h = @intFromBool((cpu.op(.a).r8.* & 0x0F) < (n8 & 0x0F));
    cpu.af.parts.c = @intFromBool(cpu.op(.a).r8.* < n8);
}

fn sbc(cpu: *CPU, val: u8) void {
    const a = cpu.af.parts.a;
    const old_carry = cpu.af.parts.c;
    cpu.af.parts.a -%= val +% old_carry;
    cpu.af.parts.c = @intFromBool(@as(i16, a) - @as(i16, val) - @as(i16, old_carry) < 0x00);
    cpu.af.parts.h = @intFromBool((@as(i16, a) & 0x0F) - (@as(i16, val) & 0x0F) - old_carry < 0x00);
    cpu.af.parts.z = @intFromBool(cpu.af.parts.a == 0);
    cpu.af.parts.n = 1;
}

fn sbc_a_n8(cpu: *CPU) void {
    cpu.sbc(cpu.popPC(u8));
}

fn sbc_a_p_hl(cpu: *CPU) void {
    cpu.sbc(cpu.readMem(cpu.op(.hl).r16.*));
}

fn sbc_a_r8(name: OperandName) OpHandler {
    return struct {
        fn sbc_a_r8(cpu: *CPU) void {
            sbc(cpu, cpu.op(name).r8.*);
        }
    }.sbc_a_r8;
}

fn ret(cpu: *CPU) void {
    cpu.pc = @as(u16, cpu.readMem(cpu.sp)) | (@as(u16, cpu.readMem(cpu.sp +% 1)) << 8);
    cpu.sp +%= 2;
    cpu.on_tick.call(4);
}

fn ret_cc(cpu: *CPU, condition: bool) void {
    cpu.on_tick.call(4);
    if (condition) {
        ret(cpu);
    }
}

fn ret_c(cpu: *CPU) void {
    ret_cc(cpu, cpu.af.parts.c == 1);
}

fn ret_nc(cpu: *CPU) void {
    ret_cc(cpu, cpu.af.parts.c == 0);
}

fn ret_z(cpu: *CPU) void {
    ret_cc(cpu, cpu.af.parts.z == 1);
}

fn ret_nz(cpu: *CPU) void {
    ret_cc(cpu, cpu.af.parts.z == 0);
}

fn rst(vec: u16) OpHandler {
    return struct {
        fn rst(cpu: *CPU) void {
            cpu.sp -%= 1;
            cpu.writeMem(cpu.sp, @truncate(cpu.pc >> 8));
            cpu.sp -%= 1;
            cpu.writeMem(cpu.sp, @truncate(cpu.pc));
            cpu.pc = vec;
        }
    }.rst;
}

fn reti(cpu: *CPU) void {
    ei(cpu);
    ret(cpu);
}

fn ei(cpu: *CPU) void {
    cpu.ime = true;
}

fn di(cpu: *CPU) void {
    cpu.ime = false;
}

fn daa(cpu: *CPU) void {
    var adjust: u8 = 0;
    if (cpu.af.parts.n == 1) {
        if (cpu.af.parts.h == 1) adjust += 0x06;
        if (cpu.af.parts.c == 1) adjust += 0x60;
        cpu.af.parts.a -%= adjust;
    } else {
        if (cpu.af.parts.h == 1 or cpu.af.parts.a & 0x0F > 0x09) adjust += 0x06;
        if (cpu.af.parts.c == 1 or cpu.af.parts.a > 0x99) {
            adjust += 0x60;
            cpu.af.parts.c = 1;
        }
        cpu.af.parts.a +%= adjust;
    }
    cpu.af.parts.z = @intFromBool(cpu.af.parts.a == 0);
    cpu.af.parts.h = 0;
}

fn halt(cpu: *CPU) void {
    if (cpu.mmu.nextInterrupt(false) != null) {
        cpu.halt_bug = true;
        return;
    }
    cpu.halted = true;
}

const instructions = initInstructions();
const prefixed_instructions = initPrefixedInstructions();

const OpHandler = *const fn (cpu: *CPU) void;

fn initInstructions() [256]OpHandler {
    var instrs = [_]OpHandler{&unhandled} ** 256;

    instrs[0x00] = noop;
    instrs[0x01] = ld_bc_n16;
    instrs[0x02] = ld_p_bc_a;
    instrs[0x03] = inc_r16(.bc);
    instrs[0x04] = inc_r8(.b);
    instrs[0x05] = dec_b;
    instrs[0x06] = ld_b_n8;
    instrs[0x07] = rlca;
    instrs[0x08] = ld_p_a16_sp;
    instrs[0x09] = add_hl_r16(.bc);
    instrs[0x0A] = ld_a_p_bc;
    instrs[0x0B] = dec_r16(.bc);
    instrs[0x0C] = inc_r8(.c);
    instrs[0x0D] = dec_c;
    instrs[0x0E] = ld_c_n8;
    instrs[0x0F] = rrca;
    instrs[0x11] = ld_de_n16;
    instrs[0x12] = ld_p_de_a;
    instrs[0x13] = inc_r16(.de);
    instrs[0x14] = inc_r8(.d);
    instrs[0x15] = dec_d;
    instrs[0x16] = ld_d_n8;
    instrs[0x17] = rla;
    instrs[0x18] = jr_e8;
    instrs[0x19] = add_hl_r16(.de);
    instrs[0x1A] = ld_a_p_de;
    instrs[0x1B] = dec_r16(.de);
    instrs[0x1C] = inc_r8(.e);
    instrs[0x1D] = dec_e;
    instrs[0x1E] = ld_e_n8;
    instrs[0x1F] = rra;
    instrs[0x20] = jr_nz_e8;
    instrs[0x21] = ld_hl_n16;
    instrs[0x22] = ld_p_hli_a;
    instrs[0x23] = inc_r16(.hl);
    instrs[0x24] = inc_r8(.h);
    instrs[0x25] = dec_h;
    instrs[0x26] = ld_h_n8;
    instrs[0x27] = daa;
    instrs[0x28] = jr_z_e8;
    instrs[0x29] = add_hl_r16(.hl);
    instrs[0x2A] = ld_a_p_hli;
    instrs[0x2B] = dec_r16(.hl);
    instrs[0x2C] = inc_r8(.l);
    instrs[0x2D] = dec_l;
    instrs[0x2E] = ld_l_n8;
    instrs[0x2F] = cpl;
    instrs[0x30] = jr_nc_e8;
    instrs[0x31] = ld_sp_n16;
    instrs[0x32] = ld_p_hld_a;
    instrs[0x33] = inc_r16(.sp);
    instrs[0x34] = inc_p_hl;
    instrs[0x35] = dec_p_hl;
    instrs[0x36] = ld_p_hl_n8;
    instrs[0x37] = scf;
    instrs[0x38] = jr_c_e8;
    instrs[0x39] = add_hl_r16(.sp);
    instrs[0x3A] = ld_a_p_hld;
    instrs[0x3B] = dec_r16(.sp);
    instrs[0x3C] = inc_r8(.a);
    instrs[0x3D] = dec_a;
    instrs[0x3E] = ld_a_n8;
    instrs[0x3F] = ccf;
    instrs[0x40] = ld_r8_r8(.b, .b);
    instrs[0x41] = ld_r8_r8(.b, .c);
    instrs[0x42] = ld_r8_r8(.b, .d);
    instrs[0x43] = ld_r8_r8(.b, .e);
    instrs[0x44] = ld_r8_r8(.b, .h);
    instrs[0x45] = ld_r8_r8(.b, .l);
    instrs[0x46] = ld_r8_p_hl(.b);
    instrs[0x47] = ld_r8_r8(.b, .a);
    instrs[0x48] = ld_r8_r8(.c, .b);
    instrs[0x49] = ld_r8_r8(.c, .c);
    instrs[0x4A] = ld_r8_r8(.c, .d);
    instrs[0x4B] = ld_r8_r8(.c, .e);
    instrs[0x4C] = ld_r8_r8(.c, .h);
    instrs[0x4D] = ld_r8_r8(.c, .l);
    instrs[0x4E] = ld_r8_p_hl(.c);
    instrs[0x4F] = ld_r8_r8(.c, .a);
    instrs[0x50] = ld_r8_r8(.d, .b);
    instrs[0x51] = ld_r8_r8(.d, .c);
    instrs[0x52] = ld_r8_r8(.d, .d);
    instrs[0x53] = ld_r8_r8(.d, .e);
    instrs[0x54] = ld_r8_r8(.d, .h);
    instrs[0x55] = ld_r8_r8(.d, .l);
    instrs[0x56] = ld_r8_p_hl(.d);
    instrs[0x57] = ld_r8_r8(.d, .a);
    instrs[0x58] = ld_r8_r8(.e, .b);
    instrs[0x59] = ld_r8_r8(.e, .c);
    instrs[0x5A] = ld_r8_r8(.e, .d);
    instrs[0x5B] = ld_r8_r8(.e, .e);
    instrs[0x5C] = ld_r8_r8(.e, .h);
    instrs[0x5D] = ld_r8_r8(.e, .l);
    instrs[0x5E] = ld_r8_p_hl(.e);
    instrs[0x5F] = ld_r8_r8(.e, .a);
    instrs[0x60] = ld_r8_r8(.h, .b);
    instrs[0x61] = ld_r8_r8(.h, .c);
    instrs[0x62] = ld_r8_r8(.h, .d);
    instrs[0x63] = ld_r8_r8(.h, .e);
    instrs[0x64] = ld_r8_r8(.h, .h);
    instrs[0x65] = ld_r8_r8(.h, .l);
    instrs[0x66] = ld_r8_p_hl(.h);
    instrs[0x67] = ld_r8_r8(.h, .a);
    instrs[0x68] = ld_r8_r8(.l, .b);
    instrs[0x69] = ld_r8_r8(.l, .c);
    instrs[0x6A] = ld_r8_r8(.l, .d);
    instrs[0x6B] = ld_r8_r8(.l, .e);
    instrs[0x6C] = ld_r8_r8(.l, .h);
    instrs[0x6D] = ld_r8_r8(.l, .l);
    instrs[0x6E] = ld_r8_p_hl(.l);
    instrs[0x6F] = ld_r8_r8(.l, .a);
    instrs[0x70] = ld_p_hl_r8(.b);
    instrs[0x71] = ld_p_hl_r8(.c);
    instrs[0x72] = ld_p_hl_r8(.d);
    instrs[0x73] = ld_p_hl_r8(.e);
    instrs[0x74] = ld_p_hl_r8(.h);
    instrs[0x75] = ld_p_hl_r8(.l);
    instrs[0x77] = ld_p_hl_r8(.a);
    instrs[0x76] = halt;
    instrs[0x78] = ld_r8_r8(.a, .b);
    instrs[0x79] = ld_r8_r8(.a, .c);
    instrs[0x7A] = ld_r8_r8(.a, .d);
    instrs[0x7B] = ld_r8_r8(.a, .e);
    instrs[0x7C] = ld_r8_r8(.a, .h);
    instrs[0x7D] = ld_r8_r8(.a, .l);
    instrs[0x7E] = ld_r8_p_hl(.a);
    instrs[0x7F] = ld_r8_r8(.a, .a);
    instrs[0x80] = add_a_r8(.b);
    instrs[0x81] = add_a_r8(.c);
    instrs[0x82] = add_a_r8(.d);
    instrs[0x83] = add_a_r8(.e);
    instrs[0x84] = add_a_r8(.h);
    instrs[0x85] = add_a_r8(.l);
    instrs[0x86] = add_a_p_hl;
    instrs[0x87] = add_a_r8(.a);
    instrs[0x88] = adc_a_r8(.b);
    instrs[0x89] = adc_a_r8(.c);
    instrs[0x8A] = adc_a_r8(.d);
    instrs[0x8B] = adc_a_r8(.e);
    instrs[0x8C] = adc_a_r8(.h);
    instrs[0x8D] = adc_a_r8(.l);
    instrs[0x8E] = adc_a_p_hl;
    instrs[0x8F] = adc_a_r8(.a);
    instrs[0x90] = sub_a_r8(.b);
    instrs[0x91] = sub_a_r8(.c);
    instrs[0x92] = sub_a_r8(.d);
    instrs[0x93] = sub_a_r8(.e);
    instrs[0x94] = sub_a_r8(.h);
    instrs[0x95] = sub_a_r8(.l);
    instrs[0x96] = sub_a_p_hl;
    instrs[0x97] = sub_a_r8(.a);
    instrs[0x98] = sbc_a_r8(.b);
    instrs[0x99] = sbc_a_r8(.c);
    instrs[0x9A] = sbc_a_r8(.d);
    instrs[0x9B] = sbc_a_r8(.e);
    instrs[0x9C] = sbc_a_r8(.h);
    instrs[0x9D] = sbc_a_r8(.l);
    instrs[0x9E] = sbc_a_p_hl;
    instrs[0x9F] = sbc_a_r8(.a);
    instrs[0xA0] = and_a_r8(.b);
    instrs[0xA1] = and_a_r8(.c);
    instrs[0xA2] = and_a_r8(.d);
    instrs[0xA3] = and_a_r8(.e);
    instrs[0xA4] = and_a_r8(.h);
    instrs[0xA5] = and_a_r8(.l);
    instrs[0xA6] = and_a_p_hl;
    instrs[0xA7] = and_a_r8(.a);
    instrs[0xA8] = xor_r8_r8(.a, .b);
    instrs[0xA9] = xor_r8_r8(.a, .c);
    instrs[0xAA] = xor_r8_r8(.a, .d);
    instrs[0xAB] = xor_r8_r8(.a, .e);
    instrs[0xAC] = xor_r8_r8(.a, .h);
    instrs[0xAD] = xor_r8_r8(.a, .l);
    instrs[0xAE] = xor_a_p_hl;
    instrs[0xAF] = xor_r8_r8(.a, .a);
    instrs[0xB0] = or_a_r8(.b);
    instrs[0xB1] = or_a_r8(.c);
    instrs[0xB2] = or_a_r8(.d);
    instrs[0xB3] = or_a_r8(.e);
    instrs[0xB4] = or_a_r8(.h);
    instrs[0xB5] = or_a_r8(.l);
    instrs[0xB6] = or_a_p_hl;
    instrs[0xB7] = or_a_r8(.a);
    instrs[0xB8] = cp_a_r8(.b);
    instrs[0xB9] = cp_a_r8(.c);
    instrs[0xBA] = cp_a_r8(.d);
    instrs[0xBB] = cp_a_r8(.e);
    instrs[0xBC] = cp_a_r8(.h);
    instrs[0xBD] = cp_a_r8(.l);
    instrs[0xBE] = cp_a_p_hl;
    instrs[0xBF] = cp_a_r8(.a);
    instrs[0xC0] = ret_nz;
    instrs[0xC1] = pop_bc;
    instrs[0xC2] = jp_nz_a16;
    instrs[0xC3] = jp_a16;
    instrs[0xC4] = call_nz_a16;
    instrs[0xC5] = push_bc;
    instrs[0xC6] = add_a_n8;
    instrs[0xC7] = rst(0x00);
    instrs[0xC8] = ret_z;
    instrs[0xC9] = ret;
    instrs[0xCA] = jp_z_a16;
    instrs[0xCB] = prefix;
    instrs[0xCC] = call_z_a16;
    instrs[0xCD] = call_a16;
    instrs[0xCE] = adc_a_n8;
    instrs[0xCF] = rst(0x08);
    instrs[0xD0] = ret_nc;
    instrs[0xD1] = pop_de;
    instrs[0xD2] = jp_nc_a16;
    instrs[0xD4] = call_nc_a16;
    instrs[0xD5] = push_de;
    instrs[0xD6] = sub_a_n8;
    instrs[0xD7] = rst(0x10);
    instrs[0xD8] = ret_c;
    instrs[0xD9] = reti;
    instrs[0xDA] = jp_c_a16;
    instrs[0xDC] = call_c_a16;
    instrs[0xDE] = sbc_a_n8;
    instrs[0xDF] = rst(0x18);
    instrs[0xE0] = ldh_p_a8_a;
    instrs[0xE1] = pop_hl;
    instrs[0xE2] = ldh_p_c_a;
    instrs[0xE5] = push_hl;
    instrs[0xE6] = and_a_n8;
    instrs[0xE7] = rst(0x20);
    instrs[0xE8] = add_sp_e8;
    instrs[0xE9] = jp_hl;
    instrs[0xEA] = ld_p_a16_a;
    instrs[0xEE] = xor_a_n8;
    instrs[0xEF] = rst(0x28);
    instrs[0xF0] = ldh_a_p_a8;
    instrs[0xF1] = pop_af;
    instrs[0xF2] = ldh_a_p_c;
    instrs[0xF3] = di;
    instrs[0xF5] = push_af;
    instrs[0xF6] = or_a_n8;
    instrs[0xF7] = rst(0x30);
    instrs[0xF8] = ld_hl_sp_plus_e8;
    instrs[0xF9] = ld_sp_hl;
    instrs[0xFA] = ld_a_p_a16;
    instrs[0xFB] = ei;
    instrs[0xFE] = cp_a_n8;
    instrs[0xFF] = rst(0x38);

    return instrs;
}

fn initPrefixedInstructions() [256]OpHandler {
    var instrs = [_]OpHandler{&unhandledPrefixed} ** 256;

    instrs[0x00] = rlc_r8(.b);
    instrs[0x01] = rlc_r8(.c);
    instrs[0x02] = rlc_r8(.d);
    instrs[0x03] = rlc_r8(.e);
    instrs[0x04] = rlc_r8(.h);
    instrs[0x05] = rlc_r8(.l);
    instrs[0x06] = rlc_p_hl;
    instrs[0x07] = rlc_r8(.a);
    instrs[0x08] = rrc_r8(.b);
    instrs[0x09] = rrc_r8(.c);
    instrs[0x0A] = rrc_r8(.d);
    instrs[0x0B] = rrc_r8(.e);
    instrs[0x0C] = rrc_r8(.h);
    instrs[0x0D] = rrc_r8(.l);
    instrs[0x0E] = rrc_p_hl;
    instrs[0x0F] = rrc_r8(.a);
    instrs[0x10] = rl_r8(.b);
    instrs[0x11] = rl_r8(.c);
    instrs[0x12] = rl_r8(.d);
    instrs[0x13] = rl_r8(.e);
    instrs[0x14] = rl_r8(.h);
    instrs[0x15] = rl_r8(.l);
    instrs[0x16] = rl_p_hl;
    instrs[0x17] = rl_r8(.a);
    instrs[0x18] = rr_r8(.b);
    instrs[0x19] = rr_r8(.c);
    instrs[0x1A] = rr_r8(.d);
    instrs[0x1B] = rr_r8(.e);
    instrs[0x1C] = rr_r8(.h);
    instrs[0x1D] = rr_r8(.l);
    instrs[0x1E] = rr_p_hl;
    instrs[0x1F] = rr_r8(.a);
    instrs[0x20] = sla_r8(.b);
    instrs[0x21] = sla_r8(.c);
    instrs[0x22] = sla_r8(.d);
    instrs[0x23] = sla_r8(.e);
    instrs[0x24] = sla_r8(.h);
    instrs[0x25] = sla_r8(.l);
    instrs[0x26] = sla_p_hl;
    instrs[0x27] = sla_r8(.a);
    instrs[0x28] = sra_r8(.b);
    instrs[0x29] = sra_r8(.c);
    instrs[0x2A] = sra_r8(.d);
    instrs[0x2B] = sra_r8(.e);
    instrs[0x2C] = sra_r8(.h);
    instrs[0x2D] = sra_r8(.l);
    instrs[0x2E] = sra_p_hl;
    instrs[0x2F] = sra_r8(.a);
    instrs[0x30] = swap_r8(.b);
    instrs[0x31] = swap_r8(.c);
    instrs[0x32] = swap_r8(.d);
    instrs[0x33] = swap_r8(.e);
    instrs[0x34] = swap_r8(.h);
    instrs[0x35] = swap_r8(.l);
    instrs[0x36] = swap_p_hl;
    instrs[0x37] = swap_r8(.a);
    instrs[0x38] = srl_r8(.b);
    instrs[0x39] = srl_r8(.c);
    instrs[0x3A] = srl_r8(.d);
    instrs[0x3B] = srl_r8(.e);
    instrs[0x3C] = srl_r8(.h);
    instrs[0x3D] = srl_r8(.l);
    instrs[0x3E] = srl_p_hl;
    instrs[0x3F] = srl_r8(.a);
    instrs[0x40] = bit_u3_r8(0, .b);
    instrs[0x41] = bit_u3_r8(0, .c);
    instrs[0x42] = bit_u3_r8(0, .d);
    instrs[0x43] = bit_u3_r8(0, .e);
    instrs[0x44] = bit_u3_r8(0, .h);
    instrs[0x45] = bit_u3_r8(0, .l);
    instrs[0x46] = bit_u3_p_hl(0);
    instrs[0x47] = bit_u3_r8(0, .a);
    instrs[0x48] = bit_u3_r8(1, .b);
    instrs[0x49] = bit_u3_r8(1, .c);
    instrs[0x4A] = bit_u3_r8(1, .d);
    instrs[0x4B] = bit_u3_r8(1, .e);
    instrs[0x4C] = bit_u3_r8(1, .h);
    instrs[0x4D] = bit_u3_r8(1, .l);
    instrs[0x4E] = bit_u3_p_hl(1);
    instrs[0x4F] = bit_u3_r8(1, .a);
    instrs[0x50] = bit_u3_r8(2, .b);
    instrs[0x51] = bit_u3_r8(2, .c);
    instrs[0x52] = bit_u3_r8(2, .d);
    instrs[0x53] = bit_u3_r8(2, .e);
    instrs[0x54] = bit_u3_r8(2, .h);
    instrs[0x55] = bit_u3_r8(2, .l);
    instrs[0x56] = bit_u3_p_hl(2);
    instrs[0x57] = bit_u3_r8(2, .a);
    instrs[0x58] = bit_u3_r8(3, .b);
    instrs[0x59] = bit_u3_r8(3, .c);
    instrs[0x5A] = bit_u3_r8(3, .d);
    instrs[0x5B] = bit_u3_r8(3, .e);
    instrs[0x5C] = bit_u3_r8(3, .h);
    instrs[0x5D] = bit_u3_r8(3, .l);
    instrs[0x5E] = bit_u3_p_hl(3);
    instrs[0x5F] = bit_u3_r8(3, .a);
    instrs[0x60] = bit_u3_r8(4, .b);
    instrs[0x61] = bit_u3_r8(4, .c);
    instrs[0x62] = bit_u3_r8(4, .d);
    instrs[0x63] = bit_u3_r8(4, .e);
    instrs[0x64] = bit_u3_r8(4, .h);
    instrs[0x65] = bit_u3_r8(4, .l);
    instrs[0x66] = bit_u3_p_hl(4);
    instrs[0x67] = bit_u3_r8(4, .a);
    instrs[0x68] = bit_u3_r8(5, .b);
    instrs[0x69] = bit_u3_r8(5, .c);
    instrs[0x6A] = bit_u3_r8(5, .d);
    instrs[0x6B] = bit_u3_r8(5, .e);
    instrs[0x6C] = bit_u3_r8(5, .h);
    instrs[0x6D] = bit_u3_r8(5, .l);
    instrs[0x6E] = bit_u3_p_hl(5);
    instrs[0x6F] = bit_u3_r8(5, .a);
    instrs[0x70] = bit_u3_r8(6, .b);
    instrs[0x71] = bit_u3_r8(6, .c);
    instrs[0x72] = bit_u3_r8(6, .d);
    instrs[0x73] = bit_u3_r8(6, .e);
    instrs[0x74] = bit_u3_r8(6, .h);
    instrs[0x75] = bit_u3_r8(6, .l);
    instrs[0x76] = bit_u3_p_hl(6);
    instrs[0x77] = bit_u3_r8(6, .a);
    instrs[0x78] = bit_u3_r8(7, .b);
    instrs[0x79] = bit_u3_r8(7, .c);
    instrs[0x7A] = bit_u3_r8(7, .d);
    instrs[0x7B] = bit_u3_r8(7, .e);
    instrs[0x7C] = bit_7_h;
    instrs[0x7C] = bit_u3_r8(7, .h);
    instrs[0x7D] = bit_u3_r8(7, .l);
    instrs[0x7E] = bit_u3_p_hl(7);
    instrs[0x7F] = bit_u3_r8(7, .a);
    instrs[0x80] = res_u3_r8(0, .b);
    instrs[0x81] = res_u3_r8(0, .c);
    instrs[0x82] = res_u3_r8(0, .d);
    instrs[0x83] = res_u3_r8(0, .e);
    instrs[0x84] = res_u3_r8(0, .h);
    instrs[0x85] = res_u3_r8(0, .l);
    instrs[0x86] = res_u3_p_hl(0);
    instrs[0x87] = res_u3_r8(0, .a);
    instrs[0x88] = res_u3_r8(1, .b);
    instrs[0x89] = res_u3_r8(1, .c);
    instrs[0x8A] = res_u3_r8(1, .d);
    instrs[0x8B] = res_u3_r8(1, .e);
    instrs[0x8C] = res_u3_r8(1, .h);
    instrs[0x8D] = res_u3_r8(1, .l);
    instrs[0x8E] = res_u3_p_hl(1);
    instrs[0x8F] = res_u3_r8(1, .a);
    instrs[0x90] = res_u3_r8(2, .b);
    instrs[0x91] = res_u3_r8(2, .c);
    instrs[0x92] = res_u3_r8(2, .d);
    instrs[0x93] = res_u3_r8(2, .e);
    instrs[0x94] = res_u3_r8(2, .h);
    instrs[0x95] = res_u3_r8(2, .l);
    instrs[0x96] = res_u3_p_hl(2);
    instrs[0x97] = res_u3_r8(2, .a);
    instrs[0x98] = res_u3_r8(3, .b);
    instrs[0x99] = res_u3_r8(3, .c);
    instrs[0x9A] = res_u3_r8(3, .d);
    instrs[0x9B] = res_u3_r8(3, .e);
    instrs[0x9C] = res_u3_r8(3, .h);
    instrs[0x9D] = res_u3_r8(3, .l);
    instrs[0x9E] = res_u3_p_hl(3);
    instrs[0x9F] = res_u3_r8(3, .a);
    instrs[0xA0] = res_u3_r8(4, .b);
    instrs[0xA1] = res_u3_r8(4, .c);
    instrs[0xA2] = res_u3_r8(4, .d);
    instrs[0xA3] = res_u3_r8(4, .e);
    instrs[0xA4] = res_u3_r8(4, .h);
    instrs[0xA5] = res_u3_r8(4, .l);
    instrs[0xA6] = res_u3_p_hl(4);
    instrs[0xA7] = res_u3_r8(4, .a);
    instrs[0xA8] = res_u3_r8(5, .b);
    instrs[0xA9] = res_u3_r8(5, .c);
    instrs[0xAA] = res_u3_r8(5, .d);
    instrs[0xAB] = res_u3_r8(5, .e);
    instrs[0xAC] = res_u3_r8(5, .h);
    instrs[0xAD] = res_u3_r8(5, .l);
    instrs[0xAE] = res_u3_p_hl(5);
    instrs[0xAF] = res_u3_r8(5, .a);
    instrs[0xB0] = res_u3_r8(6, .b);
    instrs[0xB1] = res_u3_r8(6, .c);
    instrs[0xB2] = res_u3_r8(6, .d);
    instrs[0xB3] = res_u3_r8(6, .e);
    instrs[0xB4] = res_u3_r8(6, .h);
    instrs[0xB5] = res_u3_r8(6, .l);
    instrs[0xB6] = res_u3_p_hl(6);
    instrs[0xB7] = res_u3_r8(6, .a);
    instrs[0xB8] = res_u3_r8(7, .b);
    instrs[0xB9] = res_u3_r8(7, .c);
    instrs[0xBA] = res_u3_r8(7, .d);
    instrs[0xBB] = res_u3_r8(7, .e);
    instrs[0xBC] = res_u3_r8(7, .h);
    instrs[0xBD] = res_u3_r8(7, .l);
    instrs[0xBE] = res_u3_p_hl(7);
    instrs[0xBF] = res_u3_r8(7, .a);
    instrs[0xC0] = set_u3_r8(0, .b);
    instrs[0xC1] = set_u3_r8(0, .c);
    instrs[0xC2] = set_u3_r8(0, .d);
    instrs[0xC3] = set_u3_r8(0, .e);
    instrs[0xC4] = set_u3_r8(0, .h);
    instrs[0xC5] = set_u3_r8(0, .l);
    instrs[0xC6] = set_u3_p_hl(0);
    instrs[0xC7] = set_u3_r8(0, .a);
    instrs[0xC8] = set_u3_r8(1, .b);
    instrs[0xC9] = set_u3_r8(1, .c);
    instrs[0xCA] = set_u3_r8(1, .d);
    instrs[0xCB] = set_u3_r8(1, .e);
    instrs[0xCC] = set_u3_r8(1, .h);
    instrs[0xCD] = set_u3_r8(1, .l);
    instrs[0xCE] = set_u3_p_hl(1);
    instrs[0xCF] = set_u3_r8(1, .a);
    instrs[0xD0] = set_u3_r8(2, .b);
    instrs[0xD1] = set_u3_r8(2, .c);
    instrs[0xD2] = set_u3_r8(2, .d);
    instrs[0xD3] = set_u3_r8(2, .e);
    instrs[0xD4] = set_u3_r8(2, .h);
    instrs[0xD5] = set_u3_r8(2, .l);
    instrs[0xD6] = set_u3_p_hl(2);
    instrs[0xD7] = set_u3_r8(2, .a);
    instrs[0xD8] = set_u3_r8(3, .b);
    instrs[0xD9] = set_u3_r8(3, .c);
    instrs[0xDA] = set_u3_r8(3, .d);
    instrs[0xDB] = set_u3_r8(3, .e);
    instrs[0xDC] = set_u3_r8(3, .h);
    instrs[0xDD] = set_u3_r8(3, .l);
    instrs[0xDE] = set_u3_p_hl(3);
    instrs[0xDF] = set_u3_r8(3, .a);
    instrs[0xE0] = set_u3_r8(4, .b);
    instrs[0xE1] = set_u3_r8(4, .c);
    instrs[0xE2] = set_u3_r8(4, .d);
    instrs[0xE3] = set_u3_r8(4, .e);
    instrs[0xE4] = set_u3_r8(4, .h);
    instrs[0xE5] = set_u3_r8(4, .l);
    instrs[0xE6] = set_u3_p_hl(4);
    instrs[0xE7] = set_u3_r8(4, .a);
    instrs[0xE8] = set_u3_r8(5, .b);
    instrs[0xE9] = set_u3_r8(5, .c);
    instrs[0xEA] = set_u3_r8(5, .d);
    instrs[0xEB] = set_u3_r8(5, .e);
    instrs[0xEC] = set_u3_r8(5, .h);
    instrs[0xED] = set_u3_r8(5, .l);
    instrs[0xEE] = set_u3_p_hl(5);
    instrs[0xEF] = set_u3_r8(5, .a);
    instrs[0xF0] = set_u3_r8(6, .b);
    instrs[0xF1] = set_u3_r8(6, .c);
    instrs[0xF2] = set_u3_r8(6, .d);
    instrs[0xF3] = set_u3_r8(6, .e);
    instrs[0xF4] = set_u3_r8(6, .h);
    instrs[0xF5] = set_u3_r8(6, .l);
    instrs[0xF6] = set_u3_p_hl(6);
    instrs[0xF7] = set_u3_r8(6, .a);
    instrs[0xF8] = set_u3_r8(7, .b);
    instrs[0xF9] = set_u3_r8(7, .c);
    instrs[0xFA] = set_u3_r8(7, .d);
    instrs[0xFB] = set_u3_r8(7, .e);
    instrs[0xFC] = set_u3_r8(7, .h);
    instrs[0xFD] = set_u3_r8(7, .l);
    instrs[0xFE] = set_u3_p_hl(7);
    instrs[0xFF] = set_u3_r8(7, .a);

    return instrs;
}

fn unhandled(cpu: *CPU) void {
    std.debug.panic("unhandled opcode: 0x{x:0>2}", .{cpu.peekMem(cpu.pc - 1)});
}

fn unhandledPrefixed(cpu: *CPU) void {
    std.debug.panic("unhandled opcode: (prefix) 0x{x:0>2}", .{cpu.peekMem(cpu.pc - 1)});
}
