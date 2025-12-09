const std = @import("std");

const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    const boxes = try parseBoxes(ctx.alloc, ctx.input);
    defer ctx.alloc.free(boxes);

    var distances = try calculateDistances(ctx.alloc, boxes);
    defer distances.deinit(ctx.alloc);

    const part1 = try solvePart1(ctx.alloc, distances, 1000);

    const part2 = try solvePart2(ctx.alloc, distances, boxes);
    try ctx.writer.print(
        \\part1: {d}
        \\part2: {d}
        \\
    , .{ part1, part2 });
}

fn parseBoxes(alloc: std.mem.Allocator, src: []const u8) ![]Coord {
    var boxes: std.ArrayList(Coord) = .empty;
    errdefer boxes.deinit(alloc);
    var it = std.mem.splitScalar(u8, src, '\n');
    while (it.next()) |line| {
        if (line.len == 0) break;
        const box = try Coord.parse(line);
        try boxes.append(alloc, box);
    }
    return try boxes.toOwnedSlice(alloc);
}

fn calculateDistances(alloc: std.mem.Allocator, boxes: []Coord) !std.ArrayList(JunctionPair) {
    var dists: std.ArrayList(JunctionPair) = try .initCapacity(alloc, boxes.len * boxes.len);

    for (0..boxes.len) |index_a| {
        for (index_a + 1..boxes.len) |index_b| {
            const box_a = boxes[index_a];
            const box_b = boxes[index_b];
            const dist = box_a.dist(box_b);
            try dists.append(alloc, .{ .dist = dist, .index_a = index_a, .index_b = index_b });
        }
    }

    std.mem.sort(JunctionPair, dists.items, {}, struct {
        fn f(_: void, a: JunctionPair, b: JunctionPair) bool {
            return a.dist < b.dist;
        }
    }.f);

    return dists;
}

fn solvePart1(allocator: std.mem.Allocator, distances: std.ArrayList(JunctionPair), comptime num_connections: u32) !u32 {
    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const dists = distances.items[0..num_connections];

    var circuits: std.ArrayList(Circuit) = .empty;

    for (dists) |d| {
        var connected_to: std.ArrayList(usize) = .empty;
        defer connected_to.deinit(alloc);
        for (0.., circuits.items) |idx, *circuit| {
            const contains_a = circuit.contains(d.index_a);
            const contains_b = circuit.contains(d.index_b);
            if (contains_a or contains_b) {
                try connected_to.append(alloc, idx);
            }
        }
        if (connected_to.items.len == 0) {
            var circuit: Circuit = .empty;
            try circuit.add(alloc, d.index_a);
            try circuit.add(alloc, d.index_b);
            try circuits.append(alloc, circuit);
        } else {
            var new_circuit: Circuit = .empty;
            try new_circuit.add(alloc, d.index_a);
            try new_circuit.add(alloc, d.index_b);
            for (connected_to.items) |idx| {
                try new_circuit.merge(alloc, circuits.items[idx]);
            }
            circuits.orderedRemoveMany(connected_to.items); // todo: leak
            try circuits.append(alloc, new_circuit);
        }
    }

    std.mem.sort(Circuit, circuits.items, {}, struct {
        fn f(_: void, a: Circuit, b: Circuit) bool {
            return a.size() > b.size();
        }
    }.f);

    const a: u32 = @intCast(circuits.items[0].size());
    const b: u32 = @intCast(circuits.items[1].size());
    const c: u32 = @intCast(circuits.items[2].size());
    return a * b * c;
}

