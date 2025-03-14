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
cycles_since_clock_increment: u64 = 0,

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
    var cycles: u64 = 0;
    while (cycles < cycles_per_frame) {
        cycles += try self.step();
    }
}

pub fn step(self: *Gameboy) !u64 {
    if (!self.debugger.shouldStep()) return 0;

    const cycles_this_step = self.cpu.step();
    self.ppu.step(cycles_this_step);

    self.triggerInterrupts(cycles_this_step);

    try self.debugger.evalBreakpoints();

    return cycles_this_step;
}

fn triggerInterrupts(self: *Gameboy, cycles_this_step: u64) void {
    if (self.ppu.mode == .v_blank) {
        self.mmu.requestInterrupt(.v_blank);
    }

    const timer_control = self.mmu.readTimerControl();

    if (timer_control.enable) {
        self.cycles_since_clock_increment += cycles_this_step;

        const counter_increment_cycles = timer_control.tCycles();

        if (self.cycles_since_clock_increment >= counter_increment_cycles) {
            var timer_counter = self.mmu.readTimerCounter();
            self.cycles_since_clock_increment = 0;
            timer_counter, const overflowed = @addWithOverflow(timer_counter, 1);
            if (overflowed == 1) {
                self.mmu.writeTimerCounter(self.mmu.readTimerModulo());
                self.mmu.requestInterrupt(.timer);
            } else {
                self.mmu.writeTimerCounter(timer_counter);
            }
        }
    }
}
