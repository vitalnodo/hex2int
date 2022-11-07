const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const Allocator = mem.Allocator;
const shl = std.math.shl;
const divCeil = std.math.divCeil;
const d = @import("double_dabble.zig");
const double_dabble = d.double_dabble;
const reversed_double_dabble = d.reversed_double_dabble;
const PackedBCD = @import("BCD.zig").PackedBCD;
const toStringAlloc = PackedBCD.toStringAlloc;
const lowerNibble = PackedBCD.lowerNibble;
const higherNibble = PackedBCD.higherNibble;

pub const Hex2Int = struct {
    pub fn hexToBigEndian(allocator: Allocator, b: []const u8) ![]const u8 {
        var bytes = try allocator.alloc(u8, b.len / 2);
        defer allocator.free(bytes);
        var i: usize = 0;
        while (i < bytes.len) {
            var byte: u8 = 0;
            byte |= shl(u8, try parseHexDigit(b[i * 2]), 4);
            byte |= try parseHexDigit(b[i * 2 + 1]);
            bytes[i] = byte;
            i += 1;
        }
        var bcd = try double_dabble(allocator, bytes);
        defer allocator.free(bcd);
        var string = try toStringAlloc(allocator, bcd);
        errdefer allocator.free(string);
        return string;
    }

    pub fn hexToLittleEndian(allocator: Allocator, b: []const u8) ![]const u8 {
        var bytes = try allocator.alloc(u8, b.len / 2);
        defer allocator.free(bytes);
        var i: usize = 0;
        while (i < bytes.len) {
            var byte: u8 = 0;
            byte |= shl(u8, try parseHexDigit(b[i * 2]), 4);
            byte |= try parseHexDigit(b[i * 2 + 1]);
            bytes[i] = byte;
            i += 1;
        }
        mem.reverse(u8, bytes);
        var bcd = try double_dabble(allocator, bytes);
        defer allocator.free(bcd);
        var string = try toStringAlloc(allocator, bcd);
        errdefer allocator.free(string);
        return string;
    }

    pub fn bigEndianToHex(allocator: Allocator, b: []const u8) ![]const u8 {
        const how_many =  b.len/2 + (b.len % 2);
        var bytes = try allocator.alloc(u8, how_many);
        defer allocator.free(bytes);
        mem.set(u8, bytes, 0);
        if (b.len % 2 == 1) {
            bytes[0] = b[0] - '0';
            var i: usize = 1;
            while (i < bytes.len) {
                bytes[i] = b[i*2-1] - '0' << 4 | b[i*2] - '0';
                i+=1;
            }
        } else {
            var i: usize = 0;
            while (i < bytes.len) {
                bytes[i] = b[i*2] - '0' << 4 | b[i*2+1] - '0';
                i += 1;
            }
        }
        var res = try reversed_double_dabble(allocator, bytes);
        defer allocator.free(res);
        var str = try allocator.alloc(u8, res.len*2);
        errdefer allocator.free(str);
        for (res) |v, i| {
            str[2*i] = toHex(higherNibble(v));
            str[2*i+1] = toHex(lowerNibble(v));
        }
        return mem.trimLeft(u8, str, "0");
    }

    pub fn littleEndianToHex(allocator: Allocator, b: []const u8) ![]const u8 {
        const how_many =  b.len/2 + (b.len % 2);
        var bytes = try allocator.alloc(u8, how_many);
        defer allocator.free(bytes);
        mem.set(u8, bytes, 0);
        if (b.len % 2 == 1) {
            bytes[0] = b[0] - '0';
            var i: usize = 1;
            while (i < bytes.len) {
                bytes[i] = b[i*2-1] - '0' << 4 | b[i*2] - '0';
                i+=1;
            }
        } else {
            var i: usize = 0;
            while (i < bytes.len) {
                bytes[i] = b[i*2] - '0' << 4 | b[i*2+1] - '0';
                i += 1;
            }
        }
        var res = try reversed_double_dabble(allocator, bytes);
        defer allocator.free(res);
        mem.reverse(u8, res);
        var str = try allocator.alloc(u8, res.len*2);
        errdefer allocator.free(str);
        for (res) |v, i| {
            str[2*i] = toHex(higherNibble(v));
            str[2*i+1] = toHex(lowerNibble(v));
        }
        return str;
    }

    pub fn parseHexDigit(c: u8) !u8 {
        return switch (c) {
            '0'...'9' => return c - '0',
            'a'...'f' => return c - 'a' + 10,
            'A'...'F' => return c - 'A' + 10,
            else => error.InvalidCharacter,
        };
    }
    
    pub fn toHex(c: u8) u8 {
        const hex_digits = "0123456789ABCDEF";
        return hex_digits[c];
    }
};

