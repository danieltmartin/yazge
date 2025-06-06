const Debugger = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const CPU = @import("CPU.zig");
const PPU = @import("PPU.zig");
const Gameboy = @import("Gameboy.zig");
const sm83 = @import("sm83.zig");

const Command = union(enum) {
    Continue,
    Step,
    PrintVRam,
    PrintOam,
    AddBreakpoint: struct {
        address: u16,
    },
    DeleteBreakpoint: struct {
        address: u16,
    },
    PrintCPUState,
    PrintLCDState,
    PrintClock,
    PrintInterruptState,
};

alloc: Allocator,
breakpoints: std.AutoHashMap(u16, void),
num_breakpoints: u64 = 0,
enabled: bool = false,
buf_out: std.io.BufferedWriter(4096, std.fs.File.Writer),
out_mutex: std.Thread.Mutex,
buf_in: std.io.BufferedReader(4096, std.fs.File.Reader),
stop_on_next: bool = false,
debugger_thread: std.Thread = undefined,
gameboy: *Gameboy,
paused: bool = false,
mutex: std.Thread.Mutex,
stopping: std.atomic.Value(bool),

pub fn init(alloc: Allocator, gameboy: *Gameboy, enabled: bool) !*Debugger {
    const debugger = try alloc.create(Debugger);
    errdefer alloc.destroy(debugger);

    const out = std.io.getStdOut();
    const buf_out = std.io.bufferedWriter(out.writer());

    const in = std.io.getStdIn();
    const bufIn = std.io.bufferedReader(in.reader());

    debugger.* = .{
        .alloc = alloc,
        .buf_out = buf_out,
        .out_mutex = std.Thread.Mutex{},
        .buf_in = bufIn,
        .breakpoints = std.AutoHashMap(u16, void).init(alloc),
        .gameboy = gameboy,
        .mutex = std.Thread.Mutex{},
        .stopping = std.atomic.Value(bool).init(false),
        .enabled = enabled,
    };

    debugger.debugger_thread = try std.Thread.spawn(.{}, replLoop, .{debugger});

    return debugger;
}

pub fn deinit(self: *Debugger) void {
    self.stopping.store(true, .release);
    self.debugger_thread.join();
    self.breakpoints.deinit();
    self.alloc.destroy(self);
}

pub fn replLoop(self: *Debugger) !void {
    if (!self.enabled) return;
    while (!self.stopping.load(.monotonic)) {
        try self.printPrompt();

        const reader = self.buf_in.reader();
        const line = try reader.readUntilDelimiterAlloc(self.alloc, '\n', 1024);
        defer self.alloc.free(line);

        if (line.len == 0) continue;

        const command = parseCommand(line) catch {
            try self.print("Invalid command.\n");
            continue;
        };

        switch (command) {
            .Continue => {
                self.mutex.lock();
                defer self.mutex.unlock();
                self.paused = false;
            },
            .Step => {
                self.mutex.lock();
                defer self.mutex.unlock();
                self.stop_on_next = true;
            },
            .PrintVRam => self.printVram(),
            .PrintOam => self.printOam(),
            .AddBreakpoint => |b| try self.addBreakpoint(b.address),
            .DeleteBreakpoint => |b| try self.deleteBreakpoint(b.address),
            .PrintCPUState => try self.printCPUState(),
            .PrintLCDState => self.printLCDState(),
            .PrintClock => self.printClock(),
            .PrintInterruptState => self.printInterruptState(),
        }
        std.time.sleep(10 * std.time.ns_per_ms);
    }
}

pub fn shouldStep(self: *Debugger) !bool {
    if (!self.mutex.tryLock()) return false;
    defer self.mutex.unlock();

    const opcode = self.gameboy.cpu.peekMem(self.gameboy.cpu.pc);
    const on_prefix = !self.gameboy.cpu.prefixed and sm83.unprefixed[opcode].mnemonic == .PREFIX;

    if (on_prefix) return true;

    if (self.gameboy.cpu.halted or self.gameboy.cpu.halt_bug) return true;

    if (self.stop_on_next or self.checkBreakpoint()) {
        self.stop_on_next = false;
        self.paused = true;
        try self.print("\n");
        try self.printCPUState();
        try self.printPrompt();
        return true;
    }

    return !self.paused;
}

fn printPrompt(self: *Debugger) !void {
    try self.print("> ");
}

fn print(self: *Debugger, text: []const u8) !void {
    self.out_mutex.lock();
    defer self.out_mutex.unlock();
    const writer = self.buf_out.writer();
    try writer.print("{s}", .{text});
    try self.buf_out.flush();
}

fn parseCommand(command: []const u8) !Command {
    if (std.mem.startsWith(u8, command, "breakpoint")) {
        const addr = try parseU16(command);
        return Command{ .AddBreakpoint = .{ .address = addr } };
    } else if (std.mem.startsWith(u8, command, "delete")) {
        const addr = try parseU16(command);
        return Command{ .DeleteBreakpoint = .{ .address = addr } };
    } else if (std.mem.eql(u8, command, "continue")) {
        return .Continue;
    } else if (std.mem.eql(u8, command, "step")) {
        return .Step;
    } else if (std.mem.eql(u8, command, "vram")) {
        return .PrintVRam;
    } else if (std.mem.eql(u8, command, "oam")) {
        return .PrintOam;
    } else if (std.mem.eql(u8, command, "cpu")) {
        return .PrintCPUState;
    } else if (std.mem.eql(u8, command, "lcd")) {
        return .PrintLCDState;
    } else if (std.mem.eql(u8, command, "clock")) {
        return .PrintClock;
    } else if (std.mem.eql(u8, command, "interrupt")) {
        return .PrintInterruptState;
    }

    return error.InvalidCommand;
}

