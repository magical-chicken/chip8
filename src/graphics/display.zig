const print = @import("std").debug.print;
const chip = @import("../chip8.zig").chip;
const sdl = @cImport({
    @cInclude("/usr/include/SDL2/SDL.h");
});

const offset: u32 = 10;
const display_w: u32 = 64 * offset;
const display_h: u32 = 32 * offset;
const foreground_color: u32 = 0xffA91d3a;
const background_color: u32 = 0xff151515;

var buffer: [display_w * display_h]u32 = .{background_color} ** (display_w * display_h);

const Window = sdl.SDL_Window;
const Renderer = sdl.SDL_Renderer;
const Texture = sdl.SDL_Texture;

var wind: *Window = undefined;
var rend: *Renderer = undefined;
var texture: *Texture = undefined;

const Color = struct { r: u8, g: u8, b: u8, a: u8 };
const Rect = sdl.SDL_Rect;

pub fn initGraphics() void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);
    wind = sdl.SDL_CreateWindow("chip8-VM", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, @as(c_int, display_w), @as(c_int, display_h), sdl.SDL_WINDOW_SHOWN | sdl.SDL_WINDOW_RESIZABLE).?;
    rend = sdl.SDL_CreateRenderer(wind, @as(c_int, -1), sdl.SDL_RENDERER_ACCELERATED).?;

    texture = sdl.SDL_CreateTexture(rend, sdl.SDL_PIXELFORMAT_ARGB8888, sdl.SDL_TEXTUREACCESS_STREAMING, @as(c_int, display_w), @as(c_int, display_h)).?;
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
    sdl.SDL_DestroyTexture(texture);
    sdl.SDL_DestroyRenderer(rend);
    sdl.SDL_DestroyWindow(wind);
    sdl.SDL_Quit();
}

pub fn delay(t: u32) void {
    sdl.SDL_Delay(t);
}

pub fn render() void {
    var y: u32 = 0;
    var x: u32 = 0;

    while (y < 31) : (x += 1) {
        if (x != 0 and x % 8 == 0) {
            x = 0;
            y += 1;
        }

        mapPixelAt(chip.ram[(y * 8) + x + 0x0f00], x * 8, y);
    }

    _ = sdl.SDL_UpdateTexture(texture, null, &buffer, display_w * @sizeOf(u32));
    _ = sdl.SDL_RenderClear(rend);
    _ = sdl.SDL_RenderCopy(rend, texture, null, null);
    sdl.SDL_RenderPresent(rend);
}

fn drawPixel(color: u32, x: u32, y: u32) void {
    buffer[(y * display_w) + x] = color;
}

fn mapPixelAt(byte: u8, x: u32, y: u32) void {
    for (0..8) |bi| {
        const bit: u8 = byte & (@as(u8, 0x80) >> @as(u3, @intCast(bi)));
        const color: u32 = if (bit > 0) foreground_color else background_color;

        //        const rx: c_int = @intCast((x + @as(u32, @intCast(bi))) * offset);
        //        const ry: c_int = @intCast(y * offset);
        //        const wh: c_int = @intCast(offset);
        //        if (rx != x or y != ry) print("we have a problem here!\n", .{});
        //        drawRect(.{ .x = rx, .y = ry, .w = wh, .h = wh }, color);
        drawSquare((x + @as(u32, @intCast(bi))) * offset, y * offset, color, offset);
    }
}

fn drawSquare(x: u32, y: u32, color: u32, len: u32) void {
    for (y..y + len) |yi| {
        for (x..x + len) |xi| {
            drawPixel(color, @intCast(xi), @intCast(yi));
        }
    }
}

//TODO: remove this
fn inspectMemory() void {
    for (chip.ram[0xf00..], 0..) |byte, i| {
        if (i % 8 == 0) print("\n", .{});
        for (0..8) |bi| {
            const bit: u8 = byte & (@as(u8, 0x80) >> @as(u3, @intCast(bi)));
            print("{s}", .{if (bit > 0) "█" else " "});
        }
    }
}
