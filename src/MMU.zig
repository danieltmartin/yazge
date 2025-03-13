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
const scroll_y = 0xFF42;
const scroll_x = 0xFF43;

const vram_start = 0x8000;
const vram_end = 0x9FFF;

alloc: Allocator,
ppu: *PPU,
boot_rom: ?[]u8 = null,
boot_rom_mapped: bool = false,
memory: [65536]u8 = undefined,

pub fn init(alloc: Allocator, ppu: *PPU, cartridge_rom: []u8, boot_rom: ?[]u8) !*MMU {
    const mmu = try alloc.create(MMU);
    errdefer alloc.destroy(mmu);

    if (cartridge_rom.len != 32768) {
        return MMUError.InvalidCartridgeSize;
    }

    mmu.* = .{
        .alloc = alloc,
        .ppu = ppu,
    };

    if (boot_rom) |rom| {
        if (rom.len != 256) {
            return MMUError.InvalidBootROMSize;
        }
        mmu.boot_rom = try alloc.dupe(u8, rom);
        mmu.boot_rom_mapped = true;
    }

    @memcpy(mmu.memory[0..cartridge_rom.len], cartridge_rom);
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
        else => {
            if (pointer >= vram_start and pointer <= vram_end) {
                self.ppu.vram[pointer - vram_start] = val;
            } else {
                self.memory[pointer] = val;
            }
        },
    }
}

pub fn readMem(self: *MMU, pointer: u16) u8 {
    if (pointer == lcd_y_coordinate) {
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
    if (pointer >= vram_start and pointer <= vram_end) {
        return self.ppu.vram[pointer - vram_start];
    }
    return self.memory[pointer];
}
