const std = @import("std");
const Context = @import("./root.zig").Context;

pub fn solve(ctx: Context) !void {
    const part1 = try solvePart1(ctx.alloc, ctx.input);
    const part2 = try solvePart2(ctx.alloc, ctx.input);

    try ctx.writer.print(
        \\part1: {d}
        \\part2: {d}
        \\
    ,
        .{ part1, part2 },
    );
}

fn solvePart1(alloc: std.mem.Allocator, src: []const u8) !u64 {
    // Separate input into the number rows and the operation row.
    var row_it = std.mem.splitScalar(u8, src, '\n');
    var number_rows: std.ArrayList(std.mem.TokenIterator(u8, .scalar)) = .empty;
    defer number_rows.deinit(alloc);
    var operation_row: std.mem.TokenIterator(u8, .scalar) = undefined;
    while (row_it.next()) |row| {
        if (row.len == 0) break;
        switch (row[0]) {
            '*', '+' => operation_row = std.mem.tokenizeScalar(u8, row, ' '),
            else => try number_rows.append(alloc, std.mem.tokenizeScalar(u8, row, ' ')),
        }
    }

    var total: u64 = 0;
    while (operation_row.next()) |operation_str| {
        std.debug.assert(operation_str.len == 1);
        const op = try Operation.parse(operation_str[0]);
        var col_total = op.empty();
        for (number_rows.items) |*row| {
            const num_str = row.next() orelse return error.InvalidInput;
            const num = try std.fmt.parseInt(u64, num_str, 10);
            col_total = op.append(col_total, num);
        }
        total += col_total;
    }
    return total;
}

fn solvePart2(alloc: std.mem.Allocator, src: []const u8) !u64 {
    // Separate input into the number rows and the operation row.
    var row_it = std.mem.splitScalar(u8, src, '\n');
    var number_rows: std.ArrayList([]const u8) = .empty;
    defer number_rows.deinit(alloc);
    var operation_row: []const u8 = undefined;
    while (row_it.next()) |row| {
        if (row.len == 0) break;
        switch (row[0]) {
            '*', '+' => operation_row = row,
            else => try number_rows.append(alloc, row),
        }
    }

    // Running total of all the columns we calculate.
    var total: u64 = 0;
    // Buffer for storing the number we parse in the current column. Done in an
    // ArrayList since we don't know how many number rows there are statically.
    var num_str: std.ArrayList(u8) = try .initCapacity(alloc, number_rows.items.len);
    defer num_str.deinit(alloc);

    var operation_it = std.mem.tokenizeScalar(u8, operation_row, ' ');
    while (operation_it.next()) |operation_str| {
        std.debug.assert(operation_str.len == 1);
        const operation = try Operation.parse(operation_str[0]);
        var col_total = operation.empty();

        // Iterate and parse each number inside each column until we run out.
        while (true) {
            try num_str.resize(alloc, 0); // reset previous number we parsed.
            // Iterate over the rows, appending any digits we see.
            for (0.., number_rows.items) |index, row| {
                if (row.len == 0) break;
                if (row[0] != ' ') {
                    try num_str.append(alloc, row[0]);
                }
                // Consume the current byte, i.e. forward to the next digit for
                // the next iteration.
                number_rows.items[index] = row[1..];
            }
            if (num_str.items.len == 0) {
                break;
            }
            const num = try std.fmt.parseInt(u64, num_str.items, 10);
            col_total = operation.append(col_total, num);
        }
        total += col_total;
    }

    return total;
}

const Operation = enum {
    add,
    mul,

    fn parse(char: u8) !Operation {
        return switch (char) {
            '+' => .add,
            '*' => .mul,
            else => error.InvalidToken,
        };
    }

    fn empty(self: Operation) u64 {
        return switch (self) {
            .add => 0,
            .mul => 1,
        };
    }

    fn append(self: Operation, a: u64, b: u64) u64 {
        return switch (self) {
            .add => a + b,
            .mul => a * b,
        };
    }
};

test "test input" {
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
        \\
    ;
    const want =
        \\part1: 4277556
        \\part2: 3263827
        \\
    ;

    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try solve(.{ .input = input, .writer = &writer, .alloc = std.testing.allocator });
    const got = writer.buffered();
    try std.testing.expectEqualStrings(want, got);
}
