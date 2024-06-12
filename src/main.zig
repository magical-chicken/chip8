const std = @import("std");
const opc = @import("opcodes.zig");
const chip8 = @import("chip8.zig");
const chip = chip8.chip;
const print = std.debug.print;

pub fn main() !void {
    var ar_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = ar_allocator.allocator();
    defer ar_allocator.deinit();
    try opc.initTable(&allocator);
    try load_code();
    while (chip.PC < 0xEA0) : (chip.PC += 2) {
        const opcode: u16 = (@as(u16, chip.ram[chip.PC]) << 8) | chip.ram[chip.PC + 1];

        opc.execOp(opcode) catch print("ERR: not found: {d}\n", .{opcode});
    }
}

fn load_code() !void {
    const in = std.io.getStdIn();
    defer in.close();
    var buf_reader = std.io.bufferedReader(in.reader());
    const reader = buf_reader.reader();
    var buffer = &chip.ram;
    reader.readNoEof(buffer[0x200..]) catch |err| if (err != error.EndOfStream) return err;
}
