const std = @import("std");

const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    var part1: u32 = 0;
    var lines_it = std.mem.splitScalar(u8, ctx.input, '\n');
    while (lines_it.next()) |line| {
        if (line.len == 0) break;
        var machine = try Machine.parse(ctx.alloc, line);
        defer machine.deinit(ctx.alloc);
        const p = try machine.minButtonPresses(ctx.alloc);
        part1 += p;
    }
    try ctx.writer.print("part1: {d}\n", .{part1});
}

const Machine = struct {
    start_lights: u32,
    buttons: std.ArrayList(u32),

    fn parse(alloc: std.mem.Allocator, src: []const u8) !Machine {
        var s = src;

        if (s[0] != '[') return error.InvalidInput;
        s = s[1..];

        var start_lights: u32 = 0;
        var idx: u5 = 0;
        while (s[0] != ']') {
            const v: u32 = if (s[0] == '#') 1 else 0;
            start_lights |= v << idx;
            idx += 1;
            s = s[1..];
        }
        s = s[1..];

        if (s[0] != ' ') return error.InvalidInput;
        s = s[1..];

        var buttons: std.ArrayList(u32) = .empty;
        errdefer buttons.deinit(alloc);

        while (s[0] == '(') {
            s = s[1..];
            var button: u32 = 0;
            while (s[0] != ' ') {
                const num_end = std.mem.indexOfAny(u8, s, ",)") orelse return error.InvalidInput;
                const num_str = s[0..num_end];
                const num = try std.fmt.parseInt(u5, num_str, 10);
                button |= @as(u32, 1) << num;
                s = s[num_end + 1 ..];
            }
            try buttons.append(alloc, button);
            if (s[0] != ' ') return error.InvalidInput;
            s = s[1..];
        }

        return .{
            .start_lights = start_lights,
            .buttons = buttons,
        };
    }

    fn deinit(self: *Machine, alloc: std.mem.Allocator) void {
        self.buttons.deinit(alloc);
    }

    fn minButtonPresses(self: Machine, alloc: std.mem.Allocator) !u32 {
        const State = struct { lights: u32, presses: u32 };

        var queue: std.ArrayList(State) = .empty;
        defer queue.deinit(alloc);
        var min_cost: std.AutoHashMap(u32, u32) = .init(alloc);
        defer min_cost.deinit();

        try queue.append(alloc, .{ .lights = 0, .presses = 0 });
        while (queue.pop()) |s| {
            if (s.lights == self.start_lights) {
                return s.presses;
            }

            for (self.buttons.items) |button| {
                const new_presses = s.presses + 1;
                const new_lights = s.lights ^ button;

                const gop = try min_cost.getOrPut(new_lights);
                if (!gop.found_existing or new_presses < gop.value_ptr.*) {
                    gop.value_ptr.* = new_presses;
                    try queue.insert(alloc, 0, .{
                        .lights = new_lights,
                        .presses = new_presses,
                    });
                }
            }
        }

        return error.InvalidInput;
    }
};

test "test input" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
        \\
    ;
    const want =
        \\part1: 7
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(.{ .input = input, .writer = &writer, .alloc = std.testing.allocator });
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}
