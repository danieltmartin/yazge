const Cartridge = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const bank_0_end = 0x3FFF;
const bank_n_start = 0x4000;
const bank_n_end = 0x7FFF;
const external_ram_start = 0xA000;
const external_ram_end = 0xBFFF;
const rom_bank_number_start = 0x2000;
const rom_bank_number_end = 0x3FFF;
const ram_bank_number_start = 0x4000;
const ram_bank_number_end = 0x5FFF;

alloc: Allocator,
rom: []u8,
bank_n: []u8,
ram_bank: []u8,
external_ram: []u8,
ram_bank_number: u8 = 0,
cart_type: CartridgeType,
external_ram_enabled: bool = false,

pub fn init(alloc: Allocator, rom: []u8) !*Cartridge {
    const cart = try alloc.create(Cartridge);
    errdefer alloc.destroy(cart);

    if (rom.len < 32768) {
        return error.InvalidCartridgeSize;
    }

    const rom_copy = try alloc.dupe(u8, rom);
    errdefer alloc.free(rom_copy);

    const external_ram = try alloc.alloc(u8, 32 * 1024);
    errdefer alloc.free(external_ram);

    cart.* = .{
        .alloc = alloc,
        .rom = rom_copy,
        .bank_n = undefined,
        .external_ram = external_ram,
        .ram_bank = external_ram[0 .. 8 * 1024],
        .cart_type = try cartridgeType(rom),
    };
    errdefer alloc.free(cart.rom);

    cart.bank_n = cart.rom[bank_n_start .. bank_n_end + 1];

    return cart;
}

pub fn deinit(self: *Cartridge) void {
    self.alloc.free(self.rom);
    self.alloc.destroy(self);
    self.alloc.free(self.external_ram);
}

pub fn read(self: *Cartridge, address: u16) u8 {
    if (address <= bank_0_end) {
        return self.rom[address];
    }
    if (address <= bank_n_end) {
        return self.bank_n[address - bank_n_start];
    }
    if (self.external_ram_enabled and
        address >= external_ram_start and
        address <= external_ram_end)
    {
        return self.ram_bank[address - external_ram_start];
    }
    return 0xFF;
}

pub fn write(self: *Cartridge, address: u16, val: u8) void {
    if (address <= 0x1FFF) {
        self.external_ram_enabled = val & 0x0F == 0x0A;
    } else if (address >= rom_bank_number_start and address <= rom_bank_number_end) {
        self.setROMBankNumber(val);
    } else if (address >= ram_bank_number_start and address <= ram_bank_number_end) {
        self.setRAMBankNumber(@truncate(val));
    } else if (self.external_ram_enabled and
        address >= external_ram_start and
        address <= external_ram_end)
    {
        self.external_ram[address - external_ram_start] = val;
    }
}

fn setROMBankNumber(self: *Cartridge, n: u8) void {
    var bank_number = n & 0b00011111;
    if (bank_number == 0) bank_number = 1;
    const start = @as(usize, bank_number) * 16384;
    const end = start + 16384;
    if (start < 0 or end >= self.rom.len + 1) {
        return;
    }
    self.bank_n = self.rom[start..end];
}

fn setRAMBankNumber(self: *Cartridge, n: u2) void {
    const start: usize = @as(usize, n) * 8 * 1024;
    const end: usize = @as(usize, start) + 8 * 1024;
    self.ram_bank = self.external_ram[start..end];
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
