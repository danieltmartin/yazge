const std = @import("std");

const Gameboy = @import("../src/Gameboy.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len > 1) {
        const rom = try std.fs.cwd().readFileAlloc(alloc, args[1], 1024 * 1024);
        defer alloc.free(rom);
        _ = runTest(alloc, rom, args[1]);
        return;
    }

    const dir = try std.fs.cwd().openDir("mooneye/acceptance", .{ .iterate = true });
    var walker = try dir.walk(alloc);
    defer walker.deinit();

    var any_failed = false;

    var count: u32 = 0;
    while (try walker.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.basename, ".gb")) {
            continue;
        }
        count += 1;

        const cartridge_rom = try entry.dir.readFileAlloc(alloc, entry.basename, 65536);
        defer alloc.free(cartridge_rom);

        if (!runTest(alloc, cartridge_rom, entry.basename)) {
            any_failed = true;
        }
    }
}

fn runTest(alloc: std.mem.Allocator, rom: []u8, name: []const u8) bool {
    const gameboy = Gameboy.init(alloc, rom, null, false) catch |err| {
        std.log.info("{s}: {}", .{ name, err });
        return false;
    };
    defer gameboy.deinit();

    const max_iters = 100_000_000;
    for (0..max_iters) |i| {
        if (i == max_iters - 1) {
            std.log.info("{s}: TIMED OUT", .{name});
            return false;
        }
        _ = gameboy.step(.{}) catch |err| {
            std.log.err("{s}: ERROR {}", .{ name, err });
        };

        if (testPassed(gameboy)) {
            std.log.info("{s}: PASSED", .{name});
            return true;
        }
        if (testFailed(gameboy)) {
            std.log.info("{s}: FAILED", .{name});
            return false;
        }
    }

    return false;
}

fn testPassed(gb: *Gameboy) bool {
    return gb.cpu.bc.parts.hi == 3 and
        gb.cpu.bc.parts.lo == 5 and
        gb.cpu.de.parts.hi == 8 and
        gb.cpu.de.parts.lo == 13 and
        gb.cpu.hl.parts.hi == 21 and
        gb.cpu.hl.parts.lo == 34;
}

fn testFailed(gb: *Gameboy) bool {
    const bad = 0x42;
    return gb.cpu.bc.parts.hi == bad and
        gb.cpu.bc.parts.lo == bad and
        gb.cpu.de.parts.hi == bad and
        gb.cpu.de.parts.lo == bad and
        gb.cpu.hl.parts.hi == bad and
        gb.cpu.hl.parts.lo == bad;
}
