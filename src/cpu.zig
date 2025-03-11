const std = @import("std");
const sm83 = @import("sm83.zig");

const rom_bank_0_end = 0x3FFF;

pub const CPU = struct {
    af: AFRegister = AFRegister.init(),
    bc: Register = Register.init(),
    de: Register = Register.init(),
    hl: Register = Register.init(),
    sp: u16 = 0,
    pc: u16 = 0,
    prefixed: bool = false,
    cycles: u3 = 0, // additional cycles caused by last executed instruction

    boot_rom: []u8,
    boot_rom_mapped: bool = true,
    memory: [65536]u8 = std.mem.zeroes([65536]u8),
    dummy: u8 = 0,

    pub fn init(boot_rom: []u8, cartridge_rom: []u8) !CPU {
        var cpu: CPU = .{
            .boot_rom = boot_rom,
        };

        if (cartridge_rom.len != 32768) {
            return CPUError.InvalidCartridgeSize;
        }

        @memcpy(cpu.memory[0..cartridge_rom.len], cartridge_rom);
        return cpu;
    }

    fn next(self: *CPU) !void {
        // TODO sleep
        self.cycles = 0;

        const opcode = self.popPC(u8);

        std.debug.print("{x:0>2}\n", .{opcode});
        if (self.prefixed) {
            self.printInstruction(sm83.cbprefixed[opcode]);
            self.prefixed = false;
            prefixed_instructions[opcode](self);
        } else {
            self.printInstruction(sm83.unprefixed[opcode]);
            instructions[opcode](self);
        }
    }

    fn printInstruction(self: *CPU, instr: sm83.Instruction) void {
        std.debug.print("{s}", .{
            @tagName(instr.mnemonic),
        });
        for (0..instr.bytes - 1) |i| {
            std.debug.print(" ${x:0>2}", .{self.mem(self.pc).* + i});
        }
        std.debug.print("\n", .{});
    }

    fn popPC(self: *CPU, t: anytype) t {
        switch (t) {
            u8 => {
                const val = self.mem(self.pc);
                self.pc += 1;
                return val.*;
            },
            u16 => {
                const low = @as(u16, self.mem(self.pc).*);
                const high = @as(u16, self.mem(self.pc + 1).*);
                self.pc += 2;
                return (high << 8) | low;
            },
            i8 => {
                const val: i8 = @bitCast(self.mem(self.pc).*);
                self.pc += 1;
                return val;
            },
            else => @compileError("invalid type"),
        }
    }

    fn dump(self: *CPU) void {
        std.debug.print("sp=${x:0>4}; pc=${x:0>4}\n", .{ self.sp, self.pc });
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

    fn mem(self: *CPU, pointer: u16) *u8 {
        if (pointer == 0xFF44) {
            // TODO this is temporary to fake the boot ROM into thinking
            // we're in a vblank period.
            self.dummy = 144;
            return &self.dummy;
        }
        if (self.boot_rom_mapped and pointer <= self.boot_rom.len) {
            return &self.boot_rom[pointer];
        }
        return &self.memory[pointer];
    }
};

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

const CPUError = error{
    UnhandledOpCode,
    UnhandledOperand,
    UnexpectedEnd,
    ProgramCounterOutOfBounds,
    InvalidCartridgeSize,
};

test "execute boot ROM" {
    const fs = @import("std").fs;
    const dir = fs.cwd();

    const boot_rom = try dir.readFileAlloc(std.testing.allocator, "dmg_boot.bin", 512);
    defer std.testing.allocator.free(boot_rom);

    const cartridge_rom = try dir.readFileAlloc(std.testing.allocator, "Tetris (World) (Rev 1).gb", 32768);
    defer std.testing.allocator.free(cartridge_rom);

    var cpu = try CPU.init(boot_rom, cartridge_rom);
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined;
    while (true) {
        if (cpu.pc == 0x00FE) {
            _ = try stdin.readUntilDelimiter(&buf, '\n');
        }
        cpu.dump();
        try cpu.next();
        std.debug.print("\n", .{});
    }
}

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
    cpu.mem(cpu.hl.whole).* = cpu.af.parts.a;
    cpu.hl.whole -%= 1;
}

