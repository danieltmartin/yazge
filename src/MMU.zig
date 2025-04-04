const MMU = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const PPU = @import("PPU.zig");
const Cartridge = @import("Cartridge.zig");
const Input = @import("common.zig").Input;

pub const MMUError = error{
    InvalidBootROMSize,
    InvalidCartridgeSize,
};

const disable_boot_rom = 0xFF50;
const lcd_control = 0xFF40;
const lcd_y_coordinate = 0xFF44;
const lcd_y_compare = 0xFF45;
const lcd_status = 0xFF41;
const scroll_y = 0xFF42;
const scroll_x = 0xFF43;
const external_ram_enable_end = 0x1FFF;
const dma_oam_transfer = 0xFF46;
const joypad = 0xFF00;

const cartridge_end = 0x7FFF;
const vram_start = 0x8000;
const vram_end = 0x9FFF;
const external_ram_start = 0xA000;
const external_ram_end = 0xBFFF;
const wram_start = 0xC000;
const echo_ram_start = 0xE000;
const echo_ram_end = 0xFDFF;
const io_registers_start = 0xFF00;
const io_registers_end = 0xFF7F;
const hram_start = 0xFF80;
const hram_end = 0xFFFE;

const interrupt_enable = 0xFFFF;
const interrupt_flag = 0xFF0F;

const timer_counter = 0xFF05;
const timer_control = 0xFF07;
const timer_modulo = 0xFF06;
const divider = 0xFF04;

alloc: Allocator,
ppu: *PPU,
boot_rom: ?[]u8 = null,
boot_rom_mapped: bool = false,
memory: *[64 * 1024]u8,
cartridge: *Cartridge,
fix_y_coordinate: bool = false,
input: Input = .{},
dma_cycles_left: u16 = 0,
dma_start: u16 = 0,

const Config = struct {
    memory: *[64 * 1024]u8,
    ppu: *PPU,
    cartridge: *Cartridge,
    boot_rom: ?[]u8,
};

pub fn init(alloc: Allocator, config: Config) !*MMU {
    const mmu = try alloc.create(MMU);
    errdefer alloc.destroy(mmu);

    mmu.* = .{
        .alloc = alloc,
        .memory = config.memory,
        .ppu = config.ppu,
        .cartridge = config.cartridge,
    };

    if (mmu.boot_rom) |rom| {
        if (rom.len != 256) {
            return MMUError.InvalidBootROMSize;
        }
        mmu.boot_rom = try alloc.dupe(u8, rom);
        mmu.boot_rom_mapped = true;
    }
    errdefer if (mmu.boot_rom) |rom| mmu.alloc.free(rom);

    return mmu;
}

pub fn deinit(self: *MMU) void {
    if (self.boot_rom) |rom| self.alloc.free(rom);
    self.alloc.destroy(self);
}

pub fn write(self: *MMU, address: u16, val: u8) void {
    // Only HRAM is accessible during a DMA transfer.
    if (self.dmaInProgress()) {
        if (address >= hram_start and address <= hram_end) {
            self.memory[address] = val;
        } else {
            return;
        }
    }

    switch (address) {
        disable_boot_rom => {
            if (val != 0) {
                self.boot_rom_mapped = false;
            }
        },
        lcd_control => {
            const control: PPU.LCDControl = @bitCast(val);
            self.ppu.setControl(control);
            self.memory[lcd_control] = val;
        },
        lcd_status => {
            self.memory[lcd_status] = val & 0b01111000;
        },
        scroll_x => {
            self.ppu.scroll_x = val;
        },
        scroll_y => {
            self.ppu.scroll_y = val;
        },
        dma_oam_transfer => {
            // Start DMA transfer. The transfer takes 160 M-cycles.
            // Multiply by 4 since we are using T-cycles. Add an additional
            // 4 T-cycles to account for the delay until the DMA transfer
            // actually starts.
            self.dma_cycles_left = 160 * 4 + 4;
            self.dma_start = @as(u16, val) << 8;
        },
        joypad => {
            // Mask out lower nibble; it's read-only.
            self.memory[joypad] = val & 0xF0;
        },
        divider => {
            self.memory[divider] = 0;
        },
        else => {
            if (address >= vram_start and address <= vram_end) {
                self.ppu.vram[address - vram_start] = val;
            } else if (address >= echo_ram_start and address <= echo_ram_end) {
                return;
            } else if (address <= cartridge_end or
                (address >= external_ram_start and address <= external_ram_end))
            {
                self.cartridge.write(address, val);
            } else {
                self.memory[address] = val;
            }
        },
    }
}

