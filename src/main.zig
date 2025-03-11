const print = @import("std").debug.print;
const cpu = @import("cpu.zig");

pub fn main() !void {
    const c = cpu.init();
    print("af:{} a:{} z:{}", .{ c.af.whole, c.af.parts.a, c.af.parts.z });
}
