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

        root: ?*Node = null,
        sentinel: *Node,

        pub const Tree = ?*Node;

        pub fn init(gpa: std.mem.Allocator) !This {
            const sentinel_node = try gpa.create(Node);
            sentinel_node.* = .{ .value = undefined, .left = null, .right = null };
            return This {
                .root = null,
                .sentinel = sentinel_node,
            };
        }

        pub fn setSentinel(this: *This, value: T) void {
            this.sentinel.value = value;
        }

        pub fn insert(this: *This, allocator: std.mem.Allocator, value: T) !void {
            var curr = this.root orelse {
                // Empty tree case
                const new_node = try allocator.create(Node);
                new_node.* = .{ .value = value, .left = this.sentinel, .right = this.sentinel };
                this.root = new_node;
                return;
            };

            var parent: *Node = undefined;
            this.sentinel.value = value; // sentinel search optimization
            
            while (value != curr.value) {
                parent = curr;
                if (value < curr.value) {
                    curr = curr.left.?;
                } else {
                    curr = curr.right.?;
                }
            }

            if (curr != this.sentinel) {
                // Value already exists in the tree
                return;
            }

            // Value not found (we reached sentinel). Create a new node.
            const new_node = try allocator.create(Node);
            new_node.* = .{ .value = value, .left = this.sentinel, .right = this.sentinel };

            if (value < parent.value) {
                parent.left = new_node;
            } else {
                parent.right = new_node;
            }
        }

        pub fn member(this: *This, x: T) bool {
            var curr = this.root orelse return false;
            this.sentinel.value = x;
            while (x != curr.value) {
                if (x < curr.value) {
                    curr = curr.left.?;
                } else {
                    curr = curr.right.?;
                }
            }
            return curr != this.sentinel;
        }
    };
}

test "BinaryTreeSentinel basic test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const FloatTree = BinaryTreeSentinel(f32);
    var tree = try FloatTree.init(allocator);
    tree.setSentinel(10.0);
    try std.testing.expect(tree.sentinel.value == 10.0);

    try tree.insert(allocator, 5.0);
    try tree.insert(allocator, 3.0);
    try tree.insert(allocator, 8.0);

    try std.testing.expect(tree.member(5.0) == true);
    try std.testing.expect(tree.member(3.0) == true);
    try std.testing.expect(tree.member(8.0) == true);
    try std.testing.expect(tree.member(4.0) == false);
}
