const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;

pub const PackedBCD = struct {
    pub fn decimalToBCD(allocator: Allocator, dec: usize) ![]const u8 {
        var l = ArrayList(u8).init(allocator);
        defer l.deinit();
        var n = dec;
        while (n > 0) {
            var last_two_digits = @intCast(u8, n % 100);
            n /= 100;
            try l.append(twoDigitsToPackedBCD(last_two_digits));
        }
        mem.reverse(u8, l.items);
        return l.toOwnedSlice();
    }

    pub fn twoDigitsToPackedBCD(dec: u8) u8 {
        return (dec / 10) << 4 | dec % 10;
    }

    pub fn packedBCDtoTwoDigits(bcd: u8) u8 {
        return higherNibble(bcd) * 10 + lowerNibble(bcd);
    }

    pub fn higherNibble(b: u8) u8 {
        return b >> 4 & 0x0f;
    }

    pub fn lowerNibble(b: u8) u8 {
        return b & 0x0f;
    }

    pub fn toStringAlloc(allocator: Allocator, bcd: []const u8) ![]const u8 {
        var string = try allocator.alloc(u8, bcd.len * 2);
        errdefer allocator.free(string);
        var i: usize = 0;
        while (i <= string.len - 2) {
            string[i] = higherNibble(bcd[i / 2]) + '0';
            string[i + 1] = lowerNibble(bcd[i / 2]) + '0';
            i += 2;
        }
        return mem.trimLeft(u8, string, "0");
    }
};

test "basic" {
    const P = PackedBCD;
    const bcd = P.twoDigitsToPackedBCD(48);
    try testing.expect(bcd == 0b0100_1000);
    try testing.expect(48 == P.packedBCDtoTwoDigits(bcd));
}

test "allocator" {
    var t = testing.allocator;
    const res = try PackedBCD.decimalToBCD(t, 1234567890);
    defer t.free(res);
    try testing.expect(res[0] == 0b0001_0010);
    try testing.expect(res[1] == 0b0011_0100);
    try testing.expect(res[2] == 0b0101_0110);
    try testing.expect(res[3] == 0b0111_1000);
    try testing.expect(res[4] == 0b1001_0000);
    const res_string = try PackedBCD.toStringAlloc(t, res);
    defer t.free(res_string);
    try testing.expectEqualStrings("1234567890", res_string);
}
