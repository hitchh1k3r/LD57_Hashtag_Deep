package main

import "base:runtime"

import "core:fmt"
import "core:math"
import "core:os"
import "core:sys/wasm/js"

import wgl "vendor:wasm/WebGL"

has_clicked := false
has_focus := false
display_size : [2]i32
input : struct {
  held : Inputs,
  pressed : Inputs,
  released : Inputs,
  _last : Inputs,
}
Inputs :: bit_set[Input]
Input :: enum {
  Up,
  Down,
  Left,
  Right,
}

main :: proc() {
  fmt.println("Initializing...")
  init_audio()
  init_graphics()
  generate_room()

  // Event Handlers
    resize_canvas :: proc() {
      window_rect := js.get_bounding_client_rect("canvas")
      display_size.x = i32(window_rect.width)
      display_size.y = i32(window_rect.height)
      js.set_element_key_f64("canvas", "width", f64(display_size.x))
      js.set_element_key_f64("canvas", "height", f64(display_size.y))
    }

    js.add_window_event_listener(.Resize, nil, proc(e : js.Event) {
      resize_canvas()
    })
    resize_canvas()

    js.add_window_event_listener(.Key_Down, nil, proc(e : js.Event) {
      if !e.data.key.repeat {
        switch e.data.key.code {
          /*
          case "Enter":
            raw_input.key_enter = true
          case "KeyW":
            raw_input.key_w = true
          case "KeyA":
            raw_input.key_a = true
          case "KeyS":
            raw_input.key_s = true
          case "KeyD":
            raw_input.key_d = true
          case "KeyZ":
            raw_input.key_z = true
          case "KeyQ":
            raw_input.key_q = true
          case "KeyH":
            raw_input.key_h = true
          case "KeyT":
            raw_input.key_t = true
          case "KeyG":
            raw_input.key_g = true
          case "KeyX":
            raw_input.key_x = true
          case "KeyC":
            raw_input.key_c = true
          case "KeyR":
            raw_input.key_r = true
          */
          case "ArrowUp":
            input.held += { .Up }
          case "ArrowLeft":
            input.held += { .Left }
          case "ArrowDown":
            input.held += { .Down }
          case "ArrowRight":
            input.held += { .Right }
        }
      }
      // js.event_prevent_default()
    })
    js.add_window_event_listener(.Key_Up, nil, proc(e : js.Event) {
      switch e.data.key.code {
          /*
          case "Enter":
            raw_input.key_enter = true
          case "KeyW":
            raw_input.key_w = true
          case "KeyA":
            raw_input.key_a = true
          case "KeyS":
            raw_input.key_s = true
          case "KeyD":
            raw_input.key_d = true
          case "KeyZ":
            raw_input.key_z = true
          case "KeyQ":
            raw_input.key_q = true
          case "KeyH":
            raw_input.key_h = true
          case "KeyT":
            raw_input.key_t = true
          case "KeyG":
            raw_input.key_g = true
          case "KeyX":
            raw_input.key_x = true
          case "KeyC":
            raw_input.key_c = true
          case "KeyR":
            raw_input.key_r = true
          */
          case "ArrowUp":
            input.held -= { .Up }
          case "ArrowLeft":
            input.held -= { .Left }
          case "ArrowDown":
            input.held -= { .Down }
          case "ArrowRight":
            input.held -= { .Right }
      }
      // js.event_prevent_default()
    })
    js.add_window_event_listener(.Touch_Start, nil, proc(e : js.Event) {
      /*
      if ready_for_touch {
        raw_input.touch_start = true
        show_touch_input = true
      }
      */
    })
    js.add_window_event_listener(.Pointer_Down, nil, proc(e : js.Event) {
      /*
      if show_touch_input {
        SCREEN_TOP :: 0.0
        SCREEN_BOTTOM :: 16.0 * game.ROOM_HEIGHT
        SCREEN_LEFT :: 0.0
        SCREEN_RIGHT :: 16.0 * game.ROOM_WIDTH

        pos := [2]f64{ f64(e.mouse.client.x), f64(e.mouse.client.y) }
        pos -= { canvas_rect.x, canvas_rect.y }
        pos /= { canvas_rect.width, canvas_rect.height }
        pos *= { 16*game.ROOM_WIDTH, 16*game.ROOM_HEIGHT }

        check_button :: proc(pos : [2]f64, center : [2]f64, radius : f64) -> bool {
          return abs(pos.x-center.x) + abs(pos.y-center.y) <= radius
        }

        if check_button(pos, { SCREEN_LEFT + 10, SCREEN_TOP + 10 }, 25) {
          raw_input.touch_undo = true
        }

        if check_button(pos, { SCREEN_RIGHT - 10, SCREEN_TOP + 10 }, 25) {
          raw_input.touch_redo = true
        }

        if check_button(pos, { SCREEN_RIGHT - (31+3.5), SCREEN_BOTTOM - ((31+3.5) + (3.5+15.5+5)) }, 20) {
          raw_input.touch_up = true
        }

        if check_button(pos, { SCREEN_RIGHT - ((31+3.5) + (3.5+15.5+5)), SCREEN_BOTTOM - (31+3.5) }, 20) {
          raw_input.touch_left = true
        }

        if check_button(pos, { SCREEN_RIGHT - (31+3.5), SCREEN_BOTTOM - ((31+3.5) - (3.5+15.5+5)) }, 20) {
          raw_input.touch_down = true
        }

        if check_button(pos, { SCREEN_RIGHT - ((31+3.5) - (3.5+15.5+5)), SCREEN_BOTTOM - (31+3.5) }, 20) {
          raw_input.touch_right = true
        }
      }
      */
      if !has_clicked {
        has_clicked = true
        has_focus = true
        music := load_sound("Echoes of the Deep.mp3", true)
        play_sound(music)
      }
    })
    js.add_window_event_listener(.Context_Menu, nil, proc(e : js.Event) {
      // js.event_prevent_default()
    })
    js.add_window_event_listener(.Focus, nil, proc(e : js.Event) {
      has_focus = true
    })
    js.add_window_event_listener(.Blur, nil, proc(e : js.Event) {
      has_focus = false
    })

  fmt.println("Starting...")
}

