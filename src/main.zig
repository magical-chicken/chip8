const std = @import("std");
const opc = @import("opcodes.zig");
const chip8 = @import("chip8.zig");
const graph = @import("graphics/display.zig");
const sound = @import("sound/sound.zig");
const kb = @import("keyboard/keyboard.zig");
const Instant = std.time.Instant;

const chip = chip8.chip;
const print = std.debug.print;
var is_running = true;

pub fn main() !void {
    var ar_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = ar_allocator.allocator();
    defer ar_allocator.deinit();
    defer graph.destroyGraphics();
    defer sound.freeSoundChunks();

    graph.initGraphics();
    try sound.initSound();
    try opc.initTable(&allocator);
    try load_code();
    try execROM();
}

fn execROM() !void {
    const timer = Timer.init(16_670_000, updateTimers);

    while (is_running) {
        try opc.execOp(fetch());
        try timer.checkTime();
        kb.detectInput(&is_running); //need refactoring
    }
}

fn fetch() u16 {
    return (@as(u16, chip.ram[chip.PC]) << 8) | chip.ram[chip.PC + 1];
}

fn load_code() !void {
    const in = std.io.getStdIn();
    defer in.close();
    var buf_reader = std.io.bufferedReader(in.reader());
    const reader = buf_reader.reader();
    const buffer = &chip.ram;
    reader.readNoEof(buffer[0x200..]) catch |err| if (err != error.EndOfStream) return err;
}

fn updateTimers() void {
    if (chip.delayTimer > 0) chip.delayTimer -= 1;
    if (chip.soundTimer > 0) {
        chip.soundTimer -= 1;
        if (chip.soundTimer == 0) sound.bip();
    }
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
