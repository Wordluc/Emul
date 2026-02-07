const std = @import("std");
const fmt = std.debug;
const engine = @import("engine.zig").engine;
const engineZ = @import("engine.zig");
const utils = @import("utils.zig");
const rl = @import("raylib");

pub fn _00E0(e: *engine, _: u16) anyerror!void {
    e.display.Clear();
}
pub fn _00EE(e: *engine, _: u16) anyerror!void {
    const address = try e.stack.Pop();
    try e.reg.SetPC(address);
}
pub fn _00nn(_: *engine, _: u16) anyerror!void {}

// 0x1***
pub fn _1nnn(e: *engine, opCode: u16) anyerror!void {
    const nnn = utils.GetVarFromOpCode(opCode, .nnn);
    try e.reg.SetPC(nnn);
}

// 0x2***
pub fn _2nnn(e: *engine, opCode: u16) anyerror!void {
    const nnn = utils.GetVarFromOpCode(opCode, .nnn);
    e.stack.Push(e.reg.PC) catch {
        return;
    };
    return e.reg.SetPC(nnn);
}

// 0x3***
pub fn _3xkk(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const kk = utils.GetVarFromOpCode(opCode, .kk);
    const v_x = try e.reg.GetValue(x);
    if (kk == v_x) {
        try e.reg.IncrementePC(2);
    }
}

// 0x4***
pub fn _4xkk(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const kk = utils.GetVarFromOpCode(opCode, .kk);
    const v_x = try e.reg.GetValue(x);
    if (kk != v_x) {
        try e.reg.IncrementePC(2);
    }
}

// 0x5***
pub fn _5xy0(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_x = try e.reg.GetValue(x);
    const v_y = try e.reg.GetValue(y);
    if (v_y == v_x) {
        try e.reg.IncrementePC(2);
    }
}

// 0x6***
pub fn _6xkk(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const kk = utils.GetVarFromOpCode(opCode, .kk);
    try e.reg.SetVariable(x, kk);
}

// 0x7***
pub fn _7xkk(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const kk = utils.GetVarFromOpCode(opCode, .kk);
    const x_v = try e.reg.GetValue(x);
    try e.reg.SetVariable(x, x_v + kk);
}

// 0x8***
pub fn _8xy0(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y = try e.reg.GetValue(y);
    try e.reg.SetVariable(x, v_y);
}
pub fn _8xy1(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y = try e.reg.GetValue(y);
    const v_x = try e.reg.GetValue(x);
    try e.reg.SetVariable(x, v_y | v_x);
    try e.reg.SetVariable(15, 0);
}
pub fn _8xy2(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y = try e.reg.GetValue(y);
    const v_x = try e.reg.GetValue(x);
    try e.reg.SetVariable(x, v_y & v_x);
    try e.reg.SetVariable(15, 0);
}
pub fn _8xy3(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y = try e.reg.GetValue(y);
    const v_x = try e.reg.GetValue(x);
    try e.reg.SetVariable(x, v_y ^ v_x);
    try e.reg.SetVariable(15, 0);
}
pub fn _8xy4(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y: u16 = @intCast(try e.reg.GetValue(y));
    const v_x: u16 = @intCast(try e.reg.GetValue(x));
    const res: u16 = (v_x + v_y);

    try e.reg.SetVariable(x, @mod(@as(u16, @intCast(res)), 256));
    if (res > 255) {
        try e.reg.SetVariable(15, 0x1);
    } else {
        try e.reg.SetVariable(15, 0x0);
    }
}
pub fn _8xy5(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y: i16 = @intCast(try e.reg.GetValue(y));
    const v_x: i16 = @intCast(try e.reg.GetValue(x));
    const res: i16 = @mod((v_x - v_y), 256);

    try e.reg.SetVariable(x, @intCast(res));
    if (v_x >= v_y) {
        try e.reg.SetVariable(15, 0x1);
    } else {
        try e.reg.SetVariable(15, 0x0);
    }
}
pub fn _8xy6(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y = try e.reg.GetValue(y);
    const lowest_bit = v_y & (0x1);
    try e.reg.SetVariable(x, v_y / 2);
    if (lowest_bit != 0) {
        try e.reg.SetVariable(15, 0x1);
    } else {
        try e.reg.SetVariable(15, 0x00);
    }
}
pub fn _8xy7(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y: i16 = @intCast(try e.reg.GetValue(y));
    const v_x: i16 = @intCast(try e.reg.GetValue(x));
    const res: i16 = @mod((v_y - v_x), 256);

    try e.reg.SetVariable(x, @intCast(res));
    if (v_y >= v_x) {
        try e.reg.SetVariable(15, 0x1);
    } else {
        try e.reg.SetVariable(15, 0x0);
    }
}
pub fn _8xyE(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y = try e.reg.GetValue(y);
    const highest_bit = v_y & (0x1 << 7);
    try e.reg.SetVariable(x, v_y * 2);
    if (highest_bit != 0) {
        try e.reg.SetVariable(15, 0x1);
    } else {
        try e.reg.SetVariable(15, 0x00);
    }
}