fn ld_p_a16_a(cpu: *CPU) void {
    cpu.af.parts.a = cpu.mem(cpu.popPC(u16)).*;
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
    cpu.af.parts.a = cpu.mem(cpu.de.whole).*;
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
    cpu.mem(0xFF00 + @as(u16, cpu.bc.parts.lo)).* = cpu.af.parts.a;
}

fn ldh_p_a8_a(cpu: *CPU) void {
    cpu.mem(0xFF00 + @as(u16, cpu.popPC(u8))).* = cpu.af.parts.a;
}

fn ldh_a_p_a8(cpu: *CPU) void {
    cpu.af.parts.a = cpu.mem(0xFF00 + @as(u16, cpu.popPC(u8))).*;
}

fn ld_p_hl_a(cpu: *CPU) void {
    cpu.mem(cpu.hl.whole).* = cpu.af.parts.a;
}

fn ld_p_hli_a(cpu: *CPU) void {
    cpu.mem(cpu.hl.whole).* = cpu.af.parts.a;
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
    const val = cpu.mem(cpu.hl.whole).*;
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
    cpu.af.parts.c = @truncate(cpu.af.parts.a >> 7);
    cpu.af.parts.a <<= 1;
    cpu.af.parts.z = 0;
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn rl_c(cpu: *CPU) void {
    cpu.af.parts.c = @truncate(cpu.bc.parts.lo >> 7);
    cpu.bc.parts.lo <<= 1;
    cpu.af.parts.z = @intFromBool(cpu.bc.parts.lo == 0);
    cpu.af.parts.n = 0;
    cpu.af.parts.h = 0;
}

fn call_a16(cpu: *CPU) void {
    const a16 = cpu.popPC(u16);
    cpu.sp -= 1;
    cpu.mem(cpu.sp).* = @truncate(cpu.pc >> 8);
    cpu.sp -= 1;
    cpu.mem(cpu.sp).* = @truncate(cpu.pc);
    cpu.pc = a16;
}

fn push_bc(cpu: *CPU) void {
    cpu.sp -= 1;
    cpu.mem(cpu.sp).* = cpu.bc.parts.hi;
    cpu.sp -= 1;
    cpu.mem(cpu.sp).* = cpu.bc.parts.lo;
}

fn pop_bc(cpu: *CPU) void {
    cpu.bc.parts.lo = cpu.mem(cpu.sp).*;
    cpu.sp += 1;
    cpu.bc.parts.hi = cpu.mem(cpu.sp).*;
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
    const n8 = cpu.mem(cpu.hl.whole).*;
    const result = cpu.af.parts.a -% n8;
    cpu.af.parts.z = @intFromBool(result == 0);
    cpu.af.parts.n = 1;
    cpu.af.parts.h = @intFromBool((cpu.af.parts.a & 0x0F) < (n8 & 0x0F));
    cpu.af.parts.c = @intFromBool(cpu.af.parts.a < n8);
}

fn ret(cpu: *CPU) void {
    cpu.pc = @as(u16, cpu.mem(cpu.sp).*) | (@as(u16, cpu.mem(cpu.sp + 1).*) << 8);
    cpu.sp += 2;
}

const instructions = initInstructions();
const prefixed_instructions = initPrefixedInstructions();

fn initInstructions() [256]*const fn (cpu: *CPU) void {
    var instrs: [256]*const fn (cpu: *CPU) void = undefined;
    for (0..256) |i| {
        instrs[i] = &unhandled;
    }

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

fn initPrefixedInstructions() [256]*const fn (cpu: *CPU) void {
    var instrs: [256]*const fn (cpu: *CPU) void = undefined;
    for (0..256) |i| {
        instrs[i] = &unhandled;
    }

    instrs[0x7C] = bit_7_h;
    instrs[0x11] = rl_c;

    return instrs;
}

fn unhandled(_: *CPU) void {
    std.debug.panic("unhandled opcode", .{});
}
