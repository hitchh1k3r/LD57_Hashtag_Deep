package main

import "base:runtime"

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:sys/wasm/js"

import wgl "vendor:wasm/WebGL"

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

generator_seed : i64
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
  R,
  Up,
  Down,
  Left,
  Right,
}

upgrades : Upgrades
Upgrades :: bit_set[Upgrade]
Upgrade :: enum {
  Walking_Staff,
  Mortar,
  Vision_Tube,
  Spy_Glass,
  Iron_Lamp,
  Diamond_Lamp,
  Iron_Sword,
  Diamond_Sword,
  Wood_Mallet,
  Stone_Mallet,
  Iron_Mallet,
  Diamond_Mallet,
  Stone_Axe,
  Iron_Axe,
  Diamond_Axe,
  Stone_Shield,
  Iron_Shield,
  Diamond_Shield,
  Compass,
}
stats : struct {
  max_health : int,
  max_shields : int,
  max_energy : int,
  vision_range : int,
  vision_extra : int,
  vision_scale : f32,
  attack_damage : Damage,
  tree_harvest : Damage,
  stone_harvest : Damage,
}

reset_world :: proc() {
  upgrades = ~{}
  update_stats()
  stats.max_health = 6
  player = {}
  player.health = stats.max_health
  player.energy = stats.max_energy
  init_wizdom()
  generator_seed = transmute(i64)(rand.uint64())
  generate_room(0, false)
}

update_stats :: proc() {
  if .Diamond_Shield in upgrades {
    stats.max_shields = 6
  } else if .Iron_Shield in upgrades {
    stats.max_shields = 4
  } else if .Stone_Shield in upgrades {
    stats.max_shields = 2
  } else {
    stats.max_shields = 0
  }

  stats.max_energy = 12
  if .Walking_Staff in upgrades {
    stats.max_energy += 6
  }
  if .Mortar in upgrades {
    stats.max_energy += 6
  }

  if .Spy_Glass in upgrades {
    stats.vision_range = 50
    stats.vision_extra = 15
    stats.vision_scale = 13
  } else if .Vision_Tube in upgrades {
    stats.vision_range = 25
    stats.vision_extra = 10
    stats.vision_scale = 8
  } else {
    stats.vision_range = 15
    stats.vision_extra = 5
    stats.vision_scale = 5
  }

  if .Diamond_Sword in upgrades {
    stats.attack_damage = .One_Hit
  } else if .Iron_Sword in upgrades {
    stats.attack_damage = .Three_Hit
  } else {
    stats.attack_damage = .Five_Hit
  }

  if .Diamond_Axe in upgrades {
    stats.tree_harvest = .One_Hit
  } else if .Iron_Axe in upgrades {
    stats.tree_harvest = .Two_Hit
  } else if .Stone_Axe in upgrades {
    stats.tree_harvest = .Three_Hit
  } else {
    stats.tree_harvest = .Four_Hit
  }

  if .Diamond_Mallet in upgrades {
    stats.stone_harvest = .One_Hit
  } else if .Iron_Mallet in upgrades {
    stats.stone_harvest = .Two_Hit
  } else if .Stone_Mallet in upgrades {
    stats.stone_harvest = .Four_Hit
  } else if .Wood_Mallet in upgrades {
    stats.stone_harvest = .Six_Hit
  } else {
    stats.stone_harvest = .Eight_Hit
  }
}

