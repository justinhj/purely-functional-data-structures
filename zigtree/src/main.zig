const std = @import("std");
const bts_std = @import("binary_tree_std.zig");
const bench = @import("bench.zig");

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

    const keys = try allocator.alloc(f32, num_elements);
    for (keys) |*key| {
        key.* = random.float(f32);
    }

    // Build the tree to benchmark search on
    const IntTreeStd = bts_std.BinaryTreeStd(f32);
    var tree_std: IntTreeStd.Tree = null;
    for (keys) |key| {
        tree_std = try IntTreeStd.insert(allocator, key, tree_std);
    }

    // Generate search queries (50% present, 50% random)
    const search_keys = try allocator.alloc(f32, num_iterations);
    for (search_keys) |*key| {
        if (random.boolean()) {
            key.* = keys[random.intRangeLessThan(usize, 0, num_elements)];
        } else {
            key.* = random.float(f32);
        }
    }

    // Run the benchmarks
    var std_stats = bench.runBenchmark(f32, io, search_keys, struct {
        tree: IntTreeStd.Tree,
        pub fn run(self: @This(), key: f32) u32 {
            const found = IntTreeStd.member(key, self.tree);
            return if (found) @as(u32, @bitCast(key)) else 0;
        }
    }{ .tree = tree_std });

    var two_stats = bench.runBenchmark(f32, io, search_keys, struct {
        tree: IntTreeStd.Tree,
        pub fn run(self: @This(), key: f32) u32 {
            const found = IntTreeStd.member2(key, self.tree, null);
            return if (found) @as(u32, @bitCast(key)) else 0;
        }
    }{ .tree = tree_std });

    var three_stats = bench.runBenchmark(f32, io, search_keys, struct {
        tree: IntTreeStd.Tree,
        pub fn run(self: @This(), key: f32) u32 {
            const found = IntTreeStd.member3(key, self.tree);
            return if (found) @as(u32, @bitCast(key)) else 0;
        }
    }{ .tree = tree_std });

    // Output results
    std.debug.print("Benchmark Results:\n", .{});
    std.debug.print("  Tree Size: {d}\n", .{num_elements});
    std.debug.print("  Iterations: {d}\n\n", .{num_iterations});

    std.debug.print("  Standard Search:  {d:.2} mean {d:.2} stddev ns/op (Hash: 0x{x})\n", .{std_stats.mean, std_stats.standard_deviation(), std_stats.hash});
    std.debug.print("  Two-Way Search:   {d:.2} mean {d:.2} stddev ns/op (Hash: 0x{x})\n", .{two_stats.mean, two_stats.standard_deviation(), two_stats.hash});
    std.debug.print("  Three-Way Search: {d:.2} mean {d:.2} stddev ns/op (Hash: 0x{x})\n", .{three_stats.mean, three_stats.standard_deviation(), three_stats.hash});
}
