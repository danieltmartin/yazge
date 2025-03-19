const Gameboy = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const CPU = @import("CPU.zig");
const MMU = @import("MMU.zig");
const PPU = @import("PPU.zig");
const Cartridge = @import("Cartridge.zig");
const Debugger = @import("Debugger.zig");
const Input = @import("common.zig").Input;

pub const screen_width = 160;
pub const screen_height = 144;
pub const fps = 60;
const gameboy_cpu_freq = 4194304;
const cycles_per_frame = gameboy_cpu_freq / fps;
const memory_map_size = 64 * 1024;

alloc: Allocator,
memory: *[memory_map_size]u8,
cpu: *CPU,
mmu: *MMU,
ppu: *PPU,
cartridge: *Cartridge,
debugger: *Debugger,
mutex: std.Thread.Mutex,
clock: u16 = 0,
cycles_since_last_frame: u64 = 0,
cycles_since_clock_incr: u64 = 0,

pub fn init(alloc: Allocator, cartridge_rom: []u8, boot_rom: ?[]u8, debug_enabled: bool) !*Gameboy {
    const gameboy = try alloc.create(Gameboy);
    errdefer alloc.destroy(gameboy);

    const memory = try alloc.create([memory_map_size]u8);
    errdefer alloc.free(memory);

    const ppu = try PPU.init(alloc, .{
        .vram = memory[0x8000..0xA000],
        .oam = memory[0xFE00..0xFEA0],
    });
    errdefer ppu.deinit();

    const cartridge = try Cartridge.init(alloc, cartridge_rom);
    errdefer cartridge.deinit();

    const mmu = try MMU.init(alloc, .{
        .memory = memory,
        .ppu = ppu,
        .cartridge = cartridge,
        .boot_rom = boot_rom,
    });
    errdefer mmu.deinit();

    const cpu = try CPU.init(alloc, mmu, gameboy.tickCallback());
    errdefer cpu.deinit();

    gameboy.* = .{
        .alloc = alloc,
        .memory = memory,
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

    gameboy.debugger = debugger;

    return gameboy;
}

pub fn deinit(self: *Gameboy) void {
    self.alloc.free(self.memory);
    self.cartridge.deinit();
    self.cpu.deinit();
    self.mmu.deinit();
    self.ppu.deinit();
    self.debugger.deinit();
    self.alloc.destroy(self);
}

pub fn stepFrame(self: *Gameboy, input: Input) !void {
    self.cycles_since_last_frame = 0;
    while (self.cycles_since_last_frame < cycles_per_frame) {
        try self.step(input);
    }
}

pub fn step(self: *Gameboy, input: Input) !void {
    if (!try self.debugger.shouldStep()) return;

    self.mmu.input = input;
    self.cpu.step();
}

/// Called whenever the CPU executes a granular amount of cycles.
fn tick(self: *Gameboy, cycles: u8) void {
    self.cycles_since_last_frame += cycles;

    for (0..cycles) |_| {
        self.clock +%= 1;
        self.mmu.writeDivider(@truncate(self.clock >> 8));

        self.mmu.step();
        self.ppu.step();
        self.triggerInterrupts();
    }
}

fn tickCallback(self: *Gameboy) CPU.TickCallback {
    return CPU.TickCallback{
        .context = self,
        .func = struct {
            fn wrapper(ctx: *anyopaque, cycles: u8) void {
                const gb: *Gameboy = @ptrCast(@alignCast(ctx));
                gb.tick(cycles);
            }
        }.wrapper,
    };
}

fn triggerInterrupts(self: *Gameboy) void {
    if (self.ppu.mode == .v_blank) {
        self.mmu.requestInterrupt(.v_blank);
    }

    const timer_control = self.mmu.readTimerControl();

    if (timer_control.enable) {
        const counter_increment_cycles = timer_control.tCycles();
        self.cycles_since_clock_incr += 1;

        if (self.cycles_since_clock_incr >= counter_increment_cycles) {
            var timer_counter = self.mmu.readTimerCounter();
            self.cycles_since_clock_incr = 0;
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
