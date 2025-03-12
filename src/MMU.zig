const MMU = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const PPU = @import("PPU.zig");

pub const MMUError = error{
    InvalidBootROMSize,
    InvalidCartridgeSize,
};

const disable_boot_rom = 0xFF50;
const lcd_control = 0xFF40;
const lcd_y_coordinate = 0xFF44;

const LCDControl = packed struct {
    enable: bool,
    window_tile_map: bool,
    window_enable: bool,
    bg_window_addressing_mode: bool,
    bg_tile_map_area: bool,
    obj_size: bool,
    obj_enable: bool,
    bg_window_enable: bool,
};

alloc: Allocator,
ppu: *PPU,
boot_rom: []u8,
boot_rom_mapped: bool = true,
memory: [65536]u8 = std.mem.zeroes([65536]u8),

pub fn init(alloc: Allocator, ppu: *PPU, boot_rom: []u8, cartridge_rom: []u8) !*MMU {
    const mmu = try alloc.create(MMU);
    errdefer alloc.destroy(mmu);

    if (boot_rom.len != 256) {
        return MMUError.InvalidBootROMSize;
    }

    if (cartridge_rom.len != 32768) {
        return MMUError.InvalidCartridgeSize;
    }

    mmu.* = .{
        .alloc = alloc,
        .ppu = ppu,
        .boot_rom = try alloc.dupe(u8, boot_rom),
    };

    @memcpy(mmu.memory[0..cartridge_rom.len], cartridge_rom);
    return mmu;
}

pub fn deinit(self: *MMU) void {
    self.alloc.free(self.boot_rom);
    self.alloc.destroy(self);
}

pub fn writeMem(self: *MMU, pointer: u16, val: u8) void {
    switch (pointer) {
        disable_boot_rom => {
            self.boot_rom_mapped = val == 0;
        },
        lcd_control => {
            const control: LCDControl = @bitCast(val);
            self.ppu.enabled = control.enable;
        },
        else => self.memory[pointer] = val,
    }
}

pub fn readMem(self: *MMU, pointer: u16) u8 {
    if (pointer == lcd_y_coordinate) {
        return self.ppu.current_scanline;
    }
    if (self.boot_rom_mapped and pointer <= self.boot_rom.len) {
        return self.boot_rom[pointer];
    }
    return self.memory[pointer];
}
