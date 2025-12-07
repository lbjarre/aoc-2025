const std = @import("std");

pub const Context = struct {
    alloc: std.mem.Allocator,
    writer: *std.Io.Writer,
    input: []const u8,
};

const solvers = [_]*const fn (Context) anyerror!void{
    @import("./day01.zig").solve,
    @import("./day02.zig").solve,
    @import("./day03.zig").solve,
    @import("./day04.zig").solve,
    @import("./day05.zig").solve,
    @import("./day06.zig").solve,
};

pub fn solve(alloc: std.mem.Allocator, writer: *std.Io.Writer, day: u8) !void {
    if (day - 1 >= solvers.len) return error.InvalidDay;
    const solver = solvers[day - 1];

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const input = try readInput(arena.allocator(), day);

    try solver(.{
        .alloc = arena.allocator(),
        .writer = writer,
        .input = input,
    });
}

pub fn solveAll(alloc: std.mem.Allocator, writer: *std.Io.Writer) !void {
    for (0..solvers.len) |day| {
        try writer.print("day {d}\n", .{day + 1});
        try solve(alloc, writer, @intCast(day + 1));
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

test {
    std.testing.refAllDecls(@This());
}
