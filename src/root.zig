const std = @import("std");

const day01 = @import("./day01.zig");

pub fn solve(writer: *std.Io.Writer, input: []const u8, day: u8) !void {
    try switch (day) {
        1 => day01.solve(writer, input),
        else => error.InvalidDay,
    };
}
