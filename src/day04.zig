const std = @import("std");
const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    var map = HM.init(ctx.alloc);
    defer map.deinit();

    var it = std.mem.splitSequence(u8, ctx.input, "\n");
    var y: i16 = 0;
    var width: u16 = 0;
    var height: u16 = 0;
    while (it.next()) |line| {
        if (line.len == 0) break;
        var x: i16 = 0;
        for (line) |c| {
            const cell = Cell.parse(c) orelse return error.InvalidCell;
            try map.put(.{ .x = x, .y = y }, cell);
            x += 1;
        }
        y += 1;
        width = @max(width, x);
        height = @max(height, y);
    }

    const accessible = countAccessible(&map, width, height);
    const removed = try remove(ctx.alloc, &map, width, height);

    try ctx.writer.print("part1: {d}\n", .{accessible});
    try ctx.writer.print("part2: {d}\n", .{removed});
}

fn countAccessible(map: *HM, width: u16, height: u16) u32 {
    var accessible: u32 = 0;
    for (0..height) |y| {
        for (0..width) |x| {
            const key: Key = .{ .x = @intCast(x), .y = @intCast(y) };
            const c = map.get(key) orelse unreachable;
            if (c == .empty) continue;

            const adj = [_]Key{
                .{ .x = -1, .y = -1 },
                .{ .x = 0, .y = -1 },
                .{ .x = 1, .y = -1 },
                .{ .x = -1, .y = 0 },
                .{ .x = 1, .y = 0 },
                .{ .x = -1, .y = 1 },
                .{ .x = 0, .y = 1 },
                .{ .x = 1, .y = 1 },
            };
            var count: u8 = 0;
            for (adj) |delta| {
                const neighbor = map.get(key.add(delta)) orelse continue;
                if (neighbor == .roll) count += 1;
            }
            if (count < 4) accessible += 1;
        }
    }
    return accessible;
}

fn remove(alloc: std.mem.Allocator, map: *HM, width: u16, height: u16) !u32 {
    var removed: u32 = 0;
    while (true) {
        const keys = try accessibleKeys(alloc, map, width, height);
        defer alloc.free(keys);
        if (keys.len == 0) return removed;

        removed += @intCast(keys.len);
        for (keys) |key| {
            try map.put(key, .empty);
        }
    }
}

fn accessibleKeys(alloc: std.mem.Allocator, map: *HM, width: u16, height: u16) ![]Key {
    var accessible: std.ArrayList(Key) = try .initCapacity(alloc, 0);
    defer accessible.deinit(alloc);

    for (0..height) |y| {
        for (0..width) |x| {
            const key: Key = .{ .x = @intCast(x), .y = @intCast(y) };
            const c = map.get(key) orelse unreachable;
            if (c == .empty) continue;

            const adj = [_]Key{
                .{ .x = -1, .y = -1 },
                .{ .x = 0, .y = -1 },
                .{ .x = 1, .y = -1 },
                .{ .x = -1, .y = 0 },
                .{ .x = 1, .y = 0 },
                .{ .x = -1, .y = 1 },
                .{ .x = 0, .y = 1 },
                .{ .x = 1, .y = 1 },
            };
            var count: u8 = 0;
            for (adj) |delta| {
                const neighbor = map.get(key.add(delta)) orelse continue;
                if (neighbor == .roll) count += 1;
            }
            if (count < 4) {
                try accessible.append(alloc, key);
            }
        }
    }

    return accessible.toOwnedSlice(alloc);
}

const Key = struct {
    x: i16,
    y: i16,

    fn add(a: Key, b: Key) Key {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }
};
const Ctx = struct {
    pub fn hash(_: Ctx, key: Key) u64 {
        var h = std.hash.Wyhash.init(0);
        std.hash.autoHash(&h, key);
        return h.final();
    }
    pub fn eql(_: Ctx, a: Key, b: Key) bool {
        return a.x == b.x and a.y == b.y;
    }
};
const HM = std.HashMap(Key, Cell, Ctx, std.hash_map.default_max_load_percentage);

const Cell = enum {
    roll,
    empty,

    fn parse(char: u8) ?Cell {
        return switch (char) {
            '@' => .roll,
            '.' => .empty,
            else => null,
        };
    }
};

test "test input" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
        \\
    ;
    const want =
        \\part1: 13
        \\part2: 43
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(&writer, input);
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}
