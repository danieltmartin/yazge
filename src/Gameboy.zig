const Gameboy = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const CPU = @import("CPU.zig");
const MMU = @import("MMU.zig");
const PPU = @import("PPU.zig");
const Cartridge = @import("Cartridge.zig");
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
cartridge: *Cartridge,
debugger: *Debugger,
mutex: std.Thread.Mutex,

pub fn init(alloc: Allocator, cartridge_rom: []u8, boot_rom: ?[]u8, debug_enabled: bool) !*Gameboy {
    const gameboy = try alloc.create(Gameboy);
    errdefer alloc.destroy(gameboy);

    const ppu = try PPU.init(alloc);
    errdefer ppu.deinit();

    const cartridge = try Cartridge.init(alloc, cartridge_rom);
    errdefer cartridge.deinit();

    const mmu = try MMU.init(alloc, ppu, cartridge, boot_rom);
    errdefer mmu.deinit();

    const cpu = try CPU.init(alloc, mmu);
    errdefer cpu.deinit();

    gameboy.* = .{
        .alloc = alloc,
        .cpu = cpu,
        .mmu = mmu,
        .ppu = ppu,
        .cartridge = cartridge,
        .mutex = std.Thread.Mutex{},
        .debugger = undefined,
    };

    if (boot_rom == null) cpu.pc = 0x100;

    const debugger = try Debugger.init(alloc, gameboy, debug_enabled);
    errdefer debugger.deinit();

    if (boot_rom == null) {
        try debugger.addBreakpoint(0x0100);
    } else {
        try debugger.addBreakpoint(0x0000);
    }
    try debugger.evalBreakpoints();

    gameboy.debugger = debugger;

    return gameboy;
}

pub fn deinit(self: *Gameboy) void {
    self.cartridge.deinit();
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
