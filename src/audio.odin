package main

AudioHandle :: distinct int

Sound :: enum {
  Attack,
  Hurt,
  Ladder,
  Pickup,
  Stone,
  Wood,
}

Sound_audio : [Sound]AudioHandle

init_sounds :: proc() {
  Sound_audio[.Attack] = make_sound(#load("../res/attack.mp3"), false)
  Sound_audio[.Hurt] = make_sound(#load("../res/hurt.mp3"), false)
  Sound_audio[.Ladder] = make_sound(#load("../res/ladder.mp3"), false)
  Sound_audio[.Pickup] = make_sound(#load("../res/pickup.mp3"), false)
  Sound_audio[.Stone] = make_sound(#load("../res/stone.mp3"), false)
  Sound_audio[.Wood] = make_sound(#load("../res/wood.mp3"), false)
}

foreign import game_js "game_js"
@(default_calling_convention="contextless")
foreign game_js {
  init_audio :: proc() ---
  load_sound :: proc(filename : string, is_looping : bool) -> AudioHandle ---
  make_sound :: proc(data : []u8, is_looping : bool) -> AudioHandle ---
  play_sound :: proc(id : AudioHandle) ---
  stop_sound :: proc(id : AudioHandle) ---
  free_sound :: proc(id : AudioHandle) ---
}
