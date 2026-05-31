const std = @import("std");
const bts_std = @import("binary_tree_std.zig");
const bts_sentinel = @import("binary_tree_sentinel.zig");
const bench = @import("bench.zig");

fn parseEnvVar(
    environ_map: anytype,
    upper_name: []const u8,
    lower_name: []const u8,
    default_value: usize,
) usize {
    if (environ_map.get(upper_name) orelse environ_map.get(lower_name)) |val| {
        return std.fmt.parseInt(usize, val, 10) catch |err| {
            std.debug.print("Error: Failed to parse {s} environment variable '{s}': {}\n", .{upper_name, val, err});
            std.process.exit(1);
        };
    }
    return default_value;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();

    const num_iterations = parseEnvVar(init.environ_map, "NUM_ITERATIONS", "num_iterations", 10_000);
    const num_elements = parseEnvVar(init.environ_map, "NUM_ELEMENTS", "num_elements", 100_000);
    const successful_search = parseEnvVar(init.environ_map, "SUCCESSFUL_SEARCH", "successful_search", 50);

    if (num_iterations == 0 or num_elements == 0) {
        std.debug.print("Zero iterations or zero elements requested. Skipping benchmark\n", .{});
        std.process.exit(1);
    }

    if (successful_search > 100) {
        std.debug.print("Error: SUCCESSFUL_SEARCH must be between 0 and 100 percent\n", .{});
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

    const IntTreeSentinel = bts_sentinel.BinaryTreeSentinel(f32);
    var tree_sentinel = try IntTreeSentinel.init(allocator);
    for (keys) |key| {
        try tree_sentinel.insert(allocator, key);
    }

    // Generate search queries based on successful_search percentage
    const search_keys = try allocator.alloc(f32, num_iterations);
    for (search_keys) |*key| {
        if (random.intRangeLessThan(usize, 0, 100) < successful_search) {
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

    var sentinel_stats = bench.runBenchmark(f32, io, search_keys, struct {
        tree: *IntTreeSentinel,
        pub fn run(self: @This(), key: f32) u32 {
            const found = self.tree.member(key);
            return if (found) @as(u32, @bitCast(key)) else 0;
        }
    }{ .tree = &tree_sentinel });

    var two_stats = bench.runBenchmark(f32, io, search_keys, struct {
        tree: IntTreeStd.Tree,
        pub fn run(self: @This(), key: f32) u32 {
            const found = IntTreeStd.member2(key, self.tree, null);
            return if (found) @as(u32, @bitCast(key)) else 0;
        }
    }{ .tree = tree_std });

    // Output results
    std.debug.print("Benchmark Results:\n", .{});
    std.debug.print("  Tree Size: {d}\n", .{num_elements});
    std.debug.print("  Iterations: {d}\n\n", .{num_iterations});

    std.debug.print("  Standard Search:  {d:.2} mean {d:.2} stddev ns/op (Hash: 0x{x})\n", .{std_stats.mean, std_stats.standard_deviation(), std_stats.hash});
    std.debug.print("  Sentinel Search:  {d:.2} mean {d:.2} stddev ns/op (Hash: 0x{x})\n", .{sentinel_stats.mean, sentinel_stats.standard_deviation(), sentinel_stats.hash});
    std.debug.print("  Two-Way Search:   {d:.2} mean {d:.2} stddev ns/op (Hash: 0x{x})\n", .{two_stats.mean, two_stats.standard_deviation(), two_stats.hash});
}