test {
    const TestVector = struct { hexadecimal: []const u8, little_endian: []const u8, big_endian: []const u8 };
    const test_vectors = [_]TestVector{
        TestVector{
            .hexadecimal = "FF00000000000000000000000000000000000000000000000000000000000000",
            .big_endian = "115339776388732929035197660848497720713218148788040405586178452820382218977280",
            .little_endian = "255",
        },
        TestVector{
            .hexadecimal = "AAAA000000000000000000000000000000000000000000000000000000000000",
            .big_endian = "77193548260167611359494267807458109956502771454495792280332974934474558013440",
            .little_endian = "43690",
        },
        TestVector{
            .hexadecimal = "FFFFFFFF",
            .big_endian = "4294967295",
            .little_endian = "4294967295",
        },
        TestVector{
            .hexadecimal = "F000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            .big_endian = "979114576324830475023518166296835358668716483481922294110218890578706788723335115795775136189060210944584475044786808910613350098299181506809283832360654948074334665509728123444088990750984735919776315636114949587227798911935355699067813766573049953903257414411690972566828795693861196044813729172123152193769005290826676049325224028303369631812105737593272002471587527915367835952474124875982077070337970837392460768423348044782340688207323630599527945406427226264695390995320400314062984891593411332752703846859640346323687201762934524222363836094053204269986087043470117703336873406636573235808683444836432453459818599293667760149123595668832133083221407128310342064668595954073131257995767262426534143159642539179485013975461689493733866106312135829807129162654188209922755829012304582671671519678313609748646814745057724363462189490278183457296449014163077506949636570237334109910914728582640301294341605533983878368789071427913184794906223657920124153256147359625549743656058746335124502376663710766611046750739680547042183503568549468592703882095207981161012224965829605768300297615939788368703353944514111011011184191740295491255291545096680705534063721012625490368756140460791685877738232879406346334603566914069127957053440",
            .little_endian = "240",
        },
    };

    // BUG: why are there problems with testing.allocator?
    var b: [16384]u8 = undefined;
    var fixed = std.heap.FixedBufferAllocator.init(&b);
    var t = fixed.allocator();
    for (test_vectors) |vector| {
        const res_big = try Hex2Int.hexToBigEndian(t, vector.hexadecimal);
        defer t.free(res_big);
        try testing.expectEqualStrings(vector.big_endian, res_big);
        const res_little = try Hex2Int.hexToLittleEndian(t, vector.hexadecimal);
        defer t.free(res_little);
        try testing.expectEqualStrings(vector.little_endian, res_little);
        const res_hex_from_big = try Hex2Int.bigEndianToHex(t, vector.big_endian);
        defer t.free(res_hex_from_big);
        try testing.expectEqualStrings(vector.hexadecimal, res_hex_from_big);
        const res_hex_from_little = try Hex2Int.bigEndianToHex(t, vector.little_endian);
        defer t.free(res_hex_from_little);
        try testing.expectStringStartsWith(vector.hexadecimal, res_hex_from_little);
    }
}
