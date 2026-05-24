const std = @import("std");

/// Implementation of a standard binary tree and search
pub fn BinaryTreeStd(comptime T: type) type {
    return struct {
        pub const Node = struct {
            value: T,
            left: ?*Node = null,
            right: ?*Node = null,
        };

        pub const Tree = ?*Node;

        pub fn insert(allocator: std.mem.Allocator, value: T, t: Tree) !Tree {
            if (t) |node| {
                if (value < node.value) {
                    node.left = try insert(allocator, value, node.left);
                } else if (value > node.value) {
                    node.right = try insert(allocator, value, node.right);
                }
                return t;
            } else {
                const new_node = try allocator.create(Node);
                new_node.* = .{ .value = value };
                return new_node;
            }
        }

        /// Basic version of member (2 comparisons per node plus the null check)
        pub fn member(x: T, t: Tree) bool {
            if (t) |node| {
                if (x < node.value) return member(x, node.left);
                if (x > node.value) return member(x, node.right);
                return true;
            }
            return false;
        }

        /// Optimized version of member taking d+1 max comparisons
        pub fn member2(x: T, t: Tree, candidate: ?T) bool {
            if (t) |node| {
                if (x >= node.value) {
                    return member2(x, node.right, node.value);
                } else {
                    return member2(x, node.left, candidate);
                }
            } else {
                if (candidate) |c| {
                    return c == x;
                }
                return false;
            }
        }

        pub fn member3(x: T, t: Tree) bool {
            var node = t;
            while (node) |curr| {
                const compare = std.math.order(x, curr.value); 
                switch (compare) {
                    .lt => node = curr.left,
                    .gt => node = curr.right,
                    .eq => return true,
                }
            }
            return false;
        }
    };
}
