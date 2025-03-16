pub const Input = packed struct {
    right: bool = false,
    left: bool = false,
    up: bool = false,
    down: bool = false,
    a: bool = false,
    b: bool = false,
    select: bool = false,
    start: bool = false,

    pub fn toDPad(self: Input) u4 {
        const val: u8 = @bitCast(self);
        return ~@as(u4, @truncate(val));
    }

    pub fn toButtons(self: Input) u4 {
        const val: u8 = @bitCast(self);
        return ~@as(u4, @truncate(val >> 4));
    }
};
