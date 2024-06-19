const std = @import("std");
const opc = @import("opcodes.zig");
const chip8 = @import("chip8.zig");
const graph = @import("graphics/display.zig");
const kb = @import("keyboard/keyboard.zig");
const Instant = std.time.Instant;

const chip = chip8.chip;
const print = std.debug.print;

pub fn main() !void {
    var ar_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = ar_allocator.allocator();
    defer ar_allocator.deinit();
    defer graph.destroyGraphics();
    graph.initGraphics();
    try opc.initTable(&allocator);
    try load_code();
    try execROM();
}

fn execROM() !void {
    const timer = Timer.init(16_670_000, updateTimers);
    graph.screenClear();
    while (true) {
        try opc.execOp(fetch());
        try timer.checkTime();

        //update io
        kb.detectInput();

        //        graph.inspectMemory();
    }
}

fn fetch() u16 {
    return (@as(u16, chip.ram[chip.PC]) << 8) | chip.ram[chip.PC + 1];
}

fn load_code() !void {
    // for (chip.ram[0..]) |*b| {
    //     b.* = 0xff;
    // }
    // //    graph.showSprite(10, 10, 8);
    // graph.showSprite(30, 10, 8);
    // graph.showSprite(50, 10, 8);
    // graph.present();
    const in = std.io.getStdIn();
    defer in.close();
    var buf_reader = std.io.bufferedReader(in.reader());
    const reader = buf_reader.reader();
    const buffer = &chip.ram;
    reader.readNoEof(buffer[0x200..]) catch |err| if (err != error.EndOfStream) return err;
}

fn updateTimers() void {
    if (chip.delayTimer > 0) chip.delayTimer -= 1;
    if (chip.soundTimer > 0) chip.soundTimer -= 1;
}

const Timer = struct {
    ns: u64,
    operation: *const fn () void,

    var tm: Instant = undefined;
    var started: bool = false;

    fn init(ns: u64, fun: *const fn () void) Timer {
        return Timer{ .ns = ns, .operation = fun };
    }

    fn reset() !void {
        tm = try Instant.now();
    }

    fn checkTime(self: *const Timer) !void {
        if (!started) {
            started = true;
            try reset();
            return;
        }
        const t = try Instant.now();
        const delta = t.since(tm);
        if (delta >= self.ns) {
            self.operation();
            try reset();
        }
    }
};
