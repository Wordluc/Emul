const rl = @import("raylib");
const ru = @import("raygui");
const utils = @import("utils.zig");
const eql = @import("std").mem.eql;

const engine = @import("engine.zig");
const std = @import("std");

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
    rl.initWindow(
        engine.PIXEL_X * engine.SIZE_PIXEL,
        engine.PIXEL_Y * engine.SIZE_PIXEL,
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
    const beep: rl.Sound = try rl.loadSound("beep.wav");

    try e.reg.SetPC(engine.FONT_ADDRESS_END);
    try utils.LoadCode(&e.memory, engine.FONT_ADDRESS_END, source_code);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        try e.RunCode();
        if (e.ST.time > 0) {
            rl.playSound(beep);
        }
        rl.clearBackground(.black);
        rl.endDrawing();
    }
}
