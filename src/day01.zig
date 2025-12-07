const std = @import("std");
const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    var state: State = .{};
    var it = std.mem.splitSequence(u8, ctx.input, "\n");
    while (it.next()) |line| {
        if (line.len == 0) break;
        const turn = try Turn.parse(line);
        state = state.rotate(turn);
    }

    try ctx.writer.print(
        \\part1: {d}
        \\part2: {d}
        \\
    , .{ state.end_on_zero, state.passed_zero });
}

const Turn = struct {
    direction: Direction,
    count: u16,
    const Direction = enum { l, r };

    fn parse(src: []const u8) !Turn {
        const direction: Direction = switch (src[0]) {
            'L' => .l,
            'R' => .r,
            else => return error.InvalidDirection,
        };
        const count = try std.fmt.parseInt(u16, src[1..], 10);

        return .{
            .direction = direction,
            .count = count,
        };
    }
};

const State = struct {
    dial: i32 = 50,
    end_on_zero: u32 = 0,
    passed_zero: u32 = 0,

    const TICKS = 100;

    fn rotate(self: State, turn: Turn) State {
        var dial = switch (turn.direction) {
            .l => self.dial - turn.count,
            .r => self.dial + turn.count,
        };
        var passed_zero = @abs(@divFloor(dial, TICKS));
        // Compensate for extra count if we were turning left and started on zero.
        if (turn.direction == .l and self.dial == 0) {
            passed_zero -= 1;
        }

        dial = @mod(dial, TICKS);
        // Compensate if we were turning left and ended up on a zero.
        if (turn.direction == .l and dial == 0) {
            passed_zero += 1;
        }

        const end_on_zero: u32 = if (dial == 0) 1 else 0;
        return .{
            .dial = dial,
            .end_on_zero = self.end_on_zero + end_on_zero,
            .passed_zero = self.passed_zero + passed_zero,
        };
    }
};

test "test input" {
    var buf: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    try solve(.{ .writer = &writer, .input = input, .alloc = std.testing.allocator });
    const want =
        \\part1: 3
        \\part2: 6
        \\
    ;
    try std.testing.expectEqualStrings(want, writer.buffered());
}

test "state update" {
    var state: State = .{};
    const cases = [_]struct { turn: []const u8, state: State }{
        .{ .turn = "L50", .state = .{ .dial = 0, .end_on_zero = 1, .passed_zero = 1 } },
        .{ .turn = "L1", .state = .{ .dial = 99, .end_on_zero = 1, .passed_zero = 1 } },
        .{ .turn = "R100", .state = .{ .dial = 99, .end_on_zero = 1, .passed_zero = 2 } },
        .{ .turn = "R1", .state = .{ .dial = 0, .end_on_zero = 2, .passed_zero = 3 } },
        .{ .turn = "R100", .state = .{ .dial = 0, .end_on_zero = 3, .passed_zero = 4 } },
    };
    for (cases) |case| {
        state = state.rotate(try Turn.parse(case.turn));
        try std.testing.expectEqual(case.state.dial, state.dial);
        try std.testing.expectEqual(case.state.end_on_zero, state.end_on_zero);
        try std.testing.expectEqual(case.state.passed_zero, state.passed_zero);
    }
}
