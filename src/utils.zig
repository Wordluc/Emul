const fmt = @import("std").debug;

const memory = @import("engine.zig").memory;

const VARIABLES = enum { x, y, nnn, kk, n };
//
//nnn or addr - A 12-bit value, the lowest 12 bits of the instruction
//n or nibble - A 4-bit value, the lowest 4 bits of the instruction
//x - A 4-bit value, the lower 4 bits of the high byte of the instruction
//y - A 4-bit value, the upper 4 bits of the low byte of the instruction
//kk or byte - An 8-bit value, the lowest 8 bits of the instruction

pub fn GetVarFromOpCode(opCode: u16, v: VARIABLES) u16 {
    return switch (v) {
        .x => (opCode & 0x0F00) >> 8,
        .y => (opCode & 0x00F0) >> 4,
        .nnn => opCode & 0x0FFF,
        .n => (opCode & 0x000F),
        .kk => (opCode & 0x00FF),
    };
}

pub fn LoadFont(m: *memory, from: u16) !void {
    const fonts = [_]u8{
        0xF0, 0x90, 0x90, 0x90, 0xF0, //0
        0x20, 0x60, 0x20, 0x20, 0x70, //1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, //2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, //3
        0x90, 0x90, 0xF0, 0x10, 0x10, //4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, //5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, //6
        0xF0, 0x10, 0x20, 0x40, 0x40, //7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, //8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, //9
        0xF0, 0x90, 0xF0, 0x90, 0x90, //A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, //B
        0xF0, 0x80, 0x80, 0x80, 0xF0, //C
        0xE0, 0x90, 0x90, 0x90, 0xE0, //D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, //E
        0xF0, 0x80, 0xF0, 0x80, 0x80, //F
    };
    for (0.., fonts) |i, font| {
        try m.SetByte(from + @as(u16, @intCast(i)), font);
    }
}
pub fn LoadCode(m: *memory, from: u16, code: []u8) !void {
    for (0.., code) |i, opCode| {
        const i_int = @as(u16, @intCast(i));
        try m.SetByte(from + i_int, opCode);
    }
}
