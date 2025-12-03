const std = @import("std");
const aoc2025 = @import("aoc2025");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const alloc = gpa.allocator();

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    var stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 2) {
        _ = try std.fs.File.stderr().write("usage: aoc2025 [DAY | 'all']\n");
        return error.IncorrectArgs;
    }

    const mode = try Mode.parse(args[1]);
    try mode.exec(alloc, stdout);
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
