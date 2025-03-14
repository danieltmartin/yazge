const Cartridge = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const bank_0_end = 0x3FFF;
const bank_n_start = 0x4000;
const bank_n_end = 0x7FFF;

alloc: Allocator,
rom: []u8,
bank_n: []u8,
cart_type: CartridgeType,

pub fn init(alloc: Allocator, rom: []u8) !*Cartridge {
    const cart = try alloc.create(Cartridge);
    errdefer alloc.destroy(cart);

    if (rom.len < 32768) {
        return error.InvalidCartridgeSize;
    }

    cart.* = .{
        .alloc = alloc,
        .rom = try alloc.dupe(u8, rom),
        .bank_n = undefined,
        .cart_type = try cartridgeType(rom),
    };
    errdefer alloc.free(cart.rom);

    cart.bank_n = cart.rom[bank_n_start .. bank_n_end + 1];

    return cart;
}

pub fn deinit(self: *Cartridge) void {
    self.alloc.free(self.rom);
    self.alloc.destroy(self);
}

pub fn read(self: *Cartridge, address: u16) u8 {
    if (address <= bank_0_end) {
        return self.rom[address];
    }
    return self.bank_n[address - bank_n_start];
}

pub fn setBankNumber(self: *Cartridge, n: u8) void {
    var bank_number = n & 0b00011111;
    if (bank_number == 0) bank_number = 1;
    const start = @as(u16, bank_number) * 16384;
    const end = start + 16384;
    if (start < 0 or end >= self.rom.len) {
        return;
    }
    self.bank_n = self.rom[start..end];
}

const CartridgeType = enum(u8) {
    rom_only = 0x00,
    mbc1 = 0x01,

    fn max() comptime_int {
        var v: comptime_int = 0;
        for (@typeInfo(CartridgeType).@"enum".fields) |field| {
            if (field.value > v) {
                v = field.value;
            }
        }
        return v;
    }
};

const header_type = 0x147;

fn cartridgeType(rom: []u8) !CartridgeType {
    if (rom.len < header_type + 1) {
        return error.InvalidCartridgeSize;
    }
    const cartridge_type = rom[header_type];
    if (cartridge_type > CartridgeType.max()) {
        return error.UnknownCartridgeType;
    }
    return @enumFromInt(cartridge_type);
}
