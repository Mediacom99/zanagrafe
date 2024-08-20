const std = @import("std");
const print = std.debug.print;
const log = std.log;
const http = std.http;
const JsonArrayList = std.ArrayListAligned(std.json.Value, null);
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

alloc: Allocator,
data_url: []const u8 = undefined,
data: []const u8 = undefined,
args: []const u8 = undefined,

const Jsonlist = @This();

pub fn init(allocator: Allocator, url: []const u8) Jsonlist {
    return .{
        .alloc = allocator,
        .data_url = url,
    };
}

test "initialization" {
    // Heap Arean Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const url = "https://raw.githubusercontent.com/italia/anpr-opendata/main/data/popolazione_residente_export.json";

    const jlist = Jsonlist.init(alloc, url);

    try expect(std.mem.eql(u8, jlist.data_url, url));
}
