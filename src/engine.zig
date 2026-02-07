const std = @import("std");
const rl = @import("raylib");
const set = @import("instructions.zig");

const N_REGISTERS = 16;
const N_STASK = 16;
pub const N_MEMORY = 4096;
const N_INSTRUCTIONS = 10;
pub const PIXEL_X = 64;
pub const PIXEL_Y = 32;
pub const SIZE_PIXEL = 10;
pub const FONT_ADDRESS_END = 0x200;

const timer = struct {
    time: u8,
    _time: f32 = 0,
    rate: u16,
    fn Decrease(this: *@This()) bool {
        if (this.time == 0) {
            this.time = 0;
            return true;
        }
        this._time = this._time - rl.getFrameTime();
        if (this._time <= 0) {
            this.time = this.time - 1;
            this._time = 1.0 / @as(f32, @floatFromInt(this.rate));
        }
        return false;
    }
};
const keyboard = struct {
    keys: [16]bool,
    map: []const mapKey,
    isSomethingPressed: bool = false,
    lastPressedKey: u4 = 0,
    pub fn IsDown(this: *@This(), x: u8) bool {
        return this.keys[x];
    }
    pub fn Print(this: *@This()) void {
        std.debug.print("--------------\n", .{});
        for (this.map) |map| {
            std.debug.print("{} {x} : {}\n", .{ map.char, map.hex, this.keys[map.hex] });
        }
        std.debug.print("--------------\n", .{});
    }
    pub fn Refresh(this: *@This()) void {
        this.isSomethingPressed = false;
        for (this.map) |map| {
            const press = rl.isKeyDown(map.char);

            this.keys[map.hex] = press;
            this.isSomethingPressed |= press;
            if (press) {
                this.lastPressedKey = map.hex;
            }
        }
    }
};
const display = struct {
    pixel: [PIXEL_Y]u64,

    pub fn Clear(this: *@This()) void {
        this.pixel = std.mem.zeroes([PIXEL_Y]u64);
    }
    pub fn SetByte(this: *@This(), _x: u8, _y: u16, v: u8) !bool {
        //WRAP ON THE LEFT/IRGHT
        const y = @as(u16, @intCast(_y)) % PIXEL_Y;
        var collide = false;
        for (0..8) |i_left| {
            const x: u8 = @intCast((_x + i_left) % PIXEL_X);

            //           const bit: u257 = @intCast((v >> @as(u3, @intCast(i_left))) & 1);
            const bit: u257 = (v >> @intCast(7 - i_left)) & 1;

            const pre = this.pixel[y];
            this.pixel[y] ^= @as(u64, @intCast(bit << x));
            if (pre > this.pixel[y]) {
                collide = true;
            }
        }
        return collide;
    }

    pub fn Draw(this: *@This()) !void {
        for (0.., this.pixel) |y, row| {
            for (0..PIXEL_X) |x| {
                const mask = @as(u64, 0x1) << @as(u6, @intCast(x));
                const pixel = mask & row;
                if (pixel != 0) {
                    rl.drawRectangle(@intCast(x * SIZE_PIXEL), @intCast(y * SIZE_PIXEL), SIZE_PIXEL, SIZE_PIXEL, .green);
                } else {
                    rl.drawRectangle(@intCast(x * SIZE_PIXEL), @intCast(y * SIZE_PIXEL), SIZE_PIXEL, SIZE_PIXEL, .gray);
                }
            }
        }
    }
};
const registers = struct {
    regs: [N_REGISTERS]u8,
    I: u16,
    PC: u16,
    pub fn GetValue(this: *@This(), i: u16) !u8 {
        return this.regs[i];
    }
    pub fn SetVariable(this: *@This(), reg: u16, v: u16) !void {
        this.regs[reg] = @intCast(v & 0xFF);
    }
    pub fn IncrementePC(this: *@This(), by: u16) !void {
        this.PC += by;
    }
    pub fn SetPC(this: *@This(), by: u16) !void {
        this.PC = by;
    }
};
const stack = struct {
    stack: [N_STASK]u16,
    sp: u8 = 0,
    pub fn Pop(this: *@This()) !u16 {
        if (this.sp == 0) {
            return error{UnderFlow}.UnderFlow;
        }
        this.sp -= 1;

        const v = this.stack[this.sp];
        return v;
    }
    pub fn Push(this: *@This(), value: u16) !void {
        if (this.sp == N_STASK) {
            return error{OverFlow}.OverFlow;
        }
        this.stack[this.sp] = value;
        this.sp += 1;
    }
};
pub const memory = struct {
    memory: [N_MEMORY]u8,
    pub fn GetByte(this: *@This(), address: u16) !u8 {
        return this.memory[address];
    }
    pub fn SetByte(this: *@This(), address: u16, value: u8) !void {
        this.memory[address] = value;
    }
};
fn strToHex(str: u8) !u32 {
    const err = error{ErrorHex};
    return switch (str) {
        '0'...'9' => str - '0',
        'A'...'F' => str - 'A' + 10,
        else => err.ErrorHex,
    };
}
pub const engine = struct {
    reg: registers,
    memory: memory,
    instructionSet: []const instructionSet,
    allocator: std.mem.Allocator,
    preInst: []const u8,
    stack: stack,
    display: display,
    keyboard: keyboard,
    DT: timer,
    ST: timer,
    beep: rl.Sound,
    waitForKey_x: u16,
    pub fn GetPreInst(t: *@This()) []const u8 {
        return t.preInst;
    }
    pub fn RunOpCode(t: *@This(), opCode: u16) !void {
        var c: u8 = ' ';
        const _OxF: u16 = 0xF000;
        for (t.instructionSet) |inst| {
            var mask: u16 = 0;
            for (0..4) |i| {
                mask = _OxF >> @as(u4, @intCast(i)) * 4;
                c = inst.inst[i];
                if (c == '.') {
                    continue;
                }
                const cHex = try strToHex(c) << (@as(u5, @intCast(3 - i)) * 4);
                if (opCode & mask != cHex) {
                    mask = 0;
                    break;
                }
            }
            if (mask == 0xF) {
                t.preInst = inst.inst;
                return try inst.callback(t, opCode);
            }
        }
    }
    pub fn GetOpCode(t: *@This(), address: u16) u16 {
        const h = @as(u16, try t.memory.GetByte(address));
        const l = try t.memory.GetByte(address + 1);
        return h << 8 | l;
    }
    pub fn RunCode(t: *@This()) !void {
        t.keyboard.Refresh();
        if (t.ST.time > 0) {
            rl.playSound(t.beep);
        }
        _ = t.DT.Decrease();
        _ = t.ST.Decrease();
        if (t.waitForKey_x != 666) {
            if (!t.keyboard.isSomethingPressed) {
                return;
            }
            try t.reg.SetVariable(t.waitForKey_x, t.keyboard.lastPressedKey);
            t.waitForKey_x = 666;
        }
        const opCode = t.GetOpCode(t.reg.PC);
        try t.reg.IncrementePC(2);
        try t.RunOpCode(opCode);
    }
};