// 0x9***
pub fn _9xy0(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const v_y = try e.reg.GetValue(y);
    const v_x = try e.reg.GetValue(x);
    if (v_x != v_y) {
        try e.reg.SetPC(e.reg.PC + 2);
    }
}

// 0xA***
pub fn _Annn(e: *engine, opCode: u16) anyerror!void {
    const nnn = utils.GetVarFromOpCode(opCode, .nnn);
    e.reg.I = nnn;
}

// 0xB***
pub fn _Bnnn(e: *engine, opCode: u16) anyerror!void {
    const _0 = try e.reg.GetValue(0);
    const nnn = utils.GetVarFromOpCode(opCode, .nnn);
    try e.reg.SetPC(nnn + _0);
}

// 0xC***
pub fn _Cxkk(e: *engine, opCode: u16) anyerror!void {
    const rand_f = std.crypto.random;
    const kk = utils.GetVarFromOpCode(opCode, .kk);
    const x = utils.GetVarFromOpCode(opCode, .x);
    try e.reg.SetVariable(x, kk & rand_f.int(u8));
}

// 0xD***
pub fn _Dxyn(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const y = utils.GetVarFromOpCode(opCode, .y);
    const n = utils.GetVarFromOpCode(opCode, .n);
    const v_x = try e.reg.GetValue(x);
    const v_y = try e.reg.GetValue(y);
    for (0..n) |i| {
        const i_u16 = @as(u16, @intCast(i));
        const i_u8 = @as(u8, @intCast(i));
        const address = @as(u16, e.reg.I + i_u16);
        const b = try e.memory.GetByte(address);
        const conflict = try e.display.SetByte(v_x, v_y + i_u8, b);
        if (conflict) {
            try e.reg.SetVariable(15, 0x1);
        } else {
            try e.reg.SetVariable(15, 0x00);
        }
    }
}

// 0xE***
pub fn _Ex9E(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const v_x = try e.reg.GetValue(x);
    if (e.keyboard.IsDown(v_x)) {
        try e.reg.IncrementePC(2);
    }
}
pub fn _ExA1(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const v_x = try e.reg.GetValue(x);
    if (!e.keyboard.IsDown(v_x)) {
        try e.reg.IncrementePC(2);
    }
}

// 0xF***
pub fn _Fx07(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    try e.reg.SetVariable(x, e.DT.time);
}
pub fn _Fx0A(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    e.waitForKey_x = x;
}
pub fn _Fx15(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const v_x = try e.reg.GetValue(x);
    e.DT.time = v_x;
}
//Sound
pub fn _Fx18(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const v_x = try e.reg.GetValue(x);
    e.ST.time = v_x;
}
pub fn _Fx1E(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const v_x = try e.reg.GetValue(x);
    e.reg.I = e.reg.I + v_x;
}
pub fn _Fx29(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const v_x: u16 = @intCast(try e.reg.GetValue(x));
    e.reg.I = 5 * v_x;
}
pub fn _Fx33(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x);
    const v_x = try e.reg.GetValue(x);
    var i = e.reg.I;
    try e.memory.SetByte(i, v_x / 100);
    i += 1;
    try e.memory.SetByte(i, v_x / 10 % 10);
    i += 1;
    try e.memory.SetByte(i, v_x % 10);
}
pub fn _Fx55(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x) + 1;
    for (0..x) |i| {
        const u16_i = @as(u16, @intCast(i));
        try e.memory.SetByte(e.reg.I + u16_i, try e.reg.GetValue(u16_i));
    }
    e.reg.I = e.reg.I + x;
}
pub fn _Fx65(e: *engine, opCode: u16) anyerror!void {
    const x = utils.GetVarFromOpCode(opCode, .x) + 1;
    for (0..x) |i| {
        const u16_i = @as(u16, @intCast(i));
        try e.reg.SetVariable(u16_i, try e.memory.GetByte(e.reg.I + u16_i));
    }
    e.reg.I = e.reg.I + x;
}
pub fn _F000(_: *engine, _: u16) anyerror!void {
    return error{Stop}.Stop;
}
