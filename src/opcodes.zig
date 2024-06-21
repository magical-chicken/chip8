const chip_lib = @import("chip8.zig");
const kb = @import("keyboard/keyboard.zig");
const graph = @import("graphics/display.zig");
const sound = @import("sound/sound.zig");
const chip = chip_lib.chip;
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
    try map.put(0x33, loadBCD);
    try map.put(0x55, loadRegistersToMem);
    try map.put(0x65, loadMemToRegisters);

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
    _ = op;
    const most_sig = chip.ram[chip.SP];
    chip.SP -= 1;
    const least_sig = chip.ram[chip.SP];
    chip.SP -= 1;
    const addr: u16 = (@as(u16, most_sig) << 8) | least_sig;
    chip.PC = addr;
}

pub fn displayClear(op: u16) void {
    _ = op;
    for (chip.ram[0x0f00..]) |*pixel| {
        pixel.* = 0;
    }
    graph.screenClear();
    chip.PC += 2;
}

fn gotoAddr(op: u16) void {
    chip.PC = op & 0x0fff;
}

fn callSub(op: u16) void {
    const sp = &chip.SP;
    const next_addr_inst = chip.PC + 2;
    const most_sig: u8 = @intCast((next_addr_inst & 0xFF00) >> 8);
    const least_sig: u8 = @intCast(next_addr_inst & 0x00FF);

    sp.* += 1;
    chip.ram[sp.*] = least_sig;
    sp.* += 1;
    chip.ram[sp.*] = most_sig;
    chip.PC = op & 0x0FFF;
}

fn skpIfRegEqN(op: u16) void {
    const nn: u8 = @intCast(op & 0x00FF);
    const reg = chip.V[(op & 0x0f00) >> 8];

    if (nn == reg) {
        chip.PC += 4;
    } else {
        chip.PC += 2;
    }
}

fn skpIfRegNotEqN(op: u16) void {
    const nn: u8 = @intCast(op & 0x00FF);
    const reg = chip.V[(op & 0x0f00) >> 8];

    if (nn != reg) {
        chip.PC += 4;
    } else {
        chip.PC += 2;
    }
}

fn skpIfRegXEqRegY(op: u16) void {
    const reg_x = chip.V[(op & 0x0f00) >> 8];
    const reg_y = chip.V[(op & 0x00f0) >> 4];

    if (reg_x == reg_y) {
        chip.PC += 4;
    } else {
        chip.PC += 2;
    }
}

fn setRegXToN(op: u16) void {
    const nn: u8 = @intCast(op & 0x00ff);
    chip.V[(op & 0x0f00) >> 8] = nn;
    chip.PC += 2;
}

fn addNToRegX(op: u16) void {
    const nn: u8 = @intCast(op & 0x00ff);
    const reg = &chip.V[(op & 0x0f00) >> 8];
    reg.* = @addWithOverflow(reg.*, nn)[0];
    chip.PC += 2;
}

fn setRegXToRegY(op: u16) void {
    const reg_y = chip.V[(op & 0x00f0) >> 4];
    chip.V[(op & 0x0f00) >> 8] = reg_y;
    chip.PC += 2;
}

fn orRegXWithRegY(op: u16) void {
    const reg_y = chip.V[(op & 0x00f0) >> 4];
    chip.V[(op & 0x0f00) >> 8] |= reg_y;
    chip.V[0xF] = 0;
    chip.PC += 2;
}

fn andRegXWithRegY(op: u16) void {
    const reg_y = chip.V[(op & 0x00f0) >> 4];
    chip.V[(op & 0x0f00) >> 8] &= reg_y;
    chip.V[0xF] = 0;
    chip.PC += 2;
}

fn xorRegXWithRegY(op: u16) void {
    const reg_y = chip.V[(op & 0x00f0) >> 4];
    chip.V[(op & 0x0f00) >> 8] ^= reg_y;
    chip.V[0xF] = 0;
    chip.PC += 2;
}

fn jmpToAddrReg0PlusN(op: u16) void {
    chip.PC = chip.V[0] + (op & 0x0fff);
}

fn addRegYToRegXWithOverflow(op: u16) void {
    const reg_x_p = &chip.V[(op & 0x0f00) >> 8];
    const result = @addWithOverflow(reg_x_p.*, chip.V[(op & 0x00f0) >> 4]);
    reg_x_p.* = result[0];
    chip.V[0xF] = result[1];
    chip.PC += 2;
}

fn subRegYToRegXWithUnderflow(op: u16) void {
    const reg_x_p = &chip.V[(op & 0x0f00) >> 8];
    const reg_y = chip.V[(op & 0x00f0) >> 4];
    const result = @subWithOverflow(reg_x_p.*, reg_y);
    reg_x_p.* = result[0];
    chip.V[0xF] = result[1] ^ 1;
    chip.PC += 2;
}

fn setRegXRegYSubRegXWithUnderflow(op: u16) void {
    const reg_x_p = &chip.V[(op & 0x0f00) >> 8];
    const reg_y = chip.V[(op & 0x00f0) >> 4];
    const result = @subWithOverflow(reg_y, reg_x_p.*);
    reg_x_p.* = result[0];
    chip.V[0xF] = result[1] ^ 1;
    chip.PC += 2;
}

fn shiftRightRegXByOne(op: u16) void {
    const reg_x_p = &chip.V[(op & 0x0f00) >> 8];
    reg_x_p.* = chip.V[(op & 0x00f0) >> 4];

    const lsb: u8 = @intCast(reg_x_p.* & 0x01);
    reg_x_p.* >>= 1;
    chip.V[0xF] = lsb;
    chip.PC += 2;
}

