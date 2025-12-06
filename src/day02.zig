const std = @import("std");
const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    const input_trim = std.mem.trimEnd(u8, ctx.input, "\n");

    var part1: u64 = 0;
    var part2: u64 = 0;
    var it = std.mem.splitSequence(u8, input_trim, ",");
    while (it.next()) |range_str| {
        const range = try Range.parse(range_str);
        var range_it = range.iter();
        while (range_it.next()) |id| {
            var buf: [128]u8 = undefined;
            const index = std.fmt.printInt(&buf, id, 10, .lower, .{});
            const str = buf[0..index];

            if (isRepeated(str)) {
                part1 += id;
            }
            if (hasOnlyRepeats(str)) {
                part2 += id;
            }
        }
    }

    try ctx.writer.print(
        \\part1: {d}
        \\part2: {d}
        \\
    , .{ part1, part2 });
}

const Range = struct {
    start: u64,
    end: u64,

    fn parse(src: []const u8) !Range {
        const index = std.mem.indexOf(u8, src, "-") orelse return error.MissingDash;
        const start = try std.fmt.parseInt(u64, src[0..index], 10);
        const end = try std.fmt.parseInt(u64, src[index + 1 ..], 10);
        return .{ .start = start, .end = end };
    }

    fn iter(self: Range) Iterator {
        return .{ .id = self.start, .end = self.end };
    }

    const Iterator = struct {
        id: u64,
        end: u64,

        fn next(it: *Iterator) ?u64 {
            if (it.id > it.end) {
                return null;
            }
            const yield = it.id;
            it.id += 1;
            return yield;
        }
    };
};

/// Check the repeat pattern for part1: the string is exactly two repeated substring.
fn isRepeated(id: []const u8) bool {
    if (@mod(id.len, 2) != 0) {
        return false;
    }

    const midpoint = id.len / 2;
    const first = id[0..midpoint];
    const second = id[midpoint..];
    return std.mem.eql(u8, first, second);
}

/// Check the repeat pattern for part2: the string is exactly n repeated substrings for any n.
fn hasOnlyRepeats(id: []const u8) bool {
    // Don't know of a good way of only iterating over even divisors of the
    // string length, so we iter over all of them and filter.
    var length = id.len - 1;
    blk: while (length > 0) {
        defer length -= 1;
        if (@rem(id.len, length) != 0) {
            continue;
        }

        // Check if we have n repeated substrings: extract the first substring
        // of this length and check if the other ones are equal.
        const repeats = @divExact(id.len, length);
        const first = id[0..length];
        for (1..repeats) |r| {
            const slice = id[r * length .. (r + 1) * length];
            if (!std.mem.eql(u8, first, slice)) {
                continue :blk;
            }
        }
        // We found a match!
        return true;
    }

    return false;
}

test "test input" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;
    const want =
        \\part1: 1227775554
        \\part2: 4174379265
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(&writer, input);
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}

test "isRepeated" {
    try std.testing.expect(isRepeated("11"));
    try std.testing.expect(isRepeated("1111"));
    try std.testing.expect(isRepeated("1212"));
    try std.testing.expect(isRepeated("123123"));
    try std.testing.expect(!isRepeated("111"));
    try std.testing.expect(!isRepeated("1122"));
}

test "hasOnlyRepeats" {
    try std.testing.expect(hasOnlyRepeats("12341234"));
    try std.testing.expect(hasOnlyRepeats("123123123"));
    try std.testing.expect(hasOnlyRepeats("12121212"));
    try std.testing.expect(hasOnlyRepeats("1111111"));
}
