//const chip_lib = @import("chip8.zig");
//const chip = chip_lib.chip;
const std = @import("std");
const print = std.debug.print;
const fmt = std.fmt.allocPrint;

const Allocator = std.mem.Allocator;
const InnerMap = std.AutoHashMap(u8, *const fn (u16) void);
const OpTableRecord = union(enum) {
    map: InnerMap,
    fun: *const fn (u16) void,
};

const OpTable = std.AutoHashMap(u4, OpTableRecord);

var op_table: OpTable = undefined;

pub fn initTable(alloc: *Allocator) !void {
    op_table = OpTable.init(alloc.*);
    var map = InnerMap.init(alloc.*);

    //0x0
    try map.put(0xEE, returnSub);
    try map.put(0xE0, displayClear);
    try op_table.put(0x0, OpTableRecord{ .map = map });

    //0x1 - 0x7
    try op_table.put(0x1, OpTableRecord{ .fun = gotoAddr });
    try op_table.put(0x2, OpTableRecord{ .fun = callSub });
    try op_table.put(0x3, OpTableRecord{ .fun = skpIfRegEqN });
    try op_table.put(0x4, OpTableRecord{ .fun = skpIfRegNotEqN });
    try op_table.put(0x5, OpTableRecord{ .fun = skpIfRegXEqRegY });
    try op_table.put(0x6, OpTableRecord{ .fun = setRegXToN });
    try op_table.put(0x7, OpTableRecord{ .fun = addNToRegX });

    //0x8
    map = InnerMap.init(alloc.*);
    try map.put(0x0, setRegXToRegY);
    try map.put(0x1, orRegXWithRegY);
    try map.put(0x2, andRegXWithRegY);
    try map.put(0x3, xorRegXWithRegY);
    try map.put(0x4, addRegYToRegXWithOverflow);
    try map.put(0x5, subRegYToRegXWithUnderflow);
    try map.put(0x6, shiftRightRegXByOne);
    try map.put(0x7, setRegXRegYSubRegXWithUnderflow);
    try map.put(0xE, shiftLeftRegXByOne);
    try op_table.put(0x8, OpTableRecord{ .map = map });

    //0x9 - 0xD
    try op_table.put(0x9, OpTableRecord{ .fun = skpIfRegXNotEqRegY });
    try op_table.put(0xA, OpTableRecord{ .fun = setIToAddr });
    try op_table.put(0xB, OpTableRecord{ .fun = jmpToAddrReg0PlusN });
    try op_table.put(0xC, OpTableRecord{ .fun = setRegXBitAndRandWithN });
    try op_table.put(0xD, OpTableRecord{ .fun = drawSprite });

    //0xE
    map = InnerMap.init(alloc.*);
    try map.put(0xA1, skpIfPressedKeyNotEqRegX);
    try map.put(0x9E, skpIfPressedKeyEqRegX);
    try op_table.put(0xE, OpTableRecord{ .map = map });

    //0xF
    map = InnerMap.init(alloc.*);
    try map.put(0x7, setRegXToDelayTimer);
    try map.put(0xA, setRegXToPressedKey);
    try map.put(0x15, setDelayTimerToRegX);
    try map.put(0x18, setSoundTimerToRegX);
    try map.put(0x1E, addRegXtoI);
    try map.put(0x29, setIToSpriteAddressRegX);
    try map.put(0x33, noOp);
    try map.put(0x55, noOp);
    try map.put(0x65, noOp);

    try op_table.put(0xF, OpTableRecord{ .map = map });
}

pub fn execOp(op: u16) !void {
    if (op == 0) return;
    const nimb: u4 = @intCast((op & 0xf000) >> 12);
    switch (op_table.get(nimb).?) {
        .map => |m| switch (nimb) {
            0x8 => m.get(@intCast(op & 0x000f)),
            else => m.get(@intCast(op & 0x00ff)),
        }.?(op),
        .fun => |f| f(op),
    }
}

fn returnSub(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn displayClear(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn gotoAddr(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn noOp(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn callSub(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn skpIfRegEqN(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn skpIfRegNotEqN(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn skpIfRegXEqRegY(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setRegXToN(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn addNToRegX(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setRegXToRegY(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn orRegXWithReg(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn andRegXWithRegY(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn xorRegXWithRegY(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn orRegXWithRegY(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn jmpToAddrReg0PlusN(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn addRegYToRegXWithOverflow(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn subRegYToRegXWithUnderflow(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn shiftRightRegXByOne(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setRegXRegYSubRegXWithUnderflow(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn shiftLeftRegXByOne(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn skpIfRegXNotEqRegY(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setIToAddr(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setRegXBitAndRandWithN(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn drawSprite(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn skpIfPressedKeyEqRegX(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setRegXToDelayTimer(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setRegXToPressedKey(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setDelayTimerToRegX(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setSoundTimerToRegX(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn addRegXtoI(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn setIToSpriteAddressRegX(op: u16) void {
    print("{X:0>4}\n", .{op});
}

fn skpIfPressedKeyNotEqRegX(op: u16) void {
    print("{X:0>4}\n", .{op});
}
