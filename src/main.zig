const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const Gameboy = @import("Gameboy.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("usage: yazge CARTRIDGE_ROM_PATH [BOOT_ROM_PATH]\n", .{});
    }

    const dir = std.fs.cwd();

    var gameboy: *Gameboy = undefined;
    {
        const cartridge_rom = try dir.readFileAlloc(allocator, args[1], 65536);
        defer allocator.free(cartridge_rom);

        var boot_rom: ?[]u8 = null;
        defer if (boot_rom) |rom| allocator.free(rom);
        if (args.len > 2) {
            boot_rom = try dir.readFileAlloc(allocator, args[2], 512);
        }

        gameboy = try Gameboy.init(allocator, cartridge_rom, boot_rom);
    }
    defer gameboy.deinit();

    try mainLoop(gameboy);
}

fn mainLoop(gameboy: *Gameboy) !void {
    rl.setTraceLogLevel(.err);
    rl.initWindow(Gameboy.screen_width * 4, Gameboy.screen_height * 4, "yazge");
    defer rl.closeWindow();

    rl.setTargetFPS(Gameboy.fps);

    const texture = try rl.loadRenderTexture(Gameboy.screen_width, Gameboy.screen_height);

    while (!rl.windowShouldClose()) {
        try gameboy.stepFrame();

        rl.beginTextureMode(texture);
        {
            for (0..Gameboy.screen_width) |x| {
                for (0..Gameboy.screen_height) |y| {
                    const color = switch (gameboy.ppu.framebuffer[x][y]) {
                        0 => rl.Color.white,
                        1 => rl.Color.light_gray,
                        2 => rl.Color.dark_gray,
                        3 => rl.Color.black,
                    };
                    rl.drawPixel(@intCast(x), @intCast(Gameboy.screen_height - y), color);
                }
            }
        }
        rl.endTextureMode();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.drawTextureEx(texture.texture, rl.Vector2.init(0, 0), 0, 4, rl.Color.white);
    }
}
