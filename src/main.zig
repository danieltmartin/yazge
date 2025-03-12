const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const Gameboy = @import("Gameboy.zig");
const debug = @import("debug.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 3) {
        std.debug.print("usage: yazge BOOT_ROM_PATH CARTRIDGE_ROM_PATH\n", .{});
    }

    const dir = std.fs.cwd();

    const boot_rom = try dir.readFileAlloc(allocator, args[1], 512);
    defer allocator.free(boot_rom);

    const cartridge_rom = try dir.readFileAlloc(allocator, args[2], 32768);
    defer allocator.free(cartridge_rom);

    const gameboy = try Gameboy.init(allocator, boot_rom, cartridge_rom);
    defer gameboy.deinit();

    try mainLoop(gameboy);
}

fn mainLoop(gameboy: *Gameboy) !void {
    rl.initWindow(Gameboy.screen_width, Gameboy.screen_height, "yazge");
    defer rl.closeWindow();

    rl.setTargetFPS(Gameboy.fps);

    while (!rl.windowShouldClose()) {
        try gameboy.stepFrame();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
    }
}
