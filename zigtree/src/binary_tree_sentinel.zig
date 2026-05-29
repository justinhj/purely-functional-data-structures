const std = @import("std");

/// Implementation of a binary tree and search with sentinel leaves
pub fn BinaryTreeSentinel(comptime T: type) type {
    return struct {
        const This = @This();
        pub const Node = struct {
            value: T,
            left: ?*Node = null,
            right: ?*Node = null,
        };

        pub var root: *Node = null;
        pub var sentinel: *Node = null;

        pub const Tree = ?*Node;

        pub fn init(gpa: std.mem.Allocator) !This {
            const sentinel_node = try gpa.create(Node);
            return This {
                .root = null,
                .sentinel = sentinel_node,
            };
        }

        pub fn setSentinel(this: *This, value: T) void {
            this.sentinel.value = value;
        }

        pub fn insert(this: *This, allocator: std.mem.Allocator, value: T) !void {
            const t: *Node = this.root;
            if (t == null) {
                const new_node = try allocator.create(Node);
                new_node.* = .{ .value = value, .left = this.sentinel, .right = this.sentinel };
                this.root = new_node;
            }
            else { 
                while (true) {
                    if (value < t.value) {
                        t = t.left;
                    } else if (value > t.value) {
                        t = t.right;
                    }
                    else {
                        if (t == this.sentinel) {
                            const new_node = try allocator.create(Node);
                            new_node.* = .{ .value = value, .left = this.sentinel, .right = this.sentinel };
                        } else { 
                            // Else we found the value we are inserting so just exit
                            return;
                        }
                    }
                }
            }
        }

        // Basic version of member (2 comparisons per node plus the null check)
        // pub fn member(x: T, t: Tree) bool {
        //     if (t) |node| {
        //         if (x < node.value) return member(x, node.left);
        //         if (x > node.value) return member(x, node.right);
        //         return true;
        //     }
        //     return false;
        // }
    };
}
