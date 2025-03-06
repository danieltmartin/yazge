pub const CPU = struct {
    af: AFRegister = AFRegister.init(),
    bc: Register = Register.init(),
    de: Register = Register.init(),
    hl: Register = Register.init(),
    sp: u16 = 0,
    pc: u16 = 0,
};

pub fn init() CPU {
    return CPU{};
}

pub const Register = union {
    whole: u16,
    parts: packed struct {
        lo: u8,
        hi: u8,
    },

    fn init() Register {
        return Register{ .whole = 0 };
    }
};

pub const AFRegister = union {
    whole: u16,
    parts: packed struct {
        z: u1,
        n: u1,
        h: u1,
        c: u1,
        _: u4,
        a: u8,
    },
    fn init() AFRegister {
        return AFRegister{ .whole = 0 };
    }
};
