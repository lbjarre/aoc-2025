const std = @import("std");
const aoc2025 = @import("aoc2025");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 2) {
        _ = try std.fs.File.stderr().write("usage: aoc2025 DAY\n");
        return error.IncorrectArgs;
    }
    const day = try std.fmt.parseInt(u8, args[1], 10);
    const input = try readInput(alloc, day);

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    try aoc2025.solve(stdout, input, day);
    try stdout.flush();
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
