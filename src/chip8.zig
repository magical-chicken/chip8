const std = @import("std");
const print = std.debug.print;

const Chip8 = struct {
    ram: [4096]u8 = .{0} ** 4096,
    V: [16]u8 = .{0} ** 16,
    PC: u16 = 0x200,
    I: u16 = 0,
    delayTimer: u8 = 60, //60hz
    soundTimer: u8 = 60,
};

var glb_chip = Chip8{};
pub const chip = &glb_chip;
pub const ChipError = error{
    OpCodeNotFound,
};
