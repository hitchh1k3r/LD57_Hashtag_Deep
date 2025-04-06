package main

import "base:runtime"

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import "core:sys/wasm/js"

import wgl "vendor:wasm/WebGL"

PLAYER_VISION :: 15
KNOWLEDGE_EXTRA :: 5
CAMERA_SCALE :: 5
PLAYER_SWORD :: Damage.Three_Hit

Damage :: enum u16 {
 One_Hit =  2520,
 Two_Hit =  1260,
 Three_Hit = 840,
 Four_Hit =  630,
 Five_Hit =  504,
 Six_Hit =   420,
 Seven_Hit = 360,
 Eight_Hit = 315,
 Nine_Hit =  280,
}

Direction :: enum {
  Down,
  Left,
  Right,
  Up,
}

Direction_cell :: [Direction]Cell {
  .Up =    {  0, -1 },
  .Left =  { -1,  0 },
  .Right = {  1,  0 },
  .Down =  {  0,  1 },
}

on_screen_text := ""
screen_dismiss := false
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
  init_wizdom()
  generate_room(0, false)
  player.total_health = 6
  player.total_energy = 6
  player.health = 6
  player.energy = 6

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
        if screen_dismiss {
          screen_dismiss = false
        }
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
      if !screen_dismiss && on_screen_text != "" {
        on_screen_text = ""
      }
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
      if on_screen_text != "" {
        on_screen_text = ""
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

player : EntityPlayer

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

  if on_screen_text == "" && has_clicked && has_focus {
    old_pos := player.pos
    new_dir := player.dir
    switch input.pressed & { .Up, .Left, .Right, .Down } {
      case { .Up }:
        player.pos += { 0, -1 }
        new_dir = .Up
      case { .Down }:
        player.pos += { 0, 1 }
        new_dir = .Down
      case { .Left }:
        player.pos += { -1, 0 }
        new_dir = .Left
      case { .Right }:
        player.pos += { 1, 0 }
        new_dir = .Right
    }
    if player.pos.x < 0 || player.pos.x >= room.width ||
       player.pos.y < 0 || player.pos.y >= room.height
    {
      player.pos = old_pos
    }
    if player.pos != old_pos {
      validation : bit_set[enum { Action, No_Move, No_Tick }]
      tile := &room.tiles[cell_to_idx(player.pos)]
      switch tile.floor {
        case .None, .Water:
          validation += { .No_Move }
        case .Dirt, .Grass, .Sand, .Stone:
          // nop
      }
      switch tile.fill {
        case .None:
          // nop
        case .Tree:
          validation += { .Action, .No_Move }
          tile.fill = .None
          tile.item = .Wood
          if player.energy <= 0 {
            player.health -= 1
            player.hit = 1
          } else {
            player.energy -= 1
          }
        case .Crate:
          validation += { .Action, .No_Move }
          player.pos = old_pos
          if player.energy <= 0 {
            player.health -= 1
            player.hit = 1
          } else {
            player.energy -= 1
          }
        case .Stone:
          validation += { .Action, .No_Move }
          player.pos = old_pos
          tile.fill = .None
          if tile.item == .None {
            tile.item = .Stone
          }
          if player.energy <= 0 {
            player.health -= 1
            player.hit = 1
          } else {
            player.energy -= 1
          }
        case .Ladder_Down:
          validation += { .No_Tick }
          delete(room.tiles)
          generate_room(room.level+1, false)
        case .Ladder_Up:
          /*
          delete(room.tiles)
          generate_room(room.level-1, true)
          */
      }
      if .No_Move in validation {
        player.pos = old_pos
        tile = &room.tiles[cell_to_idx(player.pos)]
      }
      if .No_Tick not_in validation && validation & { .No_Move, .Action } != { .No_Move } {
        for idx := 0; idx < len(room.entities); idx += 1 {
          if room.entities[idx].pos == player.pos {
            switch &entity in room.entities[idx].variant {
              case EntityZombie:
                player.pos = old_pos
                entity.damage += PLAYER_SWORD
                entity.hit = 1
                zombie_call += 5
                if entity.damage == .One_Hit {
                  unordered_remove(&room.entities, idx)
                  idx -= 1
                }
            }
          }
        }
        player.dir = new_dir
        switch tile.item {
          case .None:
          case .Wood, .Coal, .Stone:
            player.held, tile.item = tile.item, player.held
        }
        update_room()
      }
    }
    camera_pos = math.lerp(camera_pos, cell_to_v2(player.pos), half_life_interp(0.5))
  }

  set_camera(camera_pos, CAMERA_SCALE)
  draw_room()

  // Screen Text:
    if on_screen_text != "" {
      draw_screen_sprite(.Solid, rect_screen(), tint = { 0, 0, 0, 0.75 })
      set_camera(0, 2)
      text := on_screen_text
      line_count := strings.count(text, " ")
      y := -0.075*f32(line_count+1)
      for line in strings.split_lines_iterator(&text) {
        if text == "" {
          draw_string(line, { 0, y }, color = C_GRAY)
        } else {
          draw_string(line, { 0, y }, color = { 0.75, 0.75, 1.00, 1.00 })
        }
        y += 0.3
      }
      y += 0.3
      draw_string("Click to continue...", { 0, y })
    }

  // HUD:
    {
      hud_rect := rect_screen()
      hearts_rect := rect_cut_top(&hud_rect, 48)
      health := player.health
      for h in 0..<(player.total_health+1)/2 {
        if health >= 2 {
          draw_screen_sprite(.UI_Heart_2, rect_cut_left(&hearts_rect, 48))
        } else if health >= 1 {
          draw_screen_sprite(.UI_Heart_1, rect_cut_left(&hearts_rect, 48))
        } else {
          draw_screen_sprite(.UI_Heart_0, rect_cut_left(&hearts_rect, 48))
        }
        health -= 2
      }
      energy_rect := rect_cut_top(&hud_rect, 48)
      energy := player.energy
      for h in 0..<(player.total_energy+2)/3 {
        if energy >= 3 {
          draw_screen_sprite(.UI_Bolt_3, rect_cut_left(&energy_rect, 48))
        } else if energy >= 2 {
          draw_screen_sprite(.UI_Bolt_2, rect_cut_left(&energy_rect, 48))
        } else if energy >= 1 {
          draw_screen_sprite(.UI_Bolt_1, rect_cut_left(&energy_rect, 48))
        } else {
          draw_screen_sprite(.UI_Bolt_0, rect_cut_left(&energy_rect, 48))
        }
        energy -= 3
      }
    }

  // Focus Nag:
    if on_screen_text == "" && (!has_clicked || !has_focus) {
      draw_screen_sprite(.Solid, rect_screen(), tint = { 0, 0, 0, 0.75 })
      set_camera(0, 1)
      draw_string("Click to Play!", { 0, 0 })
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
