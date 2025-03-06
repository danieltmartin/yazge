const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
const alloc = gpa.allocator();

const Instructions = struct {
    unprefixed: []Instruction,
    cbprefixed: []Instruction,
};

const Instruction = struct {
    mnemonic: []const u8,
    bytes: u2,
    cycles: []u32,
    operands: []Operand,
    immediate: bool,
    flags: Flags,
};

const Operand = struct {
    name: []const u8,
    bytes: ?u2 = null,
    immediate: bool,
};

const Flags = struct {
    Z: []const u8,
    N: []const u8,
    H: []const u8,
    C: []const u8,
};

pub fn main() !void {
    const instructions = try parseInstructionsJSON();
    const output_file = try std.fs.cwd().createFile("sm83.zig", .{ .truncate = true });
    defer output_file.close();
    const writer = output_file.writer();

    try writeCommonTypes(writer);
    try writeMnemonicEnum(writer, instructions);
    try writeInstructions(writer, "unprefixed", instructions.unprefixed);
    try writeInstructions(writer, "cbprefixed", instructions.cbprefixed);
}

fn writeInstructions(writer: anytype, field_name: []const u8, instructions: []Instruction) !void {
    try std.fmt.format(writer,
        \\pub const {s} = [256]Instruction {{
        \\
    , .{field_name});
    for (instructions) |instr| {
        try std.fmt.format(
            writer,
            \\    .{{
            \\        .mnemonic = Mnemonic.{s},
            \\        .bytes = {d},
            \\        .cycles = {d},
            \\        .immediate = {},
            \\        .operands = [_]Operand {{
        ,
            .{
                normalizeMnemonic(instr.mnemonic),
                instr.bytes,
                instr.cycles[0],
                instr.immediate,
            },
        );

        for (instr.operands) |oper| {
            try std.fmt.format(writer,
                \\
                \\            .{{ .type = OperandType.{s}, .bytes = {?d}, .immediate = {} }},
            , .{ normalizeOperandName(oper.name), oper.bytes, oper.immediate });
        }

        try writer.writeAll("\n        },\n    },\n");
    }

    try writer.writeAll(
        \\
        \\};
        \\
        \\
    );
}

fn writeCommonTypes(writer: anytype) !void {
    try writer.writeAll(
        \\const Instruction = struct {
        \\    mnemonic: []u8,
        \\    bytes: u2,
        \\    cycles: u8,
        \\    operands: []Operand,
        \\    immediate: bool,
        \\};
        \\
        \\
    );
    try writer.writeAll(
        \\const OperandType = enum { AF, A, BC, B, C, DE, D, E, HL, H, L, SP, PC, N8, N16, E8, U3, VEC };
        \\
        \\
    );
    try writer.writeAll(
        \\const Operand = struct {
        \\    type: OperandType,
        \\    bytes: ?u2 = null,
        \\    immediate: bool,
        \\};
        \\
        \\
    );
}

fn writeMnemonicEnum(writer: anytype, instructions: Instructions) !void {
    var map = std.StringHashMap([]const u8).init(alloc);
    defer map.deinit();

    for (instructions.unprefixed) |instr| {
        try map.put(normalizeMnemonic(instr.mnemonic), "");
    }
    for (instructions.cbprefixed) |instr| {
        try map.put(normalizeMnemonic(instr.mnemonic), "");
    }

    try writer.writeAll(
        \\const Mnemonic = enum {
        \\
    );

    var iter = map.keyIterator();
    while (iter.next()) |next| {
        try std.fmt.format(writer, "    {s},\n", .{next.*});
    }

    try writer.writeAll("};\n\n");
}

const opcodes_json = @embedFile("Opcodes.json");

const GenError = error{InvalidJSON};

fn parseInstructionsJSON() !Instructions {
    const parsed = try std.json.parseFromSlice(
        std.json.Value,
        alloc,
        opcodes_json,
        .{},
    );
    defer parsed.deinit();

    const obj = switch (parsed.value) {
        .object => |o| o,
        else => return GenError.InvalidJSON,
    };

    var instructions: Instructions = undefined;
    const unprefixed = obj.get("unprefixed") orelse return GenError.InvalidJSON;
    const cbprefixed = obj.get("cbprefixed") orelse return GenError.InvalidJSON;
    instructions.unprefixed = try parseInnerOpcodeJSON(unprefixed);
    instructions.cbprefixed = try parseInnerOpcodeJSON(cbprefixed);

    return instructions;
}

fn parseInnerOpcodeJSON(obj: std.json.Value) ![]Instruction {
    const innerObj = switch (obj) {
        .object => |o| o,
        else => return GenError.InvalidJSON,
    };

    const instrs = try alloc.alloc(Instruction, 256);

    var iter = innerObj.iterator();
    while (iter.next()) |entry| {
        const instruction = try std.json.parseFromValue(Instruction, alloc, entry.value_ptr.*, .{ .ignore_unknown_fields = true });
        const op = try std.fmt.parseInt(u8, entry.key_ptr.*, 0);
        instrs[op] = instruction.value;
    }

    return instrs;
}

fn normalizeMnemonic(mnemonic: []const u8) []const u8 {
    if (mnemonic.len >= 7 and std.mem.eql(u8, mnemonic[0..7], "ILLEGAL")) {
        return "ILLEGAL";
    }
    return mnemonic;
}

fn normalizeOperandName(name: []const u8) []const u8 {
    if (name.len == 0) {
        return name;
    }
    if (name[0] == '$') {
        return "VEC";
    }
    if (name[0] >= '0' and name[0] <= '9') {
        return "U3";
    }
    return name;
}
