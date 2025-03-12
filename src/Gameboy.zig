const Gameboy = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const CPU = @import("CPU.zig");
const MMU = @import("MMU.zig");
const PPU = @import("PPU.zig");
const debug = @import("debug.zig");

pub const screen_width = 160;
pub const screen_height = 144;
pub const fps = 60;
const gameboy_cpu_freq = 4194304;
const cycles_per_frame = gameboy_cpu_freq / fps;

alloc: Allocator,
cpu: *CPU,
mmu: *MMU,
ppu: *PPU,

pub fn init(alloc: Allocator, boot_rom: []u8, cartridge_rom: []u8) !*Gameboy {
    const gameboy = try alloc.create(Gameboy);
    errdefer alloc.destroy(gameboy);

    const ppu = try PPU.init(alloc);
    errdefer gameboy.ppu.deinit();
    const mmu = try MMU.init(alloc, ppu, boot_rom, cartridge_rom);
    errdefer gameboy.mmu.deinit();
    const cpu = try CPU.init(alloc, mmu);
    errdefer gameboy.cpu.deinit();

    gameboy.* = .{
        .alloc = alloc,
        .cpu = cpu,
        .mmu = mmu,
        .ppu = ppu,
    };

    return gameboy;
}

pub fn deinit(self: *Gameboy) void {
    self.cpu.deinit();
    self.mmu.deinit();
    self.ppu.deinit();
    self.alloc.destroy(self);
}

pub fn stepFrame(self: *Gameboy) !void {
    var cycles: u32 = 0;
    while (cycles < cycles_per_frame) {
        const disassembled = try debug.disassembleNext(self.alloc, self.cpu);
        defer self.alloc.free(disassembled);
        std.debug.print("{s}\n", .{disassembled});
        const cyclesThisStep = self.cpu.step();
        self.ppu.step(cyclesThisStep);
        self.cpu.dump();
        cycles += cyclesThisStep;
    }
}
