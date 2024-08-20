const std = @import("std");
const print = std.debug.print;
const log = std.log;
const http = std.http;

//Types
const JsonList = std.ArrayListAligned(std.json.Value, null);
const Allocator = std.mem.Allocator;

///Retrieves raw json from github and returns a slice that has to be freed by the caller
pub fn retrieveRawJson(alloc: Allocator, url: []const u8) ![]u8 {
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

pub fn getFirstArg(alloc: Allocator) [:0]const u8 {
    var arg_iter = try std.process.argsWithAllocator(alloc);
    defer arg_iter.deinit();

    //Initialization using result location
    const default: [:0]const u8 = &("MILANO".*);

    //Skip program name
    _ = arg_iter.skip();

    //return first arg if there is one otherwise return default slice
    return arg_iter.next() orelse {
        log.err("wrong number of arguments, please use like this: `./zanagrafe <nome comune>` --> using default value: MILANO", .{});
        return default;
    };
}

pub fn linearDisplayGrep(json_list: *const JsonList, comune_chosen: []const u8) void {
    for (json_list.items) |obj| {
        const comune = obj.object.get("COMUNE").?.string;
        if (std.mem.containsAtLeast(u8, comune, 1, comune_chosen)) {
            const residents = obj.object.get("RESIDENTI").?.integer;
            print("\tNumero residenti del comune di {s} al {s}: {}\n", .{ comune, obj.object.get("DATA ELABORAZIONE").?.string, residents });
        }
    }
}

/// FIXME: if more comuni have same num of residents, prints only the first one it
/// finds.
pub fn printBigAndSmall(json_list: *const JsonList) void {
    var comune = json_list.items[0].object.get("COMUNE").?.string;
    var residents = json_list.items[0].object.get("RESIDENTI").?.integer;

    const Extrema = struct {
        big: i64 = 0,
        small: i64 = 0,
        com_big: []const u8 = undefined,
        com_small: []const u8 = undefined,
    };

    var status = Extrema{
        .big = residents,
        .small = residents,
        .com_big = comune,
        .com_small = comune,
    };

    for (json_list.items) |obj| {
        comune = obj.object.get("COMUNE").?.string;
        residents = obj.object.get("RESIDENTI").?.integer;

        if (residents > status.big) {
            status.big = residents;
            status.com_big = comune;
        } else if (residents < status.small) {
            status.small = residents;
            status.com_small = comune;
        }
    }
    print("Comune with the highest number of residents ({}): {s}\n", .{ status.big, status.com_big });
    print("Comune with the lowest number of residents ({}): {s}\n", .{ status.small, status.com_small });
}
