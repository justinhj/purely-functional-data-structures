const std = @import("std");
const bts_std = @import("binary_tree_std.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();

    var num_iterations: usize = 10_000;
    var num_elements: usize = 100_000;

    // Gather the parameters from the environment
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

    // Hardcode a random seed for consistent results
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

    // --- Benchmark: Mutable (BinaryTreeStd) ---
    // Warm-up
    for (search_keys[0..@min(100, search_keys.len)]) |key| {
        std.mem.doNotOptimizeAway(IntTreeStd.member(key, tree_std));
    }
    const start_std = std.Io.Clock.awake.now(io);
    for (search_keys) |key| {
        std.mem.doNotOptimizeAway(IntTreeStd.member(key, tree_std));
    }
    const elapsed_std = start_std.untilNow(io, .awake);
    const elapsed_ns_std = elapsed_std.toNanoseconds();
    const avg_ns_std = @divTrunc(elapsed_ns_std, @as(i96, num_iterations));

    // 7. Output results
    std.debug.print("Benchmark Results:\n", .{});
    std.debug.print("  Tree Size: {d}\n", .{num_elements});
    std.debug.print("  Iterations: {d}\n", .{num_iterations});
    std.debug.print("  Mutable (BinaryTreeStd) Search:           {d} ns/op\n", .{avg_ns_std});
}
