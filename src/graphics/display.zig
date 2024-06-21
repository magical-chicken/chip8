const print = @import("std").debug.print;
const chip = @import("../chip8.zig").chip;
const sdl = @cImport({
    @cInclude("/usr/include/SDL2/SDL.h");
});

//display info configurable
const offset: u32 = 20;
const display_w: u32 = 64 * offset;
const display_h: u32 = 32 * offset;
const foreground_color: u32 = 0xfaebd7ff; //A91d3a
const background_color: u32 = 0x151515ff;

var buffer: [display_w * display_h]u32 = .{background_color} ** (display_w * display_h);

const Window = sdl.SDL_Window;
const Renderer = sdl.SDL_Renderer;
const Texture = sdl.SDL_Texture;

var wind: *Window = undefined;
var rend: *Renderer = undefined;
//var texture: *Texture = undefined;

const Color = struct { r: u8, g: u8, b: u8, a: u8 };
const Rect = sdl.SDL_Rect;

pub fn initGraphics() void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);
    wind = sdl.SDL_CreateWindow("chip8-VM", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, display_w, display_h, sdl.SDL_WINDOW_SHOWN).?;
    rend = sdl.SDL_CreateRenderer(wind, -1, sdl.SDL_RENDERER_ACCELERATED).?;

    //    texture = sdl.SDL_CreateTexture(rend, sdl.SDL_PIXELFORMAT_ARGB8888, sdl.SDL_TEXTUREACCESS_STREAMING, display_w, display_h).?;
}

//    const rect = Rect{ .x = 30, .y = 30, .w = 100, .h = 100 };
pub fn drawRect(rect: Rect, color: u32) void {
    const c = u32AsColor(color);
    _ = sdl.SDL_SetRenderDrawColor(rend, c.r, c.g, c.b, c.a);
    _ = sdl.SDL_RenderFillRect(rend, &rect);
}

//try to implement display rendering with renderFillRect
fn u32AsColor(color: u32) Color {
    return Color{
        .r = @intCast((color >> 24) & 0xff),
        .g = @intCast((color >> 16) & 0xff),
        .b = @intCast((color >> 8) & 0xff),
        .a = @intCast(color & 0xff),
    };
}

pub fn destroyGraphics() void {
    //    sdl.SDL_DestroyTexture(texture);
    sdl.SDL_DestroyRenderer(rend);
    sdl.SDL_DestroyWindow(wind);
    sdl.SDL_Quit();
}

pub fn delay(t: u32) void {
    sdl.SDL_Delay(t);
}

pub fn render() void {
    for (0..32) |y| {
        for (0..8) |x| {
            const ram_index = (y * 8) + x + 0x0f00;
            const wrapped_x = (x * 8) % 64;
            const wrapped_y = y % 32;
            mapPixelAt(wrapped_x, wrapped_y, ram_index);
        }
    }

    //    _ = sdl.SDL_UpdateTexture(texture, null, &buffer, display_w * @sizeOf(u32));
    //    _ = sdl.SDL_RenderClear(rend);
    //    _ = sdl.SDL_RenderCopy(rend, texture, null, null);
    sdl.SDL_RenderPresent(rend);
}

fn drawPixel(color: u32, x: u32, y: u32) void {
    buffer[(y * display_w) + x] = color;
}

pub fn screenClear() void {
    const c = u32AsColor(background_color);
    _ = sdl.SDL_SetRenderDrawColor(rend, c.r, c.g, c.b, c.a);
    _ = sdl.SDL_RenderClear(rend);
    sdl.SDL_RenderPresent(rend);
}

pub fn showSprite(x: usize, y: usize, sprite_h: u8) void {
    const wrapped_x = x % 64;
    const wrapped_y = y % 32;
    for (wrapped_y..wrapped_y + sprite_h) |sprite_y| {
        const ram_index = sprite_y * 8 + 0x0f00 + (wrapped_x / 8);
        mapPixelAt(wrapped_x, sprite_y, ram_index);
        mapPixelAt(wrapped_x + offset * 8, sprite_y, ram_index + 1);
    }
}

pub fn present() void {
    sdl.SDL_RenderPresent(rend);
}

pub fn mapPixelAt(x: usize, y: usize, ram_sprite_index: usize) void {
    if (ram_sprite_index >= chip.ram.len) return;
    const byte = chip.ram[ram_sprite_index];
    for (0..8) |bi| {
        const bit: u8 = byte & (@as(u8, 0x80) >> @as(u3, @intCast(bi)));
        const color: u32 = if (bit > 0) foreground_color else background_color;

        const rx: c_int = @intCast((x + @as(u32, @intCast(bi))) * offset);
        const ry: c_int = @intCast(y * offset);
        const wh: c_int = @intCast(offset);
        if (rx > display_w or ry > display_h) break; //clipping
        drawRect(.{ .x = rx, .y = ry, .w = wh, .h = wh }, color);
        //drawSquare((x + @as(u32, @intCast(bi))) * offset, y * offset, color, offset);
    }
}

//todo remove
fn drawSquare(x: u32, y: u32, color: u32, len: u32) void {
    for (y..y + len) |yi| {
        for (x..x + len) |xi| {
            drawPixel(color, @intCast(xi), @intCast(yi));
        }
    }
}

//TODO: remove this
pub fn inspectMemory() void {
    for (chip.ram[0xf00..], 0..) |byte, i| {
        if (i % 8 == 0) print("\n", .{});
        for (0..8) |bi| {
            const bit: u8 = byte & (@as(u8, 0x80) >> @as(u3, @intCast(bi)));
            print("{s}", .{if (bit > 0) "█" else " "});
        }
    }
}
