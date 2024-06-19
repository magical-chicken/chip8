const chip = @import("../chip8.zig").chip;
const sdl = @cImport({
    @cInclude("/usr/include/SDL2/SDL.h");
});
const print = @import("std").debug.print;
const Event = sdl.SDL_Event;
pub var keyboard_event: Event = undefined;

pub fn detectInput() void {
    if (sdl.SDL_PollEvent(&keyboard_event) == 1) {
        if (keyboard_event.type == sdl.SDL_KEYDOWN) {
            if (getKeyCode(keyboard_event.key.keysym.sym)) |code| {
                chip.keyboard[code] = 1;
            }
        } else if (keyboard_event.type == sdl.SDL_KEYUP) {
            if (getKeyCode(keyboard_event.key.keysym.sym)) |code| {
                chip.keyboard[code] = 0;
            }
        }
    }
}

// pub fn windowExit() bool {
//     return sdl.SDL_PollEvent(&keyboard_event) == 1 and keyboard_event.type == sdl.SDL_WINDOWEVENT and keyboard_event.window.event == sdl.SDL_WINDOWEVENT_CLOSE;
// }

pub fn loadNextKeyInRegister(reg: *u8) void {
    while (true) {
        if (sdl.SDL_WaitEvent(&keyboard_event) > 0 and keyboard_event.type == sdl.SDL_KEYDOWN) {
            if (getKeyCode(keyboard_event.key.keysym.sym)) |code| {
                chip.keyboard[code] = 1;
                reg.* = code;
                break;
            }
        }
    }
}

fn getKeyCode(code: sdl.SDL_Keycode) ?u8 {
    return switch (code) {
        '1' => 1,
        '2' => 2,
        '3' => 3,
        '4' => 0xC,
        'q' => 4,
        'w' => 5,
        'e' => 6,
        'r' => 0xD,
        'a' => 7,
        's' => 8,
        'd' => 9,
        'f' => 0xE,
        'z' => 0xA,
        'x' => 0,
        'c' => 0xB,
        'v' => 0xF,
        else => null,
    };
}