fn shiftLeftRegXByOne(op: u16) void {
    const reg_x_p = &chip.V[(op & 0x0f00) >> 8];
    reg_x_p.* = chip.V[(op & 0x00f0) >> 4];
    const msb: u8 = @intCast((reg_x_p.* & 0x80) >> 7);
    reg_x_p.* <<= 1;
    chip.V[0xF] = msb;
    chip.PC += 2;
}

fn skpIfRegXNotEqRegY(op: u16) void {
    const reg_x = chip.V[(op & 0x0f00) >> 8];
    const reg_y = chip.V[(op & 0x00f0) >> 4];

    if (reg_x != reg_y) {
        chip.PC += 4;
    } else {
        chip.PC += 2;
    }
}

fn setIToAddr(op: u16) void {
    chip.I = op & 0x0fff;
    chip.PC += 2;
}

fn setRegXBitAndRandWithN(op: u16) void {
    print("{X:0>4}\n", .{op});
    chip.PC += 2;
}

pub fn drawSprite(op: u16) void {
    const x = chip.V[(op & 0x0f00) >> 8];
    var y = chip.V[(op & 0x00f0) >> 4] % 32;
    const sprite_h: u8 = @intCast(op & 0x000f);
    const hh: u8 = if (y + sprite_h > 32) y + (32 - y) else y + sprite_h; //naive clipping
    var i: u8 = 0;
    chip.V[0xf] = 0; //reset collision
    while (y < hh) : (y += 1) {
        loadPixel(
            x,
            y,
            chip.ram[chip.I + i],
        );

        i += 1;
    }
    graph.render();
    graph.delay(17); //about 60fps

    chip.PC += 2;
}

fn loadPixel(x: u8, y: u8, sprite_segment: u8) void {
    const xp = x % 64;
    const index: u16 = (@as(u16, y) * 8) + (xp / 8);
    detectCollision(
        index,
        sprite_segment,
        xp,
    );
}

fn detectCollision(index: u16, sprite_segment: u8, bits: u8) void {
    const left_shift: u3 = @intCast(bits % 8);
    const alignment: u3 = if (left_shift > 0) 1 else 0;
    const right_shift: u3 = @as(u3, @intCast(7 - left_shift)) + alignment;
    xorSprite(
        sprite_segment >> left_shift,
        index,
    );

    if (right_shift > 0 and bits + 8 <= 64)
        xorSprite(
            sprite_segment << right_shift,
            index + 1,
        );
}

fn xorSprite(sprite_segment: u8, index: u16) void {
    if (sprite_segment == 0) return;
    const display_byte = &chip.ram[index + 0xf00];
    for (0..8) |i| {
        const bit_index: u8 = @as(u8, 0x01) << @as(u3, @intCast(i));
        const current_bit = sprite_segment & bit_index;
        if (current_bit > 0) {
            const display_bit = display_byte.* & bit_index;
            if (display_bit == current_bit) {
                chip.V[0xf] = 1;
            }
            display_byte.* ^= current_bit;
        }
    }
}

fn skpIfPressedKeyEqRegX(op: u16) void {
    const reg = chip.V[(op & 0x0f00) >> 8];
    const key = chip.keyboard[reg];
    if (key == 1) chip.PC += 2;
    chip.PC += 2;
}

fn setRegXToDelayTimer(op: u16) void {
    chip.V[(op & 0x0f00) >> 8] = chip.delayTimer;
    chip.PC += 2;
}

fn setRegXToPressedKey(op: u16) void {
    const register = &chip.V[(op & 0x0f00) >> 8];
    if (!kb.loadNextKeyInRegister(register)) return;
    chip.PC += 2;
}

fn setDelayTimerToRegX(op: u16) void {
    chip.delayTimer = chip.V[(op & 0x0f00) >> 8];
    chip.PC += 2;
}

fn setSoundTimerToRegX(op: u16) void {
    chip.soundTimer = chip.V[(op & 0x0f00) >> 8];
    if (chip.soundTimer > 0) sound.beep();
    chip.PC += 2;
}

fn addRegXtoI(op: u16) void {
    chip.I += chip.V[(op & 0x0f00) >> 8];
    chip.PC += 2;
}

fn setIToSpriteAddressRegX(op: u16) void {
    print("{X:0>4}\n", .{op});
    chip.PC += 2;
}

fn skpIfPressedKeyNotEqRegX(op: u16) void {
    const reg = chip.V[(op & 0x0f00) >> 8];
    const key = chip.keyboard[reg];
    if (key == 0) chip.PC += 2;
    chip.PC += 2;
}

fn loadRegistersToMem(op: u16) void {
    const n = (op & 0x0f00) >> 8;
    for (chip.V[0 .. n + 1], 0..) |reg, i| {
        chip.ram[chip.I + @as(u16, @intCast(i))] = reg;
    }
    chip.I += n + 1;
    chip.PC += 2;
}

fn loadMemToRegisters(op: u16) void {
    const n = (op & 0x0f00) >> 8;
    var i: u16 = 0;
    while (i < n + 1) : (i += 1) {
        chip.V[i] = chip.ram[chip.I + i];
    }
    chip.I += n + 1;
    chip.PC += 2;
}

fn loadBCD(op: u16) void {
    const n: u8 = chip.V[(op & 0x0f00) >> 8];
    const units: u8 = n % 10;
    const tens: u8 = ((n - units) % 100) / 10;
    const hundreds: u8 = (n - tens - units) / 100;
    chip.ram[chip.I] = hundreds;
    chip.ram[chip.I + 1] = tens;
    chip.ram[chip.I + 2] = units;
    chip.PC += 2;
}
