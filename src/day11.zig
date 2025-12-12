const std = @import("std");

const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    var network = try Network.parse(ctx.alloc, ctx.input);
    defer network.deinit(ctx.alloc);

    const you: Node = "you".*;
    const svr: Node = "svr".*;
    const dac: Node = "dac".*;
    const fft: Node = "fft".*;
    const out: Node = "out".*;

    const part1 = try network.countPaths(ctx.alloc, you, out);

    var memo: Memo = .init(ctx.alloc);
    defer memo.deinit();

    const svr_to_dac = try network.countPathsMemo(&memo, svr, dac);
    const dac_to_fft = try network.countPathsMemo(&memo, dac, fft);
    const fft_to_out = try network.countPathsMemo(&memo, fft, out);

    const svr_to_fft = try network.countPathsMemo(&memo, svr, fft);
    const fft_to_dac = try network.countPathsMemo(&memo, fft, dac);
    const dac_to_out = try network.countPathsMemo(&memo, dac, out);

    const part2 = svr_to_dac * dac_to_fft * fft_to_out + svr_to_fft * fft_to_dac * dac_to_out;

    try ctx.writer.print("part1: {d}\npart2: {d}\n", .{ part1, part2 });
}

const Node = [3]u8;

const Memo = std.AutoHashMap(struct { Node, Node }, u64);

const Network = struct {
    nodes: std.AutoHashMap(Node, std.ArrayList(Node)),

    fn parse(alloc: std.mem.Allocator, src: []const u8) !Network {
        var nodes: std.AutoHashMap(Node, std.ArrayList(Node)) = .init(alloc);
        errdefer nodes.deinit();

        var lines_it = std.mem.splitScalar(u8, src, '\n');
        while (lines_it.next()) |line| {
            if (line.len == 0) break;

            const src_end_idx = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidInput;
            const src_str = line[0..src_end_idx];
            const src_node = try parseServer(src_str);

            var targets: std.ArrayList(Node) = .empty;
            var target_it = std.mem.tokenizeScalar(u8, line[src_end_idx + 1 ..], ' ');
            while (target_it.next()) |target_str| {
                const target = try parseServer(target_str);
                try targets.append(alloc, target);
            }
            try nodes.put(src_node, targets);
        }

        return .{ .nodes = nodes };
    }

    fn parseServer(src: []const u8) !Node {
        if (src.len != 3) return error.InvalidInput;
        var s: Node = undefined;
        @memcpy(&s, src);
        return s;
    }

    fn deinit(self: *Network, alloc: std.mem.Allocator) void {
        var it = self.nodes.valueIterator();
        while (it.next()) |v| v.deinit(alloc);
        self.nodes.deinit();
    }

    fn countPathsMemo(self: Network, memo: *Memo, from: Node, to: Node) !u64 {
        if (memo.get(.{ from, to })) |v| return v;

        if (std.mem.eql(u8, &from, &to)) return 1;

        var routes: u64 = 0;
        const nexts = self.nodes.get(from) orelse return 0;
        for (nexts.items) |next| {
            routes += try self.countPathsMemo(memo, next, to);
        }

        try memo.put(.{ from, to }, routes);
        return routes;
    }

    fn countPaths(self: Network, alloc: std.mem.Allocator, from: Node, to: Node) !u32 {
        var queue: std.ArrayList(Node) = .empty;
        try queue.append(alloc, from);

        var routes: u32 = 0;
        while (queue.pop()) |source| {
            if (std.mem.eql(u8, &source, &to)) {
                routes += 1;
                continue;
            }

            const targets = self.nodes.get(source) orelse continue;
            for (targets.items) |target| {
                try queue.append(alloc, target);
            }
        }

        return routes;
    }
};
