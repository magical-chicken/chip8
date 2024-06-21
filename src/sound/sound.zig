const print = @import("std").debug.print;
const sdl_mixer = @cImport({
    @cInclude("/usr/include/SDL2/SDL_mixer.h");
});

const MixChunk = sdl_mixer.Mix_Chunk;
var sound: *MixChunk = undefined;

pub fn initSound() !void {
    const result = sdl_mixer.Mix_OpenAudio(44100, sdl_mixer.MIX_DEFAULT_FORMAT, 2, 2046); //look for the size
    if (result < 0) {
        print("error initializing sound: {s}\n", .{sdl_mixer.Mix_GetError()});
    }
    if (sdl_mixer.Mix_LoadWAV("sound/effects/beep.wav")) |file| {
        sound = file;
    } else print("error initializing sound: {s}\n", .{sdl_mixer.Mix_GetError()});
}

pub fn freeSoundChunks() void {
    sdl_mixer.Mix_FreeChunk(sound);
    sdl_mixer.Mix_Quit();
}

pub fn beep() void {
    _ = sdl_mixer.Mix_PlayChannel(-1, sound, 0);
}
