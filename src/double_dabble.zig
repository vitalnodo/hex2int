const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const Allocator = mem.Allocator;
const higherNibble = @import("BCD.zig").PackedBCD.higherNibble;
const lowerNibble = @import("BCD.zig").PackedBCD.lowerNibble;
const toStringAlloc = @import("BCD.zig").PackedBCD.toStringAlloc;

pub fn double_dabble(allocator: Allocator, b: []const u8) ![]u8 {
    const how_many = 3 * b.len;
    var res = try allocator.alloc(u8, how_many);
    errdefer allocator.free(res);
    mem.set(u8, res, 0);
    mem.copy(u8, res[res.len - b.len ..], b);
    var j: usize = 0;
    while (j < b.len * 8) {
        for (res[0 .. res.len - b.len]) |v, i| {
            if (higherNibble(v) > 4) {
                res[i] = ((higherNibble(v) + 3) << 4) | lowerNibble(v);
            }
            if (lowerNibble(v) > 4) {
                res[i] += 3;
            }
        }
        res = shift_1bit_left(res);
        j += 1;
    }
    return res[0 .. res.len - b.len];
}

pub fn reversed_double_dabble(allocator: Allocator, b: []const u8) ![]u8 {
    const how_many = 2 * b.len;
    var res = try allocator.alloc(u8, how_many);
    errdefer allocator.free(res);
    mem.set(u8, res, 0);
    mem.copy(u8, res[0..], b);
    var j: usize = 0;
    while (j < b.len * 8) {
        res = shift_1bit_right(res);
        for (res[b.len..]) |_, i| {
            if (lowerNibble(res[i]) > 7) {
                res[i] -= 3;
            }
            if (higherNibble(res[i]) > 7) {
                res[i] = (higherNibble(res[i]) - 3) << 4 | lowerNibble(res[i]);
            }
        }
        j += 1;
    }
    return res;
}

fn shift_1bit_left(b: []u8) []u8 {
    for (b) |_, i| {
        b[i] <<= 1;
        if (i < b.len - 1) {
            b[i] |= (b[i + 1] >> 7) & 1;
        }
    }
    return b;
}

fn shift_1bit_right(b: []u8) []u8 {
    var pre: u8 = 0;
    var post: u8 = 0;
    for (b) |_, i| {
        post = b[i] << 7;
        b[i] >>= 1;
        b[i] |= pre;
        pre = post;
    }
    return b;
}

test "double dabble" {
    var t = testing.allocator;
    var n243 = [_]u8{0b1111_0011};
    var n65244 = [_]u8{ 0b1111_1110, 0b1101_1100 };
    var r1 = try double_dabble(t, &n243);
    var r2 = try double_dabble(t, &n65244);
    defer t.free(r1);
    defer t.free(r2);
    var s1 = try toStringAlloc(t, r1);
    var s2 = try toStringAlloc(t, r2);
    defer t.free(s1);
    defer t.free(s2);
    try testing.expectEqualStrings("243", s1);
    try testing.expectEqualStrings("65244", s2);
}

test "reversed double dabble" {
    const t = testing.allocator;
    const n89 = [_]u8{0b1000_1001};
    const res89 = try reversed_double_dabble(t, &n89);
    defer t.free(res89);
    try testing.expectEqualSlices(u8, &[_]u8{ 0, 0b0101_1001 }, res89);

    const n243 = [_]u8{ 0b0000_0010, 0b0100_0011 };
    const res243 = try reversed_double_dabble(t, &n243);
    defer t.free(res243);
    try testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 0, 0b1111_0011 }, res243);

    const n65537 = [_]u8{ 0b0000_0110, 0b0101_0101, 0b0011_0111 };
    const res65537 = try reversed_double_dabble(t, &n65537);
    defer t.free(res65537);
    try testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 0, 0b0000_0001, 0, 0b0000_0001 }, res65537);
}
