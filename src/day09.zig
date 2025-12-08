const std = @import("std");

const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    var points: std.ArrayList(Point) = .empty;
    defer points.deinit(ctx.alloc);

    var lines_it = std.mem.splitScalar(u8, ctx.input, '\n');
    while (lines_it.next()) |line| {
        if (line.len == 0) break;
        const point = try Point.parse(line);
        try points.append(ctx.alloc, point);
    }

    const max_area = maxArea(points.items);
    try ctx.writer.print("part1: {d}\n", .{max_area});

    const max_area_in_bounds = try maxAreaInBounds(ctx.alloc, points.items);
    try ctx.writer.print("part2: {d}\n", .{max_area_in_bounds});
}

fn maxArea(points: []const Point) u64 {
    var max_area: u64 = 0;
    for (0..points.len) |index_a| {
        for (index_a + 1..points.len) |index_b| {
            const a = points[index_a];
            const b = points[index_b];
            const box = Box.init(a, b);
            max_area = @max(max_area, box.area());
        }
    }
    return max_area;
}

fn maxAreaInBounds(alloc: std.mem.Allocator, points: []const Point) !u64 {
    var edges: std.ArrayList(Box) = try .initCapacity(alloc, points.len);
    defer edges.deinit(alloc);

    for (0..points.len - 1) |i| {
        const edge = Box.init(points[i], points[i + 1]);
        edges.appendAssumeCapacity(edge);
    }
    edges.appendAssumeCapacity(Box.init(points[points.len - 1], points[0]));

    var max_area: u64 = 0;
    for (0..points.len) |idx_a| {
        loop: for (idx_a + 1..points.len) |idx_b| {
            const a = points[idx_a];
            const b = points[idx_b];
            const box = Box.init(a, b);
            const area = box.area();

            // Don't check this box if the area is less than the current max.
            if (area < max_area) continue;

            // Don't check this box if it's a line segment across the edge:
            // technically this has some area but we assume that the max area
            // does not just lie on the edge, so skip them.
            if (box.min_x == box.max_x or box.min_x == box.max_x) continue;

            // Else check if the box is within the bounds. I'm not sure if this
            // is a generic method, but for the inputs we are given it's
            // sufficient to check that the box does not collide with any of the
            // edges drawn by the polygon.
            for (edges.items) |edge| {
                if (edge.collidesWith(box)) continue :loop;
            }

            // Found larger box within the polygon -> update area.
            max_area = area;
        }
    }

    return max_area;
}

const Point = struct {
    x: u64,
    y: u64,

    fn parse(line: []const u8) !Point {
        const index = std.mem.indexOfScalar(u8, line, ',') orelse return error.InvalidInput;
        const x = try std.fmt.parseInt(u64, line[0..index], 10);
        const y = try std.fmt.parseInt(u64, line[index + 1 ..], 10);
        return .{ .x = x, .y = y };
    }
};

const Box = struct {
    min_x: u64,
    max_x: u64,
    min_y: u64,
    max_y: u64,

    fn init(a: Point, b: Point) Box {
        return .{
            .min_x = @min(a.x, b.x),
            .max_x = @max(a.x, b.x),
            .min_y = @min(a.y, b.y),
            .max_y = @max(a.y, b.y),
        };
    }

    fn area(self: Box) u64 {
        const dx = self.max_x - self.min_x + 1;
        const dy = self.max_y - self.min_y + 1;
        return dx * dy;
    }

    fn collidesWith(a: Box, b: Box) bool {
        return a.min_x < b.max_x and a.max_x > b.min_x and a.min_y < b.max_y and a.max_y > b.min_y;
    }
};

test "test input" {
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
        \\
    ;

    const want =
        \\part1: 50
        \\part2: 24
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(.{ .input = input, .writer = &writer, .alloc = std.testing.allocator });
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}
