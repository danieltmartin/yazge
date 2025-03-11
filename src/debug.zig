const Debugger = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const CPU = @import("CPU.zig");

breakpoints: [256]u16,

pub fn shouldPause(self: *Debugger, cpu: *CPU) bool {
    for (self.breakpoints) |bp| {
        if (cpu.pc == bp) {
            return true;
        }
    }
    return false;
}

pub fn disassembleNext(alloc: Allocator, cpu: *CPU) ![]u8 {
    var buf: [3]u8 = undefined;
    const instr, const bytes = cpu.peekNext(&buf);
    var list = std.ArrayList(u8).init(alloc);
    defer list.deinit();
    const writer = list.writer();

    try writer.print("{x:0>4}: {s}", .{ cpu.pc, @tagName(instr.mnemonic) });

    var byteIndex: usize = 1;

    for (instr.operands) |oper| {
        const numBytes = oper.bytes orelse 0;
        switch (numBytes) {
            0 => {
                try writer.print(" {s}", .{@tagName(oper.type)});
            },
            1 => {
                try writer.print(" ${x:0>2}", .{bytes[byteIndex]});
                byteIndex += 1;
            },
            2 => {
                const val = (@as(u16, bytes[byteIndex + 1]) << 8) | bytes[byteIndex];
                try writer.print(" ${x:0>4}", .{val});
                byteIndex += 2;
            },
            else => unreachable,
        }
    }

    return alloc.dupe(u8, list.items);
}
