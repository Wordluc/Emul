const rl = @import("raylib");
const ru = @import("raygui");
const utils = @import("utils.zig");

const engine = @import("engine.zig");
const std = @import("std");
const W_EDITOR = 700;
const H_EDITOR = 400;
const W_GAME = engine.PIXEL_X * engine.SIZE_PIXEL;
const H_GAME = engine.PIXEL_Y * engine.SIZE_PIXEL;
const H_BUTTON = 30;

fn loadSourceCode(
    allocator: std.mem.Allocator,
    path: []const u8,
) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const buffer = try allocator.alloc(u8, engine.N_MEMORY - engine.FONT_ADDRESS_END);

    const bytes = std.mem.sliceAsBytes(buffer);
    _ = try file.readAll(bytes);

    return buffer;
}
const cellTable = struct { name: []const u8, size_cell: f32 = 50, value_u8: ?*const u8 = null, value_u16: ?*const u16 = null, value_bool: ?*const bool = null };
fn DrawTable(regs: []cellTable, _y: f32, _x: f32, col: f32, title: [:0]const u8) !void {
    var row: f32 = 0;
    var x: f32 = 0;
    var i: f32 = 0;
    var y = _y;
    var buf: [20]u8 = undefined;
    _ = ru.label(.{ .x = _x, .y = y, .height = H_BUTTON, .width = 200 }, title);
    y = y + H_BUTTON;
    var last_size_cell: f32 = 0;
    for (regs) |r| {
        if (i == 0) {
            last_size_cell = r.size_cell;
        } else {
            last_size_cell = regs[@intCast(@as(u8, @intFromFloat(i)) - 1)].size_cell;
        }
        x = @rem(i, col);
        buf = undefined;
        var regName: [:0]const u8 = undefined;
        if (r.value_u8) |p| {
            regName = try std.fmt.bufPrintZ(&buf, "{s}{}", .{ r.name, p.* });
        } else if (r.value_u16) |p| {
            regName = try std.fmt.bufPrintZ(&buf, "{s}{}", .{ r.name, p.* });
        } else if (r.value_bool) |p| {
            regName = try std.fmt.bufPrintZ(&buf, "{s}{s}", .{ r.name, if (p.*) "Down" else "Up" });
        }
        _ = ru.label(.{ .y = row * H_BUTTON + y, .width = r.size_cell, .height = H_BUTTON, .x = x * last_size_cell + _x }, regName);
        row = if (x == col - 1) row + 1 else row;
        i = i + 1;
    }
}
pub fn main() !void {
    rl.initWindow(
        W_GAME + W_EDITOR,
        H_GAME + H_EDITOR,
        "Emul",
    );
    rl.initAudioDevice();
    defer rl.closeWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var e = try engine.NewEngine();
    try utils.LoadFont(&e.memory, 0x0);
    //TODO: to test 5-quirks.ch8 5-quirks.ch8, 6-keypad.ch8
    const source_code = try loadSourceCode(allocator, "roms/tank.rom");
    defer allocator.free(source_code);

    try e.reg.SetPC(engine.FONT_ADDRESS_END);
    try utils.LoadCode(&e.memory, engine.FONT_ADDRESS_END, source_code);
    var stop: bool = false;
    var nameArrayAlloc: std.ArrayList([]const u8) = .empty;
    defer {
        for (nameArrayAlloc.items) |item| {
            allocator.free(item);
        }
        nameArrayAlloc.deinit(allocator);
    }

    var regsView: [19]cellTable = undefined;
    for (0.., e.reg.regs) |i, _| {
        try nameArrayAlloc.append(allocator, try std.fmt.allocPrint(allocator, "r{x}=", .{i}));
        regsView[i] = .{ .name = nameArrayAlloc.getLast(), .value_u8 = &e.reg.regs[i] };
    }
    regsView[regsView.len - 4] = .{
        .name = "WaitFor=",
        .value_u16 = &e.waitForKey_x,
        .size_cell = 200,
    };
    regsView[regsView.len - 3] = .{
        .name = "PC=",
        .value_u16 = &e.reg.PC,
    };
    regsView[regsView.len - 2] = .{
        .name = "DT=",
        .value_u8 = &e.DT.time,
    };
    regsView[regsView.len - 1] = .{
        .name = "ST=",
        .value_u8 = &e.ST.time,
    };

    var keyView: [16]cellTable = undefined;
    for (0.., e.keyboard.keys) |i, _| {
        try nameArrayAlloc.append(allocator, try std.fmt.allocPrint(allocator, "key:{x}=", .{i}));
        keyView[i] = .{ .name = nameArrayAlloc.getLast(), .value_bool = &e.keyboard.keys[i], .size_cell = 100 };
    }

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        if (!stop) {
            try e.RunCode();
        }
        if (ru.button(.{ .x = 60, .height = H_BUTTON, .width = 60, .y = H_GAME }, if (stop) "start" else "stop")) {
            stop = !stop;
        }
        try DrawTable(&regsView, H_GAME + 40, 0, 4, "Registri");
        try DrawTable(&keyView, H_GAME + 40, 300, 4, "Tastiera");
        if (stop) {
            if (ru.button(.{ .x = 0, .height = H_BUTTON, .width = 60, .y = H_GAME }, "<<")) {
                try e.reg.SetPC(e.reg.PC - 2);
                try e.RunCode();
            }
            if (ru.button(.{ .x = 120, .height = H_BUTTON, .width = 60, .y = H_GAME }, ">>")) {
                try e.reg.SetPC(e.reg.PC + 2);
                try e.RunCode();
            }
        }
        try e.display.Draw();

        rl.clearBackground(.black);
        rl.endDrawing();
    }
}
