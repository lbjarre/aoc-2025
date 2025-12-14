const std = @import("std");

const Context = @import("./root.zig").Context;

// Number of presents in the input source. Statically asserted here because it was simpler.
const NUM_PRESENTS = 6;

pub fn solve(ctx: Context) !void {
    var reader: std.Io.Reader = .fixed(ctx.input);

    var present_sizes: [NUM_PRESENTS]u16 = undefined;
    inline for (0..NUM_PRESENTS) |idx| {
        present_sizes[idx] = try parsePresentSize(&reader);
    }

    var count: u16 = 0;
    while (reader.peek(1) != error.EndOfStream) {
        const region = Region.parse(&reader) catch break;
        const fits = region.presentsFit(present_sizes);
        if (fits) count += 1;
    }

    try ctx.writer.print("part1: {}\n", .{count});
}

fn parsePresentSize(r: *std.Io.Reader) !u16 {
    const input_size = 3 + 3 * 4 + 1; // First line "0:\n", three lines of ".#.\n", one final newline.

    var buf = try r.peek(input_size);

    const index = std.mem.indexOf(u8, buf, ":\n") orelse return error.InvalidInput;
    _ = try std.fmt.parseInt(u8, buf[0..index], 10);
    buf = buf[index + 2 ..];

    var size: u16 = 0;
    inline for (0..3) |_| {
        if (buf[3] != '\n') return error.InvalidInput;
        size += @intCast(std.mem.count(u8, buf[0..3], "#"));
        buf = buf[4..];
    }
    if (buf[0] != '\n') return error.InvalidInput;

    r.toss(input_size);
    return size;
}

const Region = struct {
    /// The size of the region in number of squares.
    size: u16,
    /// How many of each kind of present that should fit in the region.
    present_counts: [NUM_PRESENTS]u16,

    fn parse(r: *std.Io.Reader) !Region {
        const buf = try r.peekDelimiterExclusive('\n');
        var buf_r: std.Io.Reader = .fixed(buf);

        const size_x_str = try buf_r.takeDelimiterExclusive('x');
        const size_x = try std.fmt.parseUnsigned(u16, size_x_str, 10);
        buf_r.toss(1);

        const size_y_str = try buf_r.takeDelimiterExclusive(':');
        const size_y = try std.fmt.parseUnsigned(u16, size_y_str, 10);
        buf_r.toss(1);

        const size = size_x * size_y;

        if (try buf_r.takeByte() != ' ') return error.InvalidInput;

        var present_counts: [NUM_PRESENTS]u16 = undefined;
        inline for (0..NUM_PRESENTS) |idx| {
            const str = try buf_r.takeDelimiterExclusive(' ');
            const count = try std.fmt.parseUnsigned(u16, str, 10);
            present_counts[idx] = count;
            if (idx != NUM_PRESENTS - 1) buf_r.toss(1);
        }

        r.toss(buf.len + 1); // line plus newline.
        return .{
            .size = size,
            .present_counts = present_counts,
        };
    }

    fn presentsFit(self: Region, present_sizes: @Vector(NUM_PRESENTS, u16)) bool {
        const size = @reduce(.Add, self.present_counts * present_sizes);
        return self.size >= size;
    }
};
