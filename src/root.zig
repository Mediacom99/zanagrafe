const std = @import("std");
const print = std.debug.print;
const log = std.log;
const http = std.http;
const JsonList = std.ArrayListAligned(std.json.Value,null);

//Retrieves raw json from github and returns a slice that has to be freed by the caller
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
    log.debug("response body capacity: {}", .{response_body.capacity});

    const is_json_valid = try std.json.validate(alloc, response_body.items);

    //TODO should handle this case better
    if (!is_json_valid) {
        log.err("file fetched from given link is not a valid JSON file, exiting.", .{});
    }

    return response_body.toOwnedSlice();

}

pub fn printStuff(json_list: *const JsonList) void {

    const numero_comuni = json_list.items.len;
    const data_elab = json_list.items[0].object.get("DATA ELABORAZIONE").?.string;
    const comune = json_list.items[0].object.get("COMUNE").?.string;
    const residenti = json_list.items[0].object.get("RESIDENTI").?.integer;

    log.info("Numero totale di comuni in Italia al {s}: {}", .{ data_elab, numero_comuni });
    log.info("Numero di residenti del comune di {s} aggiornato al {s}: {}", .{ comune, data_elab, residenti });
}
