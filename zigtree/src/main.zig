const std = @import("std");
const bts = @import("binary_tree_set.zig");

// The function we want to benchmark
fn fibonacci(n: u32) u32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();

    var iterations: usize = 10_000;
    const args = try init.minimal.args.toSlice(allocator);
    if (args.len > 1) {
        if (std.fmt.parseInt(usize, args[1], 10)) |val| {
            iterations = val;
        } else |_| {}
    }
    if (iterations == 0) iterations = 1;

    var n: u32 = 20;
    std.mem.doNotOptimizeAway(&n);

    // 1. Warm-up phase: load instructions into CPU cache
    for (0..100) |_| {
        std.mem.doNotOptimizeAway(fibonacci(n));
    }

    // 2. Timed phase
    const start = std.Io.Clock.awake.now(io);
    for (0..iterations) |_| {
        // doNotOptimizeAway prevents LLVM from deleting the loop
        std.mem.doNotOptimizeAway(fibonacci(n));
    }

    const elapsed = start.untilNow(io, .awake);
    const elapsed_ns = elapsed.toNanoseconds();
    const avg_ns = @divTrunc(elapsed_ns, @as(i96, iterations));

    std.debug.print("Fibonacci({d}): {d} ns/op\n", .{n, avg_ns});
}

// pub fn main() !void {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//
//     const IntTreeSet = bts.BinaryTreeSet(i32);
//     var tree: IntTreeSet.Tree = null;
//
//     const nums = [_]i32{ 5, 3, 8, 1, 4, 6, 9 };
//     for (nums) |num| {
//         tree = try IntTreeSet.insert(allocator, num, tree);
//     }
//
//     std.debug.print("Searching for 4 (exists): {}\n", .{IntTreeSet.member(4, tree)});
//     std.debug.print("Searching for 7 (missing): {}\n", .{IntTreeSet.member(7, tree)});
//
//     std.debug.print("Searching for 4 (exists): {}\n", .{IntTreeSet.member2(4, tree, null)});
//     std.debug.print("Searching for 7 (missing): {}\n", .{IntTreeSet.member2(7, tree, null)});
//
//     std.debug.print("Searching for 4 (exists): {}\n", .{IntTreeSet.member3(4, tree)});
//     std.debug.print("Searching for 7 (missing): {}\n", .{IntTreeSet.member3(7, tree)});
// }