pub fn read(self: *MMU, address: u16) u8 {
    // Only HRAM is accessible during a DMA transfer.
    if (self.dmaInProgress()) {
        if (address >= hram_start and address <= hram_end) {
            return self.memory[address];
        } else {
            return 0xFF;
        }
    }

    if (address == lcd_y_coordinate) {
        if (self.fix_y_coordinate) {
            return 0x90;
        }
        return self.ppu.current_scanline;
    }
    if (address == scroll_x) {
        return self.ppu.scroll_x;
    }
    if (address == scroll_y) {
        return self.ppu.scroll_y;
    }
    if (address == joypad) {
        return self.readInput();
    }
    if (self.boot_rom_mapped and address <= self.boot_rom.?.len) {
        return self.boot_rom.?[address];
    }
    if (address <= cartridge_end) {
        return self.cartridge.read(address);
    }
    if (address >= external_ram_start and address <= external_ram_end) {
        return self.cartridge.read(address);
    }
    if (address >= vram_start and address <= vram_end) {
        return self.ppu.vram[address - vram_start];
    }
    if (address >= echo_ram_start and address <= echo_ram_end) {
        return self.memory[wram_start + (address - echo_ram_start)];
    }
    return self.memory[address];
}

pub fn step(self: *MMU) void {
    if (self.dma_cycles_left > 0) {
        if (self.dma_cycles_left <= 160 * 4 and self.dma_cycles_left % 4 == 0) {
            const from = self.dma_start + 160 - (self.dma_cycles_left / 4);
            const to = 0xFE9F - (self.dma_cycles_left / 4) + 1;
            self.memory[to] = self.memory[from];
        }
        self.dma_cycles_left -= 1;
    }
}

fn dmaInProgress(self: *MMU) bool {
    return self.dma_cycles_left > 0 and self.dma_cycles_left <= 140 * 4;
}

pub const InterruptType = enum(u8) {
    v_blank = 1 << 0,
    lcd = 1 << 1,
    timer = 1 << 2,
    serial = 1 << 3,
    joypad = 1 << 4,
};

pub fn requestInterrupt(self: *MMU, inter_type: InterruptType) void {
    self.memory[interrupt_flag] |= @intFromEnum(inter_type);
}

/// Determines whether any interrupts need to be handled, or returns null otherwise.
/// If there is an interrupt to to be handled and clear_interrupt is true, then
/// the interrupt is cleared in the IF register.
pub fn nextInterrupt(self: *MMU, clear_interrupt: bool) ?InterruptType {
    const enable = self.memory[interrupt_enable];
    const flag = self.memory[interrupt_flag];
    for (0..5) |i| {
        const bit = @as(u8, 1) << @truncate(i);
        if ((enable & bit) > 0 and (flag & bit) > 0) {
            const interrupt_type: InterruptType = @enumFromInt(bit);
            if (clear_interrupt) self.clearInterrupt(interrupt_type);
            return interrupt_type;
        }
    }
    return null;
}

pub const InterruptFlag = packed struct {
    v_blank: bool,
    lcd: bool,
    timer: bool,
    serial: bool,
    joypad: bool,
    _: u3,
};

pub fn readInterruptFlag(self: *MMU) InterruptFlag {
    return @bitCast(self.memory[interrupt_flag]);
}

pub fn readInterruptEnable(self: *MMU) InterruptFlag {
    return @bitCast(self.memory[interrupt_enable]);
}

pub fn readTimerCounter(self: *MMU) u8 {
    return self.memory[timer_counter];
}

pub fn writeTimerCounter(self: *MMU, counter: u8) void {
    self.memory[timer_counter] = counter;
}

pub const TimerControl = packed struct {
    clock_select: u2,
    enable: bool,
    _: u5,

    /// Number of T cycles between clock increments.
    pub fn tCycles(self: TimerControl) u64 {
        return switch (self.clock_select) {
            0b00 => 256 * 4,
            0b01 => 4 * 4,
            0b10 => 16 * 4,
            0b11 => 64 * 4,
        };
    }
};

pub fn readTimerControl(self: *MMU) TimerControl {
    return @bitCast(self.memory[timer_control]);
}

pub fn readTimerModulo(self: *MMU) u8 {
    return self.memory[timer_modulo];
}

pub fn readDivider(self: *MMU) u8 {
    return self.memory[divider];
}

pub fn writeDivider(self: *MMU, val: u8) void {
    self.memory[divider] = val;
}

pub const LCDStatus = packed struct {
    ppu_mode: u2,
    lcd_eq_ly: bool,
    mode_0_int_select: bool,
    mode_1_int_select: bool,
    mode_2_int_select: bool,
    lyc_int_select: bool,
    _: u1 = 1,
};

pub fn readLYC(self: *MMU) u8 {
    return self.memory[lcd_y_compare];
}

pub fn readLCDStatus(self: *MMU) LCDStatus {
    return @bitCast(self.memory[lcd_y_compare]);
}

pub fn writeLCDStatus(self: *MMU, status: LCDStatus) void {
    self.memory[lcd_status] = @bitCast(status);
}

pub fn readInput(self: *MMU) u8 {
    const current = self.memory[joypad];
    if (current & 0b00100000 == 0) {
        return (current & 0xF0) | self.input.toButtons();
    } else if (current & 0b00010000 == 0) {
        return (current & 0xF0) | self.input.toDPad();
    } else {
        return current | 0x0F;
    }
}

fn clearInterrupt(self: *MMU, interrupt_type: InterruptType) void {
    self.memory[interrupt_flag] &= ~@intFromEnum(interrupt_type);
}
