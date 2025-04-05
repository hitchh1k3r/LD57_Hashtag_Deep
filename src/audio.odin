package main

AudioHandle :: distinct int

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
