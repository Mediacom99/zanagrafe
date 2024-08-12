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
    var arg_comune: []const u8 = undefined;

    var arg_iter = try std.process.argsWithAllocator(alloc);
    defer arg_iter.deinit();

    _ = arg_iter.skip();
    const arg = arg_iter.next();
    if (arg == null) {
        log.err("wrong number of arguments, please use like this: `./zanagrafe <nome-comune>` -- using default value", .{});
        arg_comune = "MILANO";
    } else {
        arg_comune = arg.?;
    }

    const url = "https://raw.githubusercontent.com/italia/anpr-opendata/main/data/popolazione_residente_export.json";

    const response_body_slice = try root.retrieveRawJson(alloc, url);
    var response_body = std.ArrayList(u8).fromOwnedSlice(alloc, response_body_slice);
    defer response_body.deinit();

    var json_parsed = try std.json.parseFromSlice(std.json.Value, alloc, response_body.items, .{ .ignore_unknown_fields = true });
    defer json_parsed.deinit();

    const json_list = json_parsed.value.array; //ArrayList containing std.json.Value data, each object is the data for a comune

    //root.printStuff(&json_list);
    for (json_list.items) |obj| {
        const comune = obj.object.get("COMUNE").?.string;
        if (std.mem.containsAtLeast(u8, comune, 1, arg_comune)) {
            log.info("\tResidenti di {s}: {}", .{ comune, obj.object.get("RESIDENTI").?.integer });
        }
    }
}
