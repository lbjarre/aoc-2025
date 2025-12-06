const std = @import("std");
const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var it = std.mem.splitSequence(u8, ctx.input, "\n");
    while (it.next()) |line| {
        if (line.len == 0) break;
        part1 += maxJoltage(line, 2);
        part2 += maxJoltage(line, 12);
    }

    try ctx.writer.print(
        \\part1: {d}
        \\part2: {d}
        \\
    , .{ part1, part2 });
}

fn maxJoltage(line: []const u8, count: u8) u64 {
    var joltage: u64 = 0;
    var search = line;

    var rem: usize = count;
    while (rem > 0) : (rem -= 1) {
        const index = std.mem.indexOfMax(u8, search[0 .. search.len - rem + 1]);
        const digit = search[index] - '0';
        joltage = joltage * 10 + digit;
        search = search[index + 1 ..];
    }

    return joltage;
}

test "joltage" {
    try std.testing.expectEqual(98, maxJoltage("987654321111111", 2));
    try std.testing.expectEqual(89, maxJoltage("811111111111119", 2));
    try std.testing.expectEqual(78, maxJoltage("234234234234278", 2));
    try std.testing.expectEqual(92, maxJoltage("818181911112111", 2));

    try std.testing.expectEqual(987654321111, maxJoltage("987654321111111", 12));
    try std.testing.expectEqual(811111111119, maxJoltage("811111111111119", 12));
    try std.testing.expectEqual(434234234278, maxJoltage("234234234234278", 12));
    try std.testing.expectEqual(888911112111, maxJoltage("818181911112111", 12));
}

test "test input" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const want =
        \\part1: 357
        \\part2: 3121910778619
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(&writer, input);
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}