player : struct {
  pos : Cell,
}

camera_pos : V2

DELTA_TIME :: 1./60.

app_defunct := false
@(export)
step :: proc(dt : f64) -> bool {
  if app_defunct {
    return false
  }

  input.pressed = input.held - input._last
  input.released = input._last - input.held
  input._last = input.held

  old_pos := player.pos
  switch input.pressed & { .Up, .Left, .Right, .Down } {
    case { .Up }:
      player.pos += { 0, -1 }
    case { .Down }:
      player.pos += { 0, 1 }
    case { .Left }:
      player.pos += { -1, 0 }
    case { .Right }:
      player.pos += { 1, 0 }
  }
  if player.pos.x < 0 || player.pos.x >= room.width ||
     player.pos.y < 0 || player.pos.y >= room.height
  {
    player.pos = old_pos
  }
  switch room.tiles[cell_to_idx(player.pos)] {
    case .Floor, .Up_Ladder:
    case .Ladder:
      delete(room.tiles)
      delete(room.tile_flags)
      generate_room()
    case .Wall:
      player.pos = old_pos
  }

  camera_pos = math.lerp(camera_pos, cell_to_v2(player.pos), half_life_interp(0.1))
  set_camera(camera_pos, 8)
  update_room()
  draw_room()

  if !has_clicked || !has_focus {
    set_camera(0, 0.1)
    draw_sprite(.Solid, { 0, 0 }, tint = { 0, 0, 0, 0.75 })
    set_camera(0, 5)
    draw_sprite(.Click_To_Play, { 0, 0 })
  }

  wgl.ClearColor(0.1, 0, 0.1, 1)
  render()

  return true
}

crash :: proc(msg : string) -> ! {
  js.evaluate(fmt.tprintf("document.body.innerHTML = '%v';", msg))
  app_defunct = true
  os.exit(1)
}
