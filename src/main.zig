const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const Gameboy = @import("Gameboy.zig");
const Input = @import("common.zig").Input;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("usage: yazge [--debug] CARTRIDGE_ROM_PATH [BOOT_ROM_PATH]\n", .{});
        return;
    }

    const dir = std.fs.cwd();

    var arg: usize = 1;
    var debug_enabled = false;
    if (std.mem.eql(u8, args[arg], "--debug")) {
        debug_enabled = true;
        arg += 1;
    }

    var gameboy: *Gameboy = undefined;
    {
        const cartridge_rom = try dir.readFileAlloc(allocator, args[arg], 65536);
        defer allocator.free(cartridge_rom);
        arg += 1;

        var boot_rom: ?[]u8 = null;
        defer if (boot_rom) |rom| allocator.free(rom);
        if (arg < args.len) {
            boot_rom = try dir.readFileAlloc(allocator, args[arg], 512);
        }

        gameboy = try Gameboy.init(allocator, cartridge_rom, boot_rom, debug_enabled);
    }
    defer gameboy.deinit();

    if (!debug_enabled) {
        gameboy.mmu.fix_y_coordinate = true;
        try gameboyDoctorMode(gameboy);
    } else {
        try mainLoop(gameboy);
    }
}

fn mainLoop(gameboy: *Gameboy) !void {
    rl.setTraceLogLevel(.err);
    rl.initWindow(Gameboy.screen_width * 4, Gameboy.screen_height * 4, "yazge");
    defer rl.closeWindow();

    rl.setTargetFPS(Gameboy.fps);

    const texture = try rl.loadRenderTexture(Gameboy.screen_width, Gameboy.screen_height);

    while (!rl.windowShouldClose()) {
        const input = Input{
            .right = rl.isKeyDown(rl.KeyboardKey.right),
            .left = rl.isKeyDown(rl.KeyboardKey.left),
            .up = rl.isKeyDown(rl.KeyboardKey.up),
            .down = rl.isKeyDown(rl.KeyboardKey.down),
            .a = rl.isKeyDown(rl.KeyboardKey.x),
            .b = rl.isKeyDown(rl.KeyboardKey.z),
            .start = rl.isKeyDown(rl.KeyboardKey.enter),
            .select = rl.isKeyDown(rl.KeyboardKey.right_shift),
        };
        try gameboy.stepFrame(input);

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

fn gameboyDoctorMode(gameboy: *Gameboy) !void {
    gameboy.cpu.af.whole = 0x01B0;
    gameboy.cpu.bc.whole = 0x0013;
    gameboy.cpu.de.whole = 0x00D8;
    gameboy.cpu.hl.whole = 0x014D;
    gameboy.cpu.sp = 0xFFFE;
    gameboy.cpu.pc = 0x0100;

    const stdout = std.io.getStdOut();
    var buf_out = std.io.bufferedWriter(stdout.writer());
    const writer = buf_out.writer();

    const cpu = gameboy.cpu;

    while (true) {
        const just_interrupted = cpu.pc == 0x40 or cpu.pc == 0x48 or cpu.pc == 0x50 or cpu.pc == 0x58 or cpu.pc == 0x60;
        if (!cpu.prefixed and !just_interrupted) {
            try writer.print("A:{X:0>2} F:{X:0>2} B:{X:0>2} C:{X:0>2} D:{X:0>2} E:{X:0>2} H:{X:0>2} L:{X:0>2} SP:{X:0>4} PC:{X:0>4} PCMEM:{X:0>2},{X:0>2},{X:0>2},{X:0>2}\n", .{
                cpu.af.parts.a,
                (@as(u8, cpu.af.parts.c) << 4) | (@as(u8, cpu.af.parts.h) << 5) | (@as(u8, cpu.af.parts.n) << 6) | (@as(u8, cpu.af.parts.z) << 7),
                cpu.bc.parts.hi,
                cpu.bc.parts.lo,
                cpu.de.parts.hi,
                cpu.de.parts.lo,
                cpu.hl.parts.hi,
                cpu.hl.parts.lo,
                cpu.sp,
                cpu.pc,
                cpu.readMem(cpu.pc),
                cpu.readMem(cpu.pc + 1),
                cpu.readMem(cpu.pc + 2),
                cpu.readMem(cpu.pc + 3),
            });
        }
        _ = try gameboy.step(.{});
    }

    writer.flush();
}
