const std = @import("std");
const bts_std = @import("binary_tree_std.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();

    var num_iterations: usize = 10_000;
    var num_elements: usize = 100_000;

    // NUM_ITERATIONS and NUM_ELEMENTS are external parameters which helps avoid the compiler
    // optimizing away our benchmarks.
    if (init.environ_map.get("NUM_ITERATIONS") orelse init.environ_map.get("num_iterations")) |val| {
        num_iterations = std.fmt.parseInt(usize, val, 10) catch |err| {
            std.debug.print("Error: Failed to parse NUM_ITERATIONS environment variable '{s}': {}\n", .{val, err});
            std.process.exit(1);
        };
    }
    if (init.environ_map.get("NUM_ELEMENTS") orelse init.environ_map.get("num_elements")) |val| {
        num_elements = std.fmt.parseInt(usize, val, 10) catch |err| {
            std.debug.print("Error: Failed to parse NUM_ELEMENTS environment variable '{s}': {}\n", .{val, err});
            std.process.exit(1);
        };
    }

    if (num_iterations == 0 or num_elements == 0) {
        std.debug.print("Zero iterations or zero elements requested. Skipping benchmark\n", .{});
        std.process.exit(1);
    }

    // Hardcode a random seed for consistent results across benchmarks
    var prng = std.Random.DefaultPrng.init(0x1287ab29);
    const random = prng.random();

    const keys = try allocator.alloc(i32, num_elements);
    for (keys) |*key| {
        key.* = random.int(i32);
    }

    // Build the tree to benchmark search on
    const IntTreeStd = bts_std.BinaryTreeStd(i32);
    var tree_std: IntTreeStd.Tree = null;
    for (keys) |key| {
        tree_std = try IntTreeStd.insert(allocator, key, tree_std);
    }

    // Generate search queries (50% present, 50% random)
    const search_keys = try allocator.alloc(i32, num_iterations);
    for (search_keys) |*key| {
        if (random.boolean()) {
            key.* = keys[random.intRangeLessThan(usize, 0, num_elements)];
        } else {
            key.* = random.int(i32);
        }
    }

    // --- Benchmark: Standard Search (member) ---
    // Warm-up
    var warm_up_hash_std: u32 = 0;
    for (search_keys[0..@min(100, search_keys.len)]) |key| {
        const found = IntTreeStd.member(key, tree_std);
        warm_up_hash_std = warm_up_hash_std *% 33 +% (if (found) @as(u32, @bitCast(key)) else 0);
    }
    const start_std = std.Io.Clock.awake.now(io);
    var hash_std: u32 = 0;
    for (search_keys) |key| {
        const found = IntTreeStd.member(key, tree_std);
        hash_std = hash_std *% 33 +% (if (found) @as(u32, @bitCast(key)) else 0);
    }
    const elapsed_std = start_std.untilNow(io, .awake);
    const elapsed_ns_std = elapsed_std.toNanoseconds();
    const avg_ns_std = @divTrunc(elapsed_ns_std, @as(i96, num_iterations));

    // --- Benchmark: Two-Way Search (member2) ---
    // Warm-up
    var warm_up_hash_two: u32 = 0;
    for (search_keys[0..@min(100, search_keys.len)]) |key| {
        const found = IntTreeStd.member2(key, tree_std, null);
        warm_up_hash_two = warm_up_hash_two *% 33 +% (if (found) @as(u32, @bitCast(key)) else 0);
    }
    const start_two = std.Io.Clock.awake.now(io);
    var hash_two: u32 = 0;
    for (search_keys) |key| {
        const found = IntTreeStd.member2(key, tree_std, null);
        hash_two = hash_two *% 33 +% (if (found) @as(u32, @bitCast(key)) else 0);
    }
    const elapsed_two = start_two.untilNow(io, .awake);
    const elapsed_ns_two = elapsed_two.toNanoseconds();
    const avg_ns_two = @divTrunc(elapsed_ns_two, @as(i96, num_iterations));

    // --- Benchmark: Three-Way Search (member3) ---
    // Warm-up
    var warm_up_hash_three: u32 = 0;
    for (search_keys[0..@min(100, search_keys.len)]) |key| {
        const found = IntTreeStd.member3(key, tree_std);
        warm_up_hash_three = warm_up_hash_three *% 33 +% (if (found) @as(u32, @bitCast(key)) else 0);
    }
    const start_three = std.Io.Clock.awake.now(io);
    var hash_three: u32 = 0;
    for (search_keys) |key| {
        const found = IntTreeStd.member3(key, tree_std);
        hash_three = hash_three *% 33 +% (if (found) @as(u32, @bitCast(key)) else 0);
    }
    const elapsed_three = start_three.untilNow(io, .awake);
    const elapsed_ns_three = elapsed_three.toNanoseconds();
    const avg_ns_three = @divTrunc(elapsed_ns_three, @as(i96, num_iterations));

    // Output results
    std.debug.print("Benchmark Results:\n", .{});
    std.debug.print("  Tree Size: {d}\n", .{num_elements});
    std.debug.print("  Iterations: {d}\n\n", .{num_iterations});
    std.debug.print("  Standard Search: {d: >4} ns/op (Hash: 0x{x})\n", .{avg_ns_std, hash_std +% warm_up_hash_std});
    std.debug.print("  Two-Way Search:  {d: >4} ns/op (Hash: 0x{x})\n", .{avg_ns_two, hash_two +% warm_up_hash_two});
    std.debug.print("  Three-Way Search: {d: >4} ns/op (Hash: 0x{x})\n", .{avg_ns_three, hash_three +% warm_up_hash_three});
}