fn parseU16(command: []const u8) !u16 {
    // Try to find the space separating the command and the address
    const space_pos = std.mem.indexOf(u8, command, " ");

    // If a space is found, we can split the string into command and address
    if (space_pos) |pos| {
        const address_str = command[(pos + 1)..]; // Take the part after the space
        return try std.fmt.parseInt(u16, address_str, 16);
    } else {
        return error.InvalidCommand;
    }
}

pub fn addBreakpoint(self: *Debugger, addr: u16) !void {
    try self.breakpoints.put(addr, {});
}

pub fn deleteBreakpoint(self: *Debugger, addr: u16) !void {
    _ = self.breakpoints.remove(addr);
}

fn checkBreakpoint(self: *Debugger) bool {
    if (!self.enabled) return false;
    return self.breakpoints.contains(self.gameboy.cpu.pc);
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

pub fn printVram(self: *Debugger) void {
    self.gameboy.mutex.lock();
    defer self.gameboy.mutex.unlock();
    for (self.gameboy.ppu.vram, 0..) |byte, i| {
        if (i % 32 == 0) {
            std.debug.print("\n{x:0>4}:", .{0x8000 + i});
        }
        std.debug.print(" {x:0>2}", .{byte});
    }
    std.debug.print("\n", .{});
}

pub fn printOam(self: *Debugger) void {
    self.gameboy.mutex.lock();
    defer self.gameboy.mutex.unlock();
    for (self.gameboy.ppu.oam, 0..) |obj, i| {
        std.debug.print("{d}: x={d} y={d} tile_index={d} bank={d} dmg_palette={d} priority={d}\n", .{
            i,
            obj.y_position,
            obj.x_position,
            obj.tile_index,
            obj.bank,
            obj.dmg_palette,
            obj.priority,
        });
    }
    std.debug.print("\n", .{});
}

fn printClock(self: *Debugger) void {
    self.gameboy.mutex.lock();
    defer self.gameboy.mutex.unlock();

    const timerControl = self.gameboy.mmu.readTimerControl();
    std.debug.print(
        \\Clock: {d}
        \\DIV (Divider register): ${x:0>2}
        \\TIMA (Timer counter): ${x:0>2}
        \\TMA (Timer modulo): ${x:0>2}
        \\TAC (Timer control):
        \\  Enable: {}
        \\  Clock select: {} T-cycles
        \\
    , .{
        self.gameboy.clock,
        self.gameboy.mmu.readDivider(),
        self.gameboy.mmu.readTimerCounter(),
        self.gameboy.mmu.readTimerModulo(),
        timerControl.enable,
        timerControl.tCycles(),
    });
}

fn printInterruptState(self: *Debugger) void {
    self.gameboy.mutex.lock();
    defer self.gameboy.mutex.unlock();

    const enable = self.gameboy.mmu.readInterruptEnable();
    const flag = self.gameboy.mmu.readInterruptFlag();
    std.debug.print(
        \\IME: {}
        \\Interrupt Enable:
        \\  VBlank: {}
        \\  LCD: {}
        \\  Timer: {}
        \\  Serial: {}
        \\  Joypad: {}
        \\Interrupt Flag:
        \\  VBlank: {}
        \\  LCD: {}
        \\  Timer: {}
        \\  Serial: {}
        \\  Joypad: {}
        \\
    , .{
        self.gameboy.cpu.ime,
        enable.v_blank,
        enable.lcd,
        enable.timer,
        enable.serial,
        enable.joypad,
        flag.v_blank,
        flag.lcd,
        flag.timer,
        flag.serial,
        flag.joypad,
    });
}

pub fn printCPUState(self: *Debugger) !void {
    self.gameboy.mutex.lock();
    defer self.gameboy.mutex.unlock();
    self.out_mutex.lock();
    defer self.out_mutex.unlock();
    const writer = self.buf_out.writer();
    try self.gameboy.cpu.dump(writer);

    const instruction = try disassembleNext(self.alloc, self.gameboy.cpu);
    try writer.print("-> {s}\n", .{instruction});

    try self.buf_out.flush();
}

pub fn printLCDState(self: *Debugger) void {
    self.gameboy.mutex.lock();
    defer self.gameboy.mutex.unlock();
    const ppu = self.gameboy.ppu;
    std.debug.print(
        \\LCD Control register: ${x:0>2}
        \\  LCD Enabled: {}
        \\  Background and Window enabled: {}
        \\  Objects enabled: {}
        \\  Window enabled: {}
        \\  Object size: {s}
        \\  Background tilemap: {s}
        \\  Window tilemap: {s}
        \\  Background and Window tileset addressing: {s}
        \\
        \\PPU Status:
        \\  Mode: {s}
        \\  Scanline: {d}
        \\
    , .{
        @as(u8, @bitCast(ppu.control)),
        ppu.control.enable,
        ppu.control.bg_window_enable,
        ppu.control.obj_enable,
        ppu.control.window_enable,
        if (ppu.control.obj_size == 1) "8x16" else "8x8",
        if (ppu.control.bg_tile_map) "$9C00" else "$9800",
        if (ppu.control.window_tile_map) "$9C00" else "$9800",
        if (ppu.control.bg_window_addressing_mode) "$8000+[0,127]" else "$9000+[-128,127]",
        @tagName(ppu.mode),
        ppu.current_scanline,
    });
}
