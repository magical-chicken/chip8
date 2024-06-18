const std = @import("std");
const print = std.debug.print;

const Chip8 = struct {
    ram: [4096]u8 = .{0} ** 4096,
    V: [16]u8 = .{0} ** 16,
    PC: u16 = 0x200,
    I: u16 = 0,
    SP: u16 = 0xEA0,
    delayTimer: u8 = 0, //60hz
    soundTimer: u8 = 0,
    display_w: u8 = 64,
    display_h: u8 = 32,
    keyboard: [16]u8 = .{0} ** 16,
};

var glb_chip = Chip8{};
pub const chip = &glb_chip;
pub const ChipError = error{
    OpCodeNotFound,
};
