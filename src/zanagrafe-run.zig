//! Download json file from github repo through http request, parse it and show the data,
//! Maybe I could write a simple database to manipulate the jsond data.
const std = @import("std");
const print = std.debug.print;
const log = std.log;
const zan = @import("zanagrafe.zig");

pub fn main() !void {
    // Heap allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    //Get first command line argument as Comune to search
    const arg_comune: [:0]const u8 = zan.getFirstArg(alloc);
    log.debug("You are looking for the Comune named: {s}", .{arg_comune});

    const url = "https://raw.githubusercontent.com/italia/anpr-opendata/main/data/popolazione_residente_export.json";

    var response_body = std.ArrayList(u8).fromOwnedSlice(alloc, try zan.retrieveRawJson(alloc, url));
    defer response_body.deinit();

    var json_parsed = try std.json.parseFromSlice(std.json.Value, alloc, response_body.items, .{ .ignore_unknown_fields = false });
    defer json_parsed.deinit();

    const json_list = json_parsed.value.array; //ArrayList containing std.json.Value data, each object is the data for a comune

    zan.linearDisplayGrep(&json_list, arg_comune);
    zan.printBigAndSmall(&json_list);
}
