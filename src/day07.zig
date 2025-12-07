const std = @import("std");

const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    const grid = try Grid.parse(ctx.input);
    const start = grid.findFirst('S') orelse return error.InvalidInput;

    const part1 = try solvePart1(ctx.alloc, grid, start);

    var memo: Memo = .init(ctx.alloc);
    defer memo.deinit();
    const part2 = try solvePart2(grid, start, &memo);

    try ctx.writer.print(
        \\part1: {d}
        \\part2: {d}
        \\
    ,
        .{ part1, part2 },
    );
}

fn solvePart1(alloc: std.mem.Allocator, grid: Grid, start: Pos) !u32 {
    var beams: std.ArrayList(Pos) = try .initCapacity(alloc, 1);
    defer beams.deinit(alloc);
    try beams.append(alloc, start);

    var splits: u32 = 0;
    while (beams.pop()) |beam| {
        const cell = grid.get(beam) orelse unreachable;
        switch (cell) {
            '.', 'S' => {
                const beam_next: Pos = .{ .x = beam.x, .y = beam.y + 1 };
                if (grid.inBounds(beam_next) and !contains(Pos, beams.items, beam_next)) {
                    try beams.insert(alloc, 0, beam_next);
                }
            },
            '^' => {
                splits += 1;
                const split_1: Pos = .{ .x = beam.x - 1, .y = beam.y + 1 };
                const split_2: Pos = .{ .x = beam.x + 1, .y = beam.y + 1 };
                if (grid.inBounds(split_1) and !contains(Pos, beams.items, split_1)) {
                    try beams.insert(alloc, 0, split_1);
                }
                if (grid.inBounds(split_2) and !contains(Pos, beams.items, split_2)) {
                    try beams.insert(alloc, 0, split_2);
                }
            },
            else => unreachable,
        }
    }

    return splits;
}

const Memo = std.AutoHashMap(Pos, u64);

fn solvePart2(grid: Grid, beam: Pos, memo: *Memo) !u64 {
    if (memo.get(beam)) |v| return v;

    const cell = grid.get(beam) orelse unreachable; // We check bounds when calling the fn.
    const timelines = switch (cell) {
        '.', 'S' => blk: {
            const beam_next: Pos = .{ .x = beam.x, .y = beam.y + 1 };
            // If the beam has exited the grid then it's a terminal case,
            // counting 1 timeline. Else recurse.
            const timelines = if (!grid.inBounds(beam_next)) 1 else try solvePart2(grid, beam_next, memo);
            break :blk timelines;
        },
        '^' => blk: {
            var timelines: u64 = 0;
            const splits = [_]Pos{
                .{ .x = beam.x - 1, .y = beam.y + 1 },
                .{ .x = beam.x + 1, .y = beam.y + 1 },
            };
            for (splits) |split| {
                if (grid.inBounds(split)) {
                    timelines += try solvePart2(grid, split, memo);
                }
            }
            break :blk timelines;
        },
        else => unreachable,
    };
    try memo.put(beam, timelines);
    return timelines;
}

const Pos = struct {
    x: i32,
    y: i32,

    fn eql(a: Pos, b: Pos) bool {
        return a.x == b.x and a.y == b.y;
    }
};

fn contains(comptime T: type, items: []const T, needle: T) bool {
    for (items) |item| {
        if (std.meta.eql(item, needle)) return true;
    }
    return false;
}

