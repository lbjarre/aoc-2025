const std = @import("std");
const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    var database = try Database.parse(ctx.alloc, ctx.input);
    defer database.deinit(ctx.alloc);

    // Part 1.
    var fresh_ids: u64 = 0;
    for (database.ids.items) |id| {
        for (database.ranges.items) |range| {
            if (range.contains(id)) {
                fresh_ids += 1;
                break;
            }
        }
    }

    // Part 2.
    mergeRanges(&database.ranges);
    var total_ids: u64 = 0;
    for (database.ranges.items) |range| {
        total_ids += range.size();
    }

    try ctx.writer.print(
        \\part1: {d}
        \\part2: {d}
        \\
    ,
        .{ fresh_ids, total_ids },
    );
}

const Database = struct {
    ranges: std.ArrayList(Range),
    ids: std.ArrayList(u64),

    fn parse(alloc: std.mem.Allocator, input: []const u8) !Database {
        var it = std.mem.splitScalar(u8, input, '\n');

        // Parse ranges.
        var ranges: std.ArrayList(Range) = .empty;
        errdefer ranges.deinit(alloc);
        while (it.next()) |line| {
            if (line.len == 0) break;
            const range = try Range.parse(line);
            try ranges.append(alloc, range);
        }

        // Parse ids.
        var ids: std.ArrayList(u64) = .empty;
        errdefer ids.deinit(alloc);
        while (it.next()) |line| {
            if (line.len == 0) break;
            const id = try std.fmt.parseInt(u64, line, 10);
            try ids.append(alloc, id);
        }

        return .{
            .ranges = ranges,
            .ids = ids,
        };
    }

    fn deinit(self: *Database, alloc: std.mem.Allocator) void {
        self.ranges.deinit(alloc);
        self.ids.deinit(alloc);
    }
};

const Range = struct {
    lower: u64,
    upper: u64,

    fn parse(src: []const u8) !Range {
        const index = std.mem.indexOfScalar(u8, src, '-') orelse return error.MissingDash;
        const lower = try std.fmt.parseInt(u64, src[0..index], 10);
        const upper = try std.fmt.parseInt(u64, src[index + 1 ..], 10);
        return .{ .lower = lower, .upper = upper };
    }

    fn contains(self: Range, num: u64) bool {
        return self.lower <= num and num <= self.upper;
    }

    /// Merge two ranges together. Returns null if the ranges does not overlap.
    fn merge(a: Range, b: Range) ?Range {
        if (!a.contains(b.lower) and !b.contains(a.lower)) return null;

        const lower = @min(a.lower, b.lower);
        const upper = @max(a.upper, b.upper);
        return .{ .lower = lower, .upper = upper };
    }

    fn size(self: Range) u64 {
        return self.upper - self.lower + 1;
    }

    fn lessThan(context: void, a: Range, b: Range) bool {
        _ = context;
        return a.lower < b.lower;
    }
};

// Merge overlapping ranges into single ranges.
fn mergeRanges(ranges: *std.ArrayList(Range)) void {
    std.sort.insertion(Range, ranges.items, {}, Range.lessThan);
    merge: while (true) {
        for (0..ranges.items.len - 1) |index| {
            const a = ranges.items[index];
            const b = ranges.items[index + 1];
            // If the range overlap: replace them with the merged range and
            // restart the loop.
            //
            // This is probably a bit inefficient since the prefix of the array
            // will already be done but we repeat work here. We probably only
            // need to back up one index or so, but haven't done the math.
            if (a.merge(b)) |new_range| {
                ranges.replaceRangeAssumeCapacity(index, 2, &[_]Range{new_range});
                continue :merge;
            }
        }
        return;
    }
}

test "mergeRanges" {
    const alloc = std.testing.allocator;
    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(alloc);
    try ranges.append(alloc, .{ .lower = 3, .upper = 5 });
    try ranges.append(alloc, .{ .lower = 10, .upper = 14 });
    try ranges.append(alloc, .{ .lower = 16, .upper = 20 });
    try ranges.append(alloc, .{ .lower = 12, .upper = 18 });

    mergeRanges(&ranges);
    const want = [_]Range{
        .{ .lower = 3, .upper = 5 },
        .{ .lower = 10, .upper = 20 },
    };
    try std.testing.expectEqualSlices(Range, &want, ranges.items);
}

test "test input" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
        \\
    ;
    const want =
        \\part1: 3
        \\part2: 14
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(.{ .writer = &writer, .input = input, .alloc = std.testing.allocator });
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}
