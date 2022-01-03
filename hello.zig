const std = @import("std");
const sleep = std.time.sleep;
const print = std.debug.print;

pub fn main() void {
    print("hello world\n", .{});
    sleep(0xFF_FF_FF_FF_FF_FF_FF_FF);
}
