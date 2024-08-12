/// Download json file from github repo through http request, parse it and show the data,
/// Maybe I could write a simple database to manipulate the jsond data.
const std = @import("std");
const print = std.debug.print;
const log = std.log;
const http = std.http;
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_result = gpa.deinit();
        log.info("general purpose allocator deinit status: {}", .{deinit_result});
    }
    const alloc = gpa.allocator();

    const url =  "https://raw.githubusercontent.com/italia/anpr-opendata/main/data/popolazione_residente_export.json";
    
    const response_body_slice = try root.retrieveRawJson(alloc, url);
    var response_body = std.ArrayList(u8).fromOwnedSlice(alloc, response_body_slice);
    defer response_body.deinit();
    
    var json_parsed = try std.json.parseFromSlice(std.json.Value, alloc, response_body.items, .{ .ignore_unknown_fields = true });
    defer json_parsed.deinit();

    const json_list = json_parsed.value.array; //ArrayList containing std.json.Value data, each object is the data for a comune

    root.printStuff(&json_list);
}
