const std = @import("std");
const print = std.debug.print;
const log = std.log;
const http = std.http;
const JsonArrayList = std.ArrayListAligned(std.json.Value, null);
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

pub const JsonList = struct {
    alloc: Allocator,
    data_url: []const u8,
    data: []const u8 = undefined,
    cli_args: []const u8 = undefined,

    pub fn init(allocator: Allocator, url: []const u8) JsonList {
        return .{
            .alloc = allocator,
            .data_url = url,
        };
    }
};

test "initialization" {
    // Heap Arean Allocator
    const alloc = std.testing.allocator;

    const url = "https://raw.githubusercontent.com/italia/anpr-opendata/main/data/popolazione_residente_export.json";

    const jlist = JsonList.init(alloc, url);

    try expect(std.mem.eql(u8, jlist.data_url, url));
}