fn solvePart2(allocator: std.mem.Allocator, distances: std.ArrayList(JunctionPair), boxes: []const Coord) !u64 {
    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var circuits: std.ArrayList(Circuit) = .empty;

    for (distances.items) |d| {
        var connected_to: std.ArrayList(usize) = .empty;
        defer connected_to.deinit(alloc);
        for (0.., circuits.items) |idx, *circuit| {
            const contains_a = circuit.contains(d.index_a);
            const contains_b = circuit.contains(d.index_b);
            if (contains_a or contains_b) {
                try connected_to.append(alloc, idx);
            }
        }
        if (connected_to.items.len == 0) {
            var circuit: Circuit = .empty;
            try circuit.add(alloc, d.index_a);
            try circuit.add(alloc, d.index_b);
            try circuits.append(alloc, circuit);
        } else {
            var new_circuit: Circuit = .empty;
            try new_circuit.add(alloc, d.index_a);
            try new_circuit.add(alloc, d.index_b);
            for (connected_to.items) |idx| {
                try new_circuit.merge(alloc, circuits.items[idx]);
            }
            circuits.orderedRemoveMany(connected_to.items); // todo: leak
            try circuits.append(alloc, new_circuit);
        }

        if (circuits.items.len == 1 and circuits.items[0].size() == boxes.len) {
            const a = boxes[d.index_a];
            const b = boxes[d.index_b];
            const result: u64 = @as(u64, @intCast(a.x)) * @as(u64, @intCast(b.x));
            return result;
        }
    }

    return error.InvalidInput;
}

const JunctionPair = struct {
    dist: f32,
    index_a: usize,
    index_b: usize,
};

const Circuit = struct {
    junctions: std.ArrayList(usize),

    const empty: Circuit = .{ .junctions = .empty };

    fn deinit(self: *Circuit, alloc: std.mem.Allocator) void {
        self.junctions.deinit(alloc);
    }

    fn size(self: Circuit) usize {
        return self.junctions.items.len;
    }

    fn contains(self: Circuit, item: usize) bool {
        return std.mem.indexOfScalar(usize, self.junctions.items, item) != null;
    }

    fn add(self: *Circuit, alloc: std.mem.Allocator, item: usize) !void {
        if (self.contains(item)) return;
        try self.junctions.append(alloc, item);
    }

    fn merge(self: *Circuit, alloc: std.mem.Allocator, other: Circuit) !void {
        for (other.junctions.items) |item| try self.add(alloc, item);
    }
};

const Coord = struct {
    x: u32,
    y: u32,
    z: u32,

    fn parse(src: []const u8) !Coord {
        const x_str, const rest_x = cut(src, ',') orelse return error.InvalidInput;
        const x = try std.fmt.parseInt(u32, x_str, 10);
        const y_str, const z_str = cut(rest_x, ',') orelse return error.InvalidInput;
        const y = try std.fmt.parseInt(u32, y_str, 10);
        const z = try std.fmt.parseInt(u32, z_str, 10);
        return .{ .x = x, .y = y, .z = z };
    }

    fn dist(a: Coord, b: Coord) f32 {
        const dx = @as(i64, @intCast(a.x)) - @as(i64, @intCast(b.x));
        const dy = @as(i64, @intCast(a.y)) - @as(i64, @intCast(b.y));
        const dz = @as(i64, @intCast(a.z)) - @as(i64, @intCast(b.z));
        const sx = std.math.pow(f32, @floatFromInt(dx), 2);
        const sy = std.math.pow(f32, @floatFromInt(dy), 2);
        const sz = std.math.pow(f32, @floatFromInt(dz), 2);
        return sx + sy + sz;
    }
};

fn cut(src: []const u8, at: u8) ?struct { []const u8, []const u8 } {
    const index = std.mem.indexOfScalar(u8, src, at) orelse return null;
    return .{ src[0..index], src[index + 1 ..] };
}

test "example part 1" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
        \\
    ;
    const boxes = try parseBoxes(std.testing.allocator, input);
    defer std.testing.allocator.free(boxes);
    var distances = try calculateDistances(std.testing.allocator, boxes);
    defer distances.deinit(std.testing.allocator);

    try std.testing.expectEqual(40, try solvePart1(std.testing.allocator, distances, 10));
}
