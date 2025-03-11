const PPU = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const Mode = enum(u2) {
    h_blank = 0,
    v_blank,
    oam_scan,
    drawing,
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
enabled: bool = false,

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
    if (!self.enabled) {
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
            }
        },
        .drawing => {
            if (self.dots >= min_drawing_duration) {
                // TODO these should vary based on various factors that can stall the draw.
                self.dots -= min_drawing_duration;
                self.last_draw_duration = min_drawing_duration;
                self.mode = .h_blank;
            }
        },
    }
}

pub fn setEnabled(self: *PPU, enabled: bool) void {
    if (self.enabled == enabled) {
        return;
    }
    self.enabled = enabled;
    self.dots = 0;
    self.last_draw_duration = 0;
    self.current_scanline = 0;
    self.mode = if (enabled) .oam_scan else .h_blank;
}

const expectEqual = std.testing.expectEqual;

test "cycle through modes" {
    const alloc = std.testing.allocator;
    const ppu = try PPU.init(alloc);
    defer ppu.deinit();

    try expectEqual(.h_blank, ppu.mode);
    ppu.setEnabled(true);

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
