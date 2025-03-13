const Gameboy = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const CPU = @import("CPU.zig");
const MMU = @import("MMU.zig");
const PPU = @import("PPU.zig");
const Debugger = @import("Debugger.zig");

pub const screen_width = 160;
pub const screen_height = 144;
pub const fps = 60;
const gameboy_cpu_freq = 4194304;
const cycles_per_frame = gameboy_cpu_freq / fps;

alloc: Allocator,
cpu: *CPU,
mmu: *MMU,
ppu: *PPU,
debugger: *Debugger,
mutex: std.Thread.Mutex,

pub fn init(alloc: Allocator, boot_rom: []u8, cartridge_rom: []u8) !*Gameboy {
    const gameboy = try alloc.create(Gameboy);
    errdefer alloc.destroy(gameboy);

    const ppu = try PPU.init(alloc);
    errdefer ppu.deinit();

    const mmu = try MMU.init(alloc, ppu, boot_rom, cartridge_rom);
    errdefer mmu.deinit();

    const cpu = try CPU.init(alloc, mmu);
    errdefer cpu.deinit();

    gameboy.* = .{
        .alloc = alloc,
        .cpu = cpu,
        .mmu = mmu,
        .ppu = ppu,
        .mutex = std.Thread.Mutex{},
        .debugger = undefined,
    };

    const debugger = try Debugger.init(alloc, gameboy);
    errdefer debugger.deinit();

    debugger.enabled = true;
    try debugger.addBreakpoint(0x0000);
    try debugger.evalBreakpoints();

    gameboy.debugger = debugger;

    return gameboy;
}

pub fn deinit(self: *Gameboy) void {
    self.cpu.deinit();
    self.mmu.deinit();
    self.ppu.deinit();
    self.debugger.deinit();
    self.alloc.destroy(self);
}

pub fn stepFrame(self: *Gameboy) !void {
    var cycles: u32 = 0;
    while (cycles < cycles_per_frame) {
        if (!self.debugger.shouldStep()) return;
        const cyclesThisStep = self.cpu.step();
        self.ppu.step(cyclesThisStep);
        cycles += cyclesThisStep;
        try self.debugger.evalBreakpoints();
    }
}
