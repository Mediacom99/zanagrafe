const std = @import("std");
const print = std.debug.print;

pub fn main() !void {

    //Perform http request to github and retrieve the json file.

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_result = gpa.deinit();
        print("INFO: general purpose allocator deinit status: {}\n", .{deinit_result});
    }
    const alloc = gpa.allocator();

    var http_client: std.http.Client = std.http.Client{ .allocator = alloc };
    defer http_client.deinit();

    const url_file_to_download = "https://github.com/italia/anpr-opendata/blob/main/data/popolazione_residente_export.json";
    const uri = try std.Uri.parse(url_file_to_download);
    const headers = .{};
    var response_body = std.ArrayList(u8).init(alloc);
    defer response_body.deinit();

    // Fetch something from github
    const fetch_options = std.http.Client.FetchOptions{
        .location = std.http.Client.FetchOptions.Location{ .uri = uri },
        .method = std.http.Method.GET,
        .response_storage = std.http.Client.FetchOptions.ResponseStorage{ .dynamic = &response_body },
        .headers = headers,
    };
    const fetch_results = try http_client.fetch(fetch_options); //Sending http request

    print("Fetch results http status: {}\n", .{fetch_results});
    print("Response body capacity: {}\n", .{response_body.capacity});
    print("Response body: {s}\n", .{response_body.items});
}
