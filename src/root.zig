const std = @import("std");
const print = std.debug.print;
const log = std.log;
const http = std.http;
const JsonList = std.ArrayListAligned(std.json.Value, null);

///Retrieves raw json from github and returns a slice that has to be freed by the caller
pub fn retrieveRawJson(alloc: std.mem.Allocator, url: []const u8) ![]u8 {
    var http_client = http.Client{ .allocator = alloc };
    defer http_client.deinit();

    const url_file_to_download = url;
    const uri = try std.Uri.parse(url_file_to_download);
    const headers = .{};
    var response_body = std.ArrayList(u8).init(alloc);

    // Fetch options for http GET request
    const fetch_options = http.Client.FetchOptions{
        .location = http.Client.FetchOptions.Location{ .uri = uri },
        .method = http.Method.GET,
        .response_storage = http.Client.FetchOptions.ResponseStorage{ .dynamic = &response_body },
        .headers = headers,
    };

    const fetch_results = try http_client.fetch(fetch_options); //Sending http request to fetch file

    log.info("fetch results http status: {s}", .{fetch_results.status.phrase().?});
    log.info("http response body capacity (u8): {}", .{response_body.capacity});

    const is_json_valid = try std.json.validate(alloc, response_body.items);
    //TODO should handle this case better
    if (!is_json_valid) {
        log.err("file fetched from given link is not a valid JSON file, exiting.", .{});
        std.process.exit(1);
    }

    return response_body.toOwnedSlice();
}

/// retrieves all the provided arguments and concatenates them into a
/// single []u8 slice.
/// check if at least an argument has been provided. if not use default comune `MILANO`
/// TODO: should check that the name is written in capital letter
pub fn getArgsAsSentence(alloc: std.mem.Allocator) ![]u8 {
    var arg_iter = try std.process.argsWithAllocator(alloc);
    defer arg_iter.deinit();

    var arg_string = std.ArrayList(u8).init(alloc);
    defer arg_string.deinit();

    _ = arg_iter.skip(); //Skip program name

    const first = arg_iter.next() orelse {
        log.err("wrong number of arguments, please use like this: `./zanagrafe <nome comune>` --> using default value", .{});
        try arg_string.appendSlice("MILANO");
        return try arg_string.toOwnedSlice();
    };

    try arg_string.appendSlice(first); //append first arg
    try arg_string.append(' ');
    while (arg_iter.next()) |value| { //append all other args until null
        try arg_string.appendSlice(value);
        try arg_string.append(' ');
    }

    _ = arg_string.pop(); //remove extra space
    return try arg_string.toOwnedSlice();
}

pub fn linearDisplayGrep(json_list: *const JsonList, comune_chosen: []const u8) void {
    for (json_list.items) |obj| {
        const comune = obj.object.get("COMUNE").?.string;
        if (std.mem.containsAtLeast(u8, comune, 1, comune_chosen)) {
            print("\tNumero residenti del comune di {s} al {s}: {}\n", .{ comune, obj.object.get("DATA ELABORAZIONE").?.string, obj.object.get("RESIDENTI").?.integer });
        }
    }
}
