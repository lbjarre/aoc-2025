const std = @import("std");

const days = 3;

pub fn solve(alloc: std.mem.Allocator, writer: *std.Io.Writer, day: u8) !void {
    const input = try readInput(alloc, day);
    defer alloc.free(input);
    try switch (day) {
        1 => @import("./day01.zig").solve(writer, input),
        2 => @import("./day02.zig").solve(writer, input),
        3 => @import("./day03.zig").solve(writer, input),
        else => error.InvalidDay,
    };
}

pub fn solveAll(alloc: std.mem.Allocator, writer: *std.Io.Writer) !void {
    for (1..days + 1) |day| {
        try writer.print("day {d}\n", .{day});
        try solve(alloc, writer, @intCast(day));
    }
}

fn readInput(alloc: std.mem.Allocator, day: u8) ![]const u8 {
    var buf: [128]u8 = undefined;

    // TODO: how do I zero-pad a number in a nicer way
    var filename: []const u8 = undefined;
    if (day < 10) {
        filename = try std.fmt.bufPrint(&buf, "input/day0{d}.txt", .{day});
    } else {
        filename = try std.fmt.bufPrint(&buf, "input/day{d}.txt", .{day});
    }

    return try std.fs.cwd().readFileAlloc(alloc, filename, 100 * 1024);
}