main :: proc() {
  fmt.println("Initializing...")
  init_audio()
  init_graphics()
  reset_world()

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
          */
          case "KeyR":
            input.held += { .R }
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
          */
          case "KeyR":
            input.held -= { .R }
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
scroll_speed := f32(0.15)

DELTA_TIME :: 1./60.

app_defunct := false
@(export)
step :: proc(dt : f64) -> bool {
  free_all(context.temp_allocator)
  if app_defunct {
    return false
  }

  input.pressed = input.held - input._last
  input.released = input._last - input.held
  input._last = input.held

  if player.health <= 0 && .R in input.pressed {
    reset_world()
  }

  if on_screen_text == "" && player.health > 0 && has_clicked && has_focus {
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
          use_energy()
        case .Crate:
          validation += { .Action, .No_Move }
          player.pos = old_pos
          use_energy()
        case .Stone:
          validation += { .Action, .No_Move }
          player.pos = old_pos
          tile.fill = .None
          if tile.item == .None {
            tile.item = .Stone
          }
          use_energy()
        case .Ladder_Down:
          validation += { .No_Tick }
          generate_room(room.level+1, false)
        case .Ladder_Up:
          /*
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
                use_energy()
                entity.damage += stats.attack_damage
                entity.hit = 1
                zombie_call = max(15, zombie_call+5)
                if entity.damage == .One_Hit {
                  unordered_remove(&room.entities, idx)
                  idx -= 1
                }
            }
          }
        }
        player.dir = new_dir
        if tile.item != .None {
          player.held, tile.item = tile.item, player.held
        }
        update_room()
      }
    }
    scroll_speed = math.lerp(scroll_speed, 0.15, half_life_interp(0.25))
    camera_pos = math.lerp(camera_pos, cell_to_v2(player.pos), half_life_interp(scroll_speed))
  }

  set_camera(camera_pos, stats.vision_scale)
  draw_room()

  if player.energy_hit > 0 {
    draw_screen_sprite(.Solid, rect_screen(), tint = { 1, 1, 0, 0.5*player.energy_hit*player.energy_hit })
  }

  if player.shield_hit > 0 {
    draw_screen_sprite(.Solid, rect_screen(), tint = { 0.5, 0.5, 0.5, 0.5*player.shield_hit*player.shield_hit })
  }

  if player.hit > 0 {
    draw_screen_sprite(.Solid, rect_screen(), tint = { 1, 0, 0, 0.5*player.hit*player.hit })
  }

  // Screen Text:
    if player.health <= 0 {
      draw_screen_sprite(.Solid, rect_screen(), tint = { 0.25, 0, 0, 0.9 })
      set_camera(0, 1)
      draw_string("You Have Died", { 0, -0.1 })
      set_camera(0, 1.75)
      draw_string("Press 'r' to Restart", { 0, 0.225 }, color = C_GRAY)
    } else if on_screen_text != "" {
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
      for h in 0..<(stats.max_health+1)/2 {
        if health >= 2 {
          draw_screen_sprite(.UI_Heart_2, rect_cut_left(&hearts_rect, 48))
        } else if health >= 1 {
          draw_screen_sprite(.UI_Heart_1, rect_cut_left(&hearts_rect, 48))
        } else {
          draw_screen_sprite(.UI_Heart_0, rect_cut_left(&hearts_rect, 48))
        }
        health -= 2
      }
      shields := player.shields
      for h in 0..<(stats.max_shields+1)/2 {
        if shields >= 2 {
          draw_screen_sprite(.UI_Shield_2, rect_cut_left(&hearts_rect, 48))
        } else if shields >= 1 {
          draw_screen_sprite(.UI_Shield_1, rect_cut_left(&hearts_rect, 48))
        } else {
          draw_screen_sprite(.UI_Shield_0, rect_cut_left(&hearts_rect, 48))
        }
        shields -= 2
      }
      energy_rect := rect_cut_top(&hud_rect, 48)
      energy := player.energy
      for h in 0..<(stats.max_energy+2)/6 {
        if energy >= 6 {
          draw_screen_sprite(.UI_Bolt_3, rect_cut_left(&energy_rect, 48))
        } else if energy >= 5 {
          rect := rect_cut_left(&energy_rect, 48)
          draw_screen_sprite(.UI_Bolt_2, rect)
          draw_screen_sprite(.UI_Bolt_3, rect, { 1, 1, 1, 0.5 })
        } else if energy >= 4 {
          draw_screen_sprite(.UI_Bolt_2, rect_cut_left(&energy_rect, 48))
        } else if energy >= 3 {
          rect := rect_cut_left(&energy_rect, 48)
          draw_screen_sprite(.UI_Bolt_1, rect)
          draw_screen_sprite(.UI_Bolt_2, rect, { 1, 1, 1, 0.5 })
        } else if energy >= 2 {
          draw_screen_sprite(.UI_Bolt_1, rect_cut_left(&energy_rect, 48))
        } else if energy >= 1 {
          rect := rect_cut_left(&energy_rect, 48)
          draw_screen_sprite(.UI_Bolt_0, rect)
          draw_screen_sprite(.UI_Bolt_1, rect, { 1, 1, 1, 0.5 })
        } else {
          draw_screen_sprite(.UI_Bolt_0, rect_cut_left(&energy_rect, 48))
        }
        energy -= 6
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

damage_player :: proc(skip_shield : bool) {
  if skip_shield || player.shields <= 0 {
    player.health -= 1
    player.hit = 1
  } else {
    player.shields -= 1
    player.shield_hit = 1
  }
}

use_energy :: proc() {
  if player.energy <= 0 {
    damage_player(true)
  } else {
    player.energy -= 1
    if player.energy <= 0 {
      player.energy_hit = 1
    }
  }
}
