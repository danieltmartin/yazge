const PPU = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const Mode = enum(u2) {
    h_blank = 0,
    v_blank,
    oam_scan,
    drawing,
};

pub const LCDControl = packed struct {
    bg_window_enable: bool,
    obj_enable: bool,
    obj_size: bool,
    bg_tile_map: bool,
    bg_window_addressing_mode: bool,
    window_enable: bool,
    window_tile_map: bool,
    enable: bool,
};

const max_h_blank_duration = 376;
const oam_scan_duration = 80;
const min_drawing_duration = 172;
const v_blank_line_duration = 456;
const max_horizontal_line = 143;
const num_v_blank_scanlines = 10;

alloc: Allocator,
mode: Mode = .h_blank,
dots: i32 = 0,
last_draw_duration: i32 = 0,
current_scanline: u8 = 0,
x: u8 = 0,
control: LCDControl = @bitCast(@as(u8, 0)),
vram: [8192]u8 = undefined,
framebuffer: [160][144]u2 = undefined,
scroll_x: u8 = 0,
scroll_y: u8 = 0,

pub fn init(alloc: Allocator) !*PPU {
    const ppu = try alloc.create(PPU);
    errdefer alloc.destroy(ppu);

    ppu.* = .{
        .alloc = alloc,
    };

    return ppu;
}

pub fn deinit(self: *PPU) void {
    self.alloc.destroy(self);
}

pub fn step(self: *PPU, cyclesSinceLastStep: u16) void {
    if (!self.control.enable) {
        return;
    }
    self.dots += cyclesSinceLastStep;

    switch (self.mode) {
        .h_blank => {
            if (self.dots >= max_h_blank_duration - self.last_draw_duration) {
                self.dots -= max_h_blank_duration - self.last_draw_duration;
                self.current_scanline += 1;
                self.mode = if (self.current_scanline > max_horizontal_line) .v_blank else .oam_scan;
            }
        },
        .v_blank => {
            if (self.dots >= v_blank_line_duration) {
                self.dots -= v_blank_line_duration;
                self.current_scanline += 1;
                if (self.current_scanline > max_horizontal_line + num_v_blank_scanlines) {
                    self.current_scanline = 0;
                    self.mode = .oam_scan;
                }
            }
        },
        .oam_scan => {
            if (self.dots >= oam_scan_duration) {
                self.dots -= oam_scan_duration;
                self.mode = .drawing;
                self.x = 0;
            }
        },
        .drawing => {
            for (0..cyclesSinceLastStep) |_| {
                if (self.x >= 160) break;
                self.draw(self.x);
                self.x += 1;
            }
            if (self.dots >= min_drawing_duration) {
                // TODO these should vary based on various factors that can stall the draw.
                self.dots -= min_drawing_duration;
                self.last_draw_duration = min_drawing_duration;
                self.mode = .h_blank;
            }
        },
    }
}

pub fn setControl(self: *PPU, control: LCDControl) void {
    if (self.control.enable != control.enable) {
        self.dots = 0;
        self.last_draw_duration = 0;
        self.current_scanline = 0;
        self.mode = if (control.enable) .oam_scan else .h_blank;
    }
    self.control = control;
}

fn draw(self: *PPU, x: u8) void {
    if (!self.control.bg_window_enable) {
        return;
    }
    const y = self.current_scanline;
    const scroll_x = x +% self.scroll_x;
    const scroll_y = y +% self.scroll_y;
    const tilemap_addr = self.get_tilemap_addr(scroll_x, scroll_y);
    const tile_number = self.vram_read(tilemap_addr);
    const tile_addr = self.get_tile_addr(tile_number);
    const tile_x = scroll_x % 8;
    const tile_y = scroll_y % 8;
    const tile_pixel = self.get_tile_pixel(tile_addr, tile_x, tile_y);
    self.framebuffer[x][y] = tile_pixel;
}

fn get_tilemap_addr(self: *PPU, x: u8, y: u8) u16 {
    const tilemap: u16 = if (self.control.bg_tile_map) 0x9C00 else 0x9800;
    const tilemap_x: u16 = x / 8;
    const tilemap_y: u16 = y / 8;
    return tilemap + tilemap_x + 32 * tilemap_y;
}

fn get_tile_addr(self: *PPU, tile_number: u8) u16 {
    return if (self.control.bg_window_addressing_mode)
        @as(u16, 0x8000) + 16 * @as(u16, tile_number)
    else
        @intCast(@as(i32, 0x9000) + 16 * @as(i16, @as(i8, @bitCast(tile_number))));
}

fn get_tile_pixel(self: *PPU, tile_addr: u16, x: u8, y: u8) u2 {
    const row_offset = @as(u16, y) * 2;
    const lsb = self.vram_read(tile_addr + row_offset);
    const msb = self.vram_read(tile_addr + row_offset + 1);
    const bit_position: u3 = @intCast(7 - x);
    const lsb_bit = (lsb >> bit_position) & 1;
    const msb_bit = (msb >> bit_position) & 1;
    return @truncate((msb_bit << 1) | lsb_bit);
}

fn vram_read(self: *PPU, addr: u16) u8 {
    return self.vram[addr - 0x8000];
}

const expectEqual = std.testing.expectEqual;

test "cycle through modes" {
    const alloc = std.testing.allocator;
    const ppu = try PPU.init(alloc);
    defer ppu.deinit();

    try expectEqual(.h_blank, ppu.mode);
    ppu.control.enable = true;

    for (0..100) |_| {
        for (0..144) |scanline| {
            try expectEqual(scanline, ppu.current_scanline);
            try expectEqual(.oam_scan, ppu.mode);
            ppu.step(80);
            try expectEqual(.drawing, ppu.mode);
            ppu.step(172);
            try expectEqual(.h_blank, ppu.mode);
            ppu.step(204);
        }

        try expectEqual(0, ppu.dots);

        for (144..154) |scanline| {
            try expectEqual(scanline, ppu.current_scanline);
            try expectEqual(.v_blank, ppu.mode);
            ppu.step(456);
        }
    }
}
