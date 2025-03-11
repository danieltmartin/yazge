const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const CPU = @import("CPU.zig");
const PPU = @import("PPU.zig");
const debug = @import("debug.zig");

const screen_width = 160;
const screen_height = 144;
const fps = 60;
const gameboy_cpu_freq = 4194304;
const cycles_per_frame = gameboy_cpu_freq / fps;

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

    const cpu = try CPU.init(allocator, boot_rom, cartridge_rom);
    defer cpu.deinit();

    const ppu = try PPU.init(allocator);
    defer ppu.deinit();

    try mainLoop(allocator, cpu, ppu);
}

fn mainLoop(alloc: Allocator, cpu: *CPU, ppu: *PPU) !void {
    rl.initWindow(screen_width, screen_height, "yazge");
    defer rl.closeWindow();

    rl.setTargetFPS(fps);

    while (!rl.windowShouldClose()) {
        var cycles: u32 = 0;
        while (cycles < cycles_per_frame) {
            const disassembled = try debug.disassembleNext(alloc, cpu);
            defer alloc.free(disassembled);
            std.debug.print("{s}\n", .{disassembled});
            const cyclesThisStep = cpu.step();
            ppu.step(cyclesThisStep);
            cpu.dump();
            cycles += cyclesThisStep;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
    }
}
