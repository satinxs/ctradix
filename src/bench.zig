const std = @import("std");
const testing = std.testing;
const Timer = std.time.Timer;
const log = std.log.scoped(.bench);

const words = @embedFile("testdata/words.txt");
const gpa = testing.allocator;

pub fn main() !void {
    comptime var radix = @import("main.zig").RadixTree(u32){};
    comptime {
        @setEvalBranchQuota(10_000);
        comptime var index: usize = 0;
        comptime var count: u32 = 0;

        for (words) |c, i| {
            if (c == '\n') {
                _ = radix.insert(words[index..i], count);
                count += 1;
                index = i + 1;
            }
        }
        _ = radix.insert(words[index..], count);
    }

    //_ = radix.get("aardvark").?;

    var map = std.StringHashMap(u32).init(gpa);
    var array_map = std.StringArrayHashMap(u32).init(gpa);
    var map_results: [3]u64 = undefined;
    var array_map_results: [3]u64 = undefined;
    var radix_results: [3]u64 = undefined;

    defer map.deinit();

    var it = std.mem.split(words, "\n");
    var i: u32 = 0;
    while (it.next()) |val| : (i += 1) {
        try map.putNoClobber(val, i);
        try array_map.putNoClobber(val, i);
    }

    log.warn("Start benching {} words\t[0]\t\t[1]\t\t[2]", .{i});
    std.debug.assert(radix.size == i);

    for (map_results) |*r| {
        it.index = 0;

        var timer = try Timer.start();
        while (it.next()) |val| {
            _ = map.get(val).?;
        }
        r.* = timer.read();
    }

    log.warn("StringHashMap\t\t\t{:0>6}ns\t{:0>6}ns\t{:0>6}ns", .{
        map_results[0],
        map_results[1],
        map_results[2],
    });

    for (array_map_results) |*r| {
        it.index = 0;

        var timer = try Timer.start();
        while (it.next()) |val| {
            _ = array_map.get(val).?;
        }
        r.* = timer.read();
    }

    log.warn("StringArrayHashMap\t\t{:0>6}ns\t{:0>6}ns\t{:0>6}ns", .{
        array_map_results[0],
        array_map_results[1],
        array_map_results[2],
    });

    for (radix_results) |*r| {
        it.index = 0;

        var timer = try Timer.start();
        while (it.next()) |val| {
            _ = radix.get(val).?;
        }
        r.* = timer.read();
    }

    log.warn("RadixTree\t\t\t{:0>6}ns\t{:0>6}ns\t{:0>6}ns", .{
        radix_results[0],
        radix_results[1],
        radix_results[2],
    });
}