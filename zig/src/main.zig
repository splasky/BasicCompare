const std = @import("std");
const Instant = std.time.Instant;
const rngenerator = std.rand.DefaultPrng;

//declare and initialize pieces/parts to be used
const Account = struct {
    account_id: i32,
    current_bill: i32,
    balance: i32,
    paid_amount: i32,
};
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    //declare oper/iter size and timer parts
    var args = std.process.args();
    const argv = [_]?[]const u8{ args.next(), args.next(), args.next() };
    const opers: usize = if (argv[1] != null)
        try std.fmt.parseUnsigned(usize, argv[1].?, 10)
    else
        100;
    const iters: usize = if (argv[2] != null)
        try std.fmt.parseUnsigned(usize, argv[2].?, 10)
    else
        100;
    var min: usize = std.math.maxInt(usize);
    var max: usize = 0;
    var average: usize = 0;
    const total = try Instant.now();

    //Declare and begin iterations
    std.debug.print("Zig performing {} operations over {} iterations.\n", .{ opers, iters });
    for (0..iters) |iteration| {
        //start timer
        const start = try Instant.now();
        //initialize psuedo random seed
        const tmp: u64 = @intCast(iters + opers);
        var rng = rngenerator.init(tmp + iteration);

        //initialize collection
        var accounts = std.ArrayList(Account).init(allocator);
        //free collection (defer'd)
        defer accounts.deinit();
        //fill collection
        for (0..opers) |i|
            try accounts.append(.{
                .account_id = @intCast(i),
                .current_bill = @intCast(rng.next() % 1000),
                .balance = @intCast(rng.next() % 100),
                .paid_amount = @intCast(rng.next() % 1000),
            });

        //process accounts for collection
        for (0..opers) |_|
            for (accounts.items) |*account| {
                const payment: i32 = if (account.balance < account.current_bill) account.balance else account.current_bill;
                account.paid_amount += payment;
                account.paid_amount >>= 2;
                const bill: i32 = @intCast(rng.next() % 100);
                account.current_bill += account.current_bill - payment + bill;
                account.current_bill >>= 2;
                account.balance += @intCast(rng.next() % 100);
            };

        //grab time
        const diff = (try Instant.now()).since(start);
        if (diff < min) min = diff;
        if (diff > max) max = diff;
        average += diff;
    }
    //print result
    const diff_total: f64 = @floatFromInt((try Instant.now()).since(total));
    const diff_seconds: f64 = diff_total / 1e9;
    std.debug.print("Done! after {d:.5} seconds\n", .{diff_seconds});
    std.debug.print("\tmax: {}, min: {}, avg: {} nanoseconds\n\n", .{ max, min, average / iters });
}
