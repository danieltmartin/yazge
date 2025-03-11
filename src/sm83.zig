pub const Instruction = struct {
    mnemonic: Mnemonic,
    bytes: u2,
    cycles: u8,
    operands: []const Operand,
    immediate: bool,
};

pub const OperandType = enum { AF, A, BC, B, C, DE, D, E, HL, H, L, SP, PC, A8, A16, N8, N16, E8, U3, VEC, Z, NZ, NC };

pub const Operand = struct {
    type: OperandType,
    bytes: ?u2 = null,
    immediate: bool,
};

pub const Mnemonic = enum {
    NOP,
    ADC,
    RLA,
    HALT,
    STOP,
    RRA,
    DAA,
    AND,
    SCF,
    PREFIX,
    RST,
    RLCA,
    SRL,
    OR,
    RETI,
    SBC,
    EI,
    JR,
    CCF,
    PUSH,
    SLA,
    SRA,
    SET,
    RLC,
    RL,
    JP,
    LD,
    DI,
    BIT,
    SWAP,
    SUB,
    XOR,
    RET,
    ADD,
    ILLEGAL,
    CALL,
    INC,
    RRC,
    RES,
    RRCA,
    CP,
    RR,
    LDH,
    CPL,
    DEC,
    POP,
};

pub const unprefixed = [256]Instruction {
    .{
        .mnemonic = Mnemonic.NOP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 3,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.BC, .bytes = null, .immediate = true },
            .{ .type = OperandType.N16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.BC, .bytes = null, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.BC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLCA,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 3,
        .cycles = 20,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A16, .bytes = 2, .immediate = false },
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
            .{ .type = OperandType.BC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.BC, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.BC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRCA,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.STOP,
        .bytes = 2,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 3,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.DE, .bytes = null, .immediate = true },
            .{ .type = OperandType.N16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.DE, .bytes = null, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.DE, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLA,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.JR,
        .bytes = 2,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
            .{ .type = OperandType.DE, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.DE, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.DE, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRA,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.JR,
        .bytes = 2,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NZ, .bytes = null, .immediate = true },
            .{ .type = OperandType.E8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 3,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
            .{ .type = OperandType.N16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DAA,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.JR,
        .bytes = 2,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.Z, .bytes = null, .immediate = true },
            .{ .type = OperandType.E8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CPL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.JR,
        .bytes = 2,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NC, .bytes = null, .immediate = true },
            .{ .type = OperandType.E8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 3,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
            .{ .type = OperandType.N16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SCF,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.JR,
        .bytes = 2,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.E8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.INC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.DEC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CCF,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.HALT,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RET,
        .bytes = 1,
        .cycles = 20,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NZ, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.POP,
        .bytes = 1,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.BC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.JP,
        .bytes = 3,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NZ, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.JP,
        .bytes = 3,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CALL,
        .bytes = 3,
        .cycles = 24,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NZ, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.PUSH,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.BC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RET,
        .bytes = 1,
        .cycles = 20,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.Z, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RET,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.JP,
        .bytes = 3,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.Z, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.PREFIX,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.CALL,
        .bytes = 3,
        .cycles = 24,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.Z, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.CALL,
        .bytes = 3,
        .cycles = 24,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RET,
        .bytes = 1,
        .cycles = 20,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.POP,
        .bytes = 1,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.DE, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.JP,
        .bytes = 3,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NC, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.CALL,
        .bytes = 3,
        .cycles = 24,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.NC, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.PUSH,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.DE, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SUB,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RET,
        .bytes = 1,
        .cycles = 20,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RETI,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.JP,
        .bytes = 3,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.CALL,
        .bytes = 3,
        .cycles = 24,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.SBC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LDH,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A8, .bytes = 1, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.POP,
        .bytes = 1,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LDH,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.PUSH,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.AND,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ADD,
        .bytes = 2,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
            .{ .type = OperandType.E8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.JP,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 3,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A16, .bytes = 2, .immediate = false },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.XOR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LDH,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A8, .bytes = 1, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.POP,
        .bytes = 1,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.AF, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LDH,
        .bytes = 1,
        .cycles = 8,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.DI,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.PUSH,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.AF, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.OR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 2,
        .cycles = 12,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
            .{ .type = OperandType.E8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 1,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.SP, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.LD,
        .bytes = 3,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.A16, .bytes = 2, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.EI,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.ILLEGAL,
        .bytes = 1,
        .cycles = 4,
        .immediate = true,
        .operands = &[_]Operand {
        },
    },
    .{
        .mnemonic = Mnemonic.CP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
            .{ .type = OperandType.N8, .bytes = 1, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RST,
        .bytes = 1,
        .cycles = 16,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.VEC, .bytes = null, .immediate = true },
        },
    },

};

pub const cbprefixed = [256]Instruction {
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RLC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RRC,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RR,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SLA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SRA,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SWAP,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SRL,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 12,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.BIT,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.RES,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.B, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.C, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.D, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.E, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.H, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.L, .bytes = null, .immediate = true },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 16,
        .immediate = false,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.HL, .bytes = null, .immediate = false },
        },
    },
    .{
        .mnemonic = Mnemonic.SET,
        .bytes = 2,
        .cycles = 8,
        .immediate = true,
        .operands = &[_]Operand {
            .{ .type = OperandType.U3, .bytes = null, .immediate = true },
            .{ .type = OperandType.A, .bytes = null, .immediate = true },
        },
    },

};

