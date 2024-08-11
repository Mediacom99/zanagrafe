/// Download json file from github repo through http request, parse it and show the data,
/// Maybe I could write a simple database to manipulate the jsond data.
const std = @import("std");
const print = std.debug.print;
const log = std.log;
const http = std.http;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_result = gpa.deinit();
        log.info("general purpose allocator deinit status: {}", .{deinit_result});
    }
    const alloc = gpa.allocator();

    var http_client = http.Client{ .allocator = alloc };
    defer http_client.deinit();

    const url_file_to_download = "https://raw.githubusercontent.com/italia/anpr-opendata/main/data/popolazione_residente_export.json";
    const uri = try std.Uri.parse(url_file_to_download);
    const headers = .{};
    var response_body = std.ArrayList(u8).init(alloc);
    defer response_body.deinit();

    // Fetch options for http GET request
    const fetch_options = http.Client.FetchOptions{
        .location = http.Client.FetchOptions.Location{ .uri = uri },
        .method = http.Method.GET,
        .response_storage = http.Client.FetchOptions.ResponseStorage{ .dynamic = &response_body },
        .headers = headers,
    };
    const fetch_results = try http_client.fetch(fetch_options); //Sending http request to fetch file

    log.info("fetch results http status: {s}", .{fetch_results.status.phrase().?});
    log.info("response body capacity: {}", .{response_body.capacity});

    const is_json_valid = try std.json.validate(alloc, response_body.items);

    if (!is_json_valid) {
        defer log.info("file fetched from given link is not a valid JSON file, exiting.\n", .{});
    }

    // var parsed_string = try std.json.parseFromSlice(u8, alloc, response_body.items[0..], .{});
    // defer parsed_string.deinit();
}
