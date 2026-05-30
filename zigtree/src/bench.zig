const std = @import("std");

pub const BenchmarkStats = struct {
    count: f64 = 0,
    mean: f64 = 0,
    m2: f64 = 0,
    min: u64 = std.math.maxInt(u64),
    max: u64 = 0,

    const This = @This();

    /// Record a sample from the benchmark and update stats. Note that we 
    /// calculate the mean and std dev using Welford's method.
    ///
    /// Reference: Donald E. Knuth (1998). The Art of Computer Programming, 
    /// Vol 2: Seminumerical Algorithms, 3rd ed., page 232.
    pub fn record(self: *This, sample: u64) void {
        self.min = @min(self.min, sample);
        self.max = @max(self.max, sample);

        const x = @as(f64, @floatFromInt(sample));
        self.count += 1.0;

        const delta = x - self.mean;
        self.mean += delta / self.count;

        const delta2 = x - self.mean;
        self.m2 += delta * delta2;
    }

    /// Returns the population variance
    pub fn variance(self: *This) f64 {
        if (self.count < 1.0) return 0.0;
        return self.m2 / self.count;
    }

    /// Returns the population standard deviation
    pub fn standard_deviation(self: *This) f64 {
        return std.math.sqrt(self.variance());
    }
};

test "BenchmarkStats basic operations" {
    var stats = BenchmarkStats{};

    stats.record(10);
    stats.record(20);
    stats.record(30);

    try std.testing.expectEqual(@as(u64, 10), stats.min);
    try std.testing.expectEqual(@as(u64, 30), stats.max);
    
    try std.testing.expectApproxEqAbs(@as(f64, 20.0), stats.mean, 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 8.16496580927726), stats.standard_deviation(), 1e-9);
}
