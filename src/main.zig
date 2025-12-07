const std = @import("std");
const aoc2025 = @import("aoc2025");

pub fn main() !void {
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    var stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    var args = std.process.args();
    _ = args.next() orelse unreachable;
    const arg = args.next() orelse {
        _ = try std.fs.File.stderr().write("usage: aoc2025 [DAY | 'all']\n");
        return error.InvalidArgs;
    };

    const mode = try Mode.parse(arg);
    try mode.exec(std.heap.page_allocator, stdout);
}

const Mode = union(enum) {
    /// Solve all days.
    all,
    /// Solve a single day.
    day: u8,

    fn parse(arg: []const u8) !Mode {
        if (std.mem.eql(u8, arg, "all")) {
            return .all;
        }
        const day = try std.fmt.parseInt(u8, arg, 10);
        return .{ .day = day };
    }

    fn exec(self: Mode, alloc: std.mem.Allocator, writer: *std.Io.Writer) !void {
        try switch (self) {
            .all => aoc2025.solveAll(alloc, writer),
            .day => |day| aoc2025.solve(alloc, writer, day),
        };
    }
};
