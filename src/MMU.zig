const MMU = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const PPU = @import("PPU.zig");
const Cartridge = @import("Cartridge.zig");

pub const MMUError = error{
    InvalidBootROMSize,
    InvalidCartridgeSize,
};

const disable_boot_rom = 0xFF50;
const lcd_control = 0xFF40;
const lcd_y_coordinate = 0xFF44;
const scroll_y = 0xFF42;
const scroll_x = 0xFF43;
const rom_bank_number = 0x2000;

const cartridge_end = 0x7FFF;
const vram_start = 0x8000;
const vram_end = 0x9FFF;
const wram_start = 0xC000;
const echo_ram_start = 0xE000;
const echo_ram_end = 0xFDFF;
const io_registers_start = 0xFF00;
const io_registers_end = 0xFF7F;

alloc: Allocator,
ppu: *PPU,
boot_rom: ?[]u8 = null,
boot_rom_mapped: bool = false,
memory: [65536]u8 = [_]u8{0} ** 65536,
cartridge: *Cartridge,
fix_y_coordinate: bool = false,

pub fn init(alloc: Allocator, ppu: *PPU, cartridge: *Cartridge, boot_rom: ?[]u8) !*MMU {
    const mmu = try alloc.create(MMU);
    errdefer alloc.destroy(mmu);

    mmu.* = .{
        .alloc = alloc,
        .ppu = ppu,
        .cartridge = cartridge,
    };

    if (boot_rom) |rom| {
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

pub fn writeMem(self: *MMU, pointer: u16, val: u8) void {
    switch (pointer) {
        disable_boot_rom => {
            self.boot_rom_mapped = val == 0;
        },
        lcd_control => {
            const control: PPU.LCDControl = @bitCast(val);
            self.ppu.setControl(control);
        },
        scroll_x => {
            self.ppu.scroll_x = val;
        },
        scroll_y => {
            self.ppu.scroll_y = val;
        },
        rom_bank_number => {
            self.cartridge.setBankNumber(val);
        },
        else => {
            if (pointer >= vram_start and pointer <= vram_end) {
                self.ppu.vram[pointer - vram_start] = val;
            } else if (pointer >= echo_ram_start and pointer <= echo_ram_end) {
                return;
            } else {
                self.memory[pointer] = val;
            }
        },
    }
}

pub fn readMem(self: *MMU, pointer: u16) u8 {
    if (pointer == lcd_y_coordinate) {
        if (self.fix_y_coordinate) {
            return 0x90;
        }
        return self.ppu.current_scanline;
    }
    if (pointer == scroll_x) {
        return self.ppu.scroll_x;
    }
    if (pointer == scroll_y) {
        return self.ppu.scroll_y;
    }
    if (self.boot_rom_mapped and pointer <= self.boot_rom.?.len) {
        return self.boot_rom.?[pointer];
    }
    if (pointer <= cartridge_end) {
        return self.cartridge.read(pointer);
    }
    if (pointer >= vram_start and pointer <= vram_end) {
        return self.ppu.vram[pointer - vram_start];
    }
    if (pointer >= io_registers_start and pointer <= io_registers_end) {
        return 0xFF;
    }
    if (pointer >= echo_ram_start and pointer <= echo_ram_end) {
        return self.memory[wram_start + (pointer - echo_ram_start)];
    }
    return self.memory[pointer];
}