/// Grid stores the input buffer as-is and does the math to index into it.
const Grid = struct {
    buf: []const u8,
    /// Width of the rows, as calculated by the first line break. Note that
    /// this is the logical row width: the buffer also stores one extra newline
    /// character that should be skipped.
    width: usize,

    fn parse(src: []const u8) !Grid {
        const width = std.mem.indexOfScalar(u8, src, '\n') orelse return error.InvalidInput;
        return .{
            .buf = src,
            .width = width,
        };
    }

    fn inBounds(self: Grid, pos: Pos) bool {
        const x_ok = pos.x >= 0 and pos.x < self.width;
        const y_ok = pos.y >= 0 and pos.y < (self.buf.len / (self.width + 1));
        return x_ok and y_ok;
    }

    fn get(self: Grid, pos: Pos) ?u8 {
        if (!self.inBounds(pos)) return null;
        const x_sz: usize = @intCast(pos.x);
        const y_sz: usize = @intCast(pos.y);
        const index = (self.width + 1) * y_sz + x_sz;
        if (index >= self.buf.len) return null;
        return self.buf[index];
    }

    fn findFirst(self: Grid, cell: u8) ?Pos {
        const index = std.mem.indexOfScalar(u8, self.buf, cell) orelse return null;
        const y = @divTrunc(index, self.width + 1);
        const x = @mod(index, self.width + 1);
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
};

test "Grid" {
    const grid = try Grid.parse(
        \\12345
        \\abcde
        \\pqrst
        \\
    );

    try std.testing.expectEqual(true, grid.inBounds(.{ .x = 0, .y = 0 }));
    try std.testing.expectEqual(true, grid.inBounds(.{ .x = 1, .y = 1 }));
    try std.testing.expectEqual(true, grid.inBounds(.{ .x = 4, .y = 2 }));
    try std.testing.expectEqual(false, grid.inBounds(.{ .x = 4, .y = 3 }));
    try std.testing.expectEqual(false, grid.inBounds(.{ .x = 0, .y = 3 }));

    try std.testing.expectEqual('1', grid.get(.{ .x = 0, .y = 0 }));
    try std.testing.expectEqual('b', grid.get(.{ .x = 1, .y = 1 }));
    try std.testing.expectEqual('t', grid.get(.{ .x = 4, .y = 2 }));
    try std.testing.expectEqual(null, grid.get(.{ .x = -1, .y = -1 }));
    try std.testing.expectEqual(null, grid.get(.{ .x = 5, .y = 2 }));
    try std.testing.expectEqual(null, grid.get(.{ .x = 4, .y = 3 }));

    try std.testing.expectEqual(Pos{ .x = 0, .y = 0 }, grid.findFirst('1'));
    try std.testing.expectEqual(Pos{ .x = 4, .y = 0 }, grid.findFirst('5'));
    try std.testing.expectEqual(Pos{ .x = 0, .y = 1 }, grid.findFirst('a'));
    try std.testing.expectEqual(Pos{ .x = 0, .y = 2 }, grid.findFirst('p'));
    try std.testing.expectEqual(Pos{ .x = 4, .y = 2 }, grid.findFirst('t'));
    try std.testing.expectEqual(null, grid.findFirst('x'));
    try std.testing.expectEqual(null, grid.findFirst('0'));
}

test "Grid example input" {
    const grid = try Grid.parse(
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
        \\
    );

    try std.testing.expectEqual(true, grid.inBounds(.{ .x = 0, .y = 0 }));
    try std.testing.expectEqual(true, grid.inBounds(.{ .x = 14, .y = 0 }));
    try std.testing.expectEqual(true, grid.inBounds(.{ .x = 0, .y = 15 }));
    try std.testing.expectEqual(true, grid.inBounds(.{ .x = 14, .y = 15 }));
    try std.testing.expectEqual(false, grid.inBounds(.{ .x = -1, .y = -1 }));
    try std.testing.expectEqual(false, grid.inBounds(.{ .x = 15, .y = 0 }));
    try std.testing.expectEqual(false, grid.inBounds(.{ .x = 0, .y = 16 }));
    try std.testing.expectEqual(false, grid.inBounds(.{ .x = 15, .y = 16 }));
}

test "test input" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
        \\
    ;
    const want =
        \\part1: 21
        \\part2: 40
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(.{ .input = input, .writer = &writer, .alloc = std.testing.allocator });
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}
