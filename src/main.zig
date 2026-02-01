const rl = @import("raylib");
const ru = @import("raygui");
const utils = @import("utils.zig");

const engine = @import("engine.zig");
const std = @import("std");
const W_EDITOR = 900;
const H_EDITOR = 400;

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
pub fn main() !void {
    const W_GAME = engine.PIXEL_X * engine.SIZE_PIXEL;
    const H_GAME = engine.PIXEL_Y * engine.SIZE_PIXEL;
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
    const source_code = try loadSourceCode(allocator, "roms/5-quirks.ch8");
    defer allocator.free(source_code);

    try e.reg.SetPC(engine.FONT_ADDRESS_END);
    try utils.LoadCode(&e.memory, engine.FONT_ADDRESS_END, source_code);
    var stop: bool = false;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        if (!stop) {
            try e.RunCode();
        }
        if (ru.button(.{ .x = 60, .height = H_BUTTON, .width = 60, .y = H_GAME }, if (stop) "start" else "stop")) {
            stop = !stop;
        }
        for (0.., e.reg.regs) |i, v| {
            const max_len = 20;
            var buf: [max_len]u8 = undefined;
            const regName = try std.fmt.bufPrintZ(&buf, "r{}={}", .{ i, v });
            _ = ru.label(.{ .y = @as(f32, @floatFromInt(i)) * H_BUTTON, .width = 100, .height = H_BUTTON, .x = W_GAME }, regName);
        }
        const max_len = 20;
        var buf: [max_len]u8 = undefined;
        var regName = try std.fmt.bufPrintZ(&buf, "PC={}", .{e.reg.PC});
        _ = ru.label(.{ .y = 16 * H_BUTTON, .width = 100, .height = H_BUTTON, .x = W_GAME }, regName);
        buf = undefined;

        regName = try std.fmt.bufPrintZ(&buf, "ST={}", .{e.ST.time});
        _ = ru.label(.{ .y = 17 * H_BUTTON, .width = 100, .height = H_BUTTON, .x = W_GAME }, regName);

        regName = try std.fmt.bufPrintZ(&buf, "DT={}", .{e.DT.time});
        _ = ru.label(.{ .y = 18 * H_BUTTON, .width = 100, .height = H_BUTTON, .x = W_GAME }, regName);

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
