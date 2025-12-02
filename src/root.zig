const std = @import("std");

const day01 = @import("./day01.zig");
const day02 = @import("./day02.zig");
const day03 = @import("./day03.zig");

pub fn solve(writer: *std.Io.Writer, input: []const u8, day: u8) !void {
    try switch (day) {
        1 => day01.solve(writer, input),
        2 => day02.solve(writer, input),
        3 => day03.solve(writer, input),
        else => error.InvalidDay,
    };
}
