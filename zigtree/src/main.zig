const std = @import("std");
const bts = @import("binary_tree_set.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const IntTreeSet = bts.BinaryTreeSet(i32);
    var tree: IntTreeSet.Tree = null;

    const nums = [_]i32{ 5, 3, 8, 1, 4, 6, 9 };
    for (nums) |num| {
        tree = try IntTreeSet.insert(allocator, num, tree);
    }

    std.debug.print("Searching for 4 (exists): {}\n", .{IntTreeSet.member(4, tree)});
    std.debug.print("Searching for 7 (missing): {}\n", .{IntTreeSet.member(7, tree)});

    std.debug.print("Searching for 4 (exists): {}\n", .{IntTreeSet.member2(4, tree, null)});
    std.debug.print("Searching for 7 (missing): {}\n", .{IntTreeSet.member2(7, tree, null)});

    std.debug.print("Searching for 4 (exists): {}\n", .{IntTreeSet.member3(4, tree)});
    std.debug.print("Searching for 7 (missing): {}\n", .{IntTreeSet.member3(7, tree)});
}