const instructionSet = struct {
    inst: []const u8,
    callback: *const fn (e: *engine, inst: u16) anyerror!void,
};
const mapKey = struct { char: rl.KeyboardKey, hex: u4 };
fn newRegisters() anyerror!registers {
    return registers{ .regs = std.mem.zeroes([N_REGISTERS]u8), .I = 0, .PC = 0 };
}
fn newMemory() anyerror!memory {
    return memory{
        .memory = std.mem.zeroes([N_MEMORY]u8),
    };
}
pub fn NewEngine() anyerror!engine {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    return engine{
        .reg = try newRegisters(),
        .memory = try newMemory(),
        .instructionSet = getInstructionsSet(),
        .allocator = allocator,
        .preInst = "0000",
        .stack = .{ .stack = std.mem.zeroes([N_STASK]u16), .sp = 0 },
        .display = .{ .pixel = std.mem.zeroes([PIXEL_Y]u64) },
        .keyboard = .{ .keys = std.mem.zeroes([16]bool), .map = getKeysMap() },
        .DT = .{ .time = 0, .rate = 60 },
        .ST = .{ .time = 0, .rate = 60 },
        .waitForKey_x = 666,
        .beep = try rl.loadSound("beep.wav"),
    };
}
fn getKeysMap() []const mapKey {
    return &[_]mapKey{
        .{ .char = .one, .hex = 0x1 },
        .{ .char = .two, .hex = 0x2 },
        .{ .char = .three, .hex = 0x3 },
        .{ .char = .four, .hex = 0xC },
        .{ .char = .q, .hex = 0x4 },
        .{ .char = .w, .hex = 0x5 },
        .{ .char = .e, .hex = 0x6 },
        .{ .char = .r, .hex = 0xD },
        .{ .char = .a, .hex = 0x7 },
        .{ .char = .s, .hex = 0x8 },
        .{ .char = .d, .hex = 0x9 },
        .{ .char = .f, .hex = 0xE },
        .{ .char = .z, .hex = 0xA },
        .{ .char = .x, .hex = 0x0 },
        .{ .char = .c, .hex = 0xB },
        .{ .char = .v, .hex = 0xF },
    };
}
fn getInstructionsSet() []const instructionSet {
    return &[_]instructionSet{
        // 0x0***
        .{ .inst = "00E0", .callback = set._00E0 },
        .{ .inst = "00EE", .callback = set._00EE },
        .{ .inst = "00..", .callback = set._00nn },
        // 0x1***
        .{ .inst = "1...", .callback = set._1nnn },
        // 0x2***
        .{ .inst = "2...", .callback = set._2nnn },
        // 0x3***
        .{ .inst = "3...", .callback = set._3xkk },
        // 0x4***
        .{ .inst = "4...", .callback = set._4xkk },
        // 0x5***
        .{ .inst = "5..0", .callback = set._5xy0 },
        // 0x6***
        .{ .inst = "6...", .callback = set._6xkk },
        // 0x7***
        .{ .inst = "7...", .callback = set._7xkk },
        // 0x8***
        .{ .inst = "8..0", .callback = set._8xy0 },
        .{ .inst = "8..1", .callback = set._8xy1 },
        .{ .inst = "8..2", .callback = set._8xy2 },
        .{ .inst = "8..3", .callback = set._8xy3 },
        .{ .inst = "8..4", .callback = set._8xy4 },
        .{ .inst = "8..5", .callback = set._8xy5 },
        .{ .inst = "8..6", .callback = set._8xy6 },
        .{ .inst = "8..7", .callback = set._8xy7 },
        .{ .inst = "8..E", .callback = set._8xyE },
        // 0x9***
        .{ .inst = "9..0", .callback = set._9xy0 },
        // 0xA***
        .{ .inst = "A...", .callback = set._Annn },
        // 0xB***
        .{ .inst = "B...", .callback = set._Bnnn },
        // 0xC***
        .{ .inst = "C...", .callback = set._Cxkk },
        // 0xD***
        .{ .inst = "D...", .callback = set._Dxyn },
        // 0xE***
        .{ .inst = "E.9E", .callback = set._Ex9E },
        .{ .inst = "E.A1", .callback = set._ExA1 },
        // 0xF***
        .{ .inst = "F.07", .callback = set._Fx07 },
        .{ .inst = "F.0A", .callback = set._Fx0A },
        .{ .inst = "F.15", .callback = set._Fx15 },
        .{ .inst = "F.18", .callback = set._Fx18 },
        .{ .inst = "F.1E", .callback = set._Fx1E },
        .{ .inst = "F.29", .callback = set._Fx29 },
        .{ .inst = "F.33", .callback = set._Fx33 },
        .{ .inst = "F.55", .callback = set._Fx55 },
        .{ .inst = "F.65", .callback = set._Fx65 },
        .{ .inst = "F000", .callback = set._F000 },
    };
}
