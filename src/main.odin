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

high_score : int
score : int
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

cursed_axe : bool
cursed_mallet : bool
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
  upgrades = {}
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
    stats.vision_range = 40
    stats.vision_extra = 15
    stats.vision_scale = 12
  } else if .Vision_Tube in upgrades {
    stats.vision_range = 25
    stats.vision_extra = 10
    stats.vision_scale = 8
  } else {
    stats.vision_range = 15
    stats.vision_extra = 5
    stats.vision_scale = 5
  }
  if .Diamond_Lamp in upgrades {
    stats.vision_range += 20
    stats.vision_extra += 10
    stats.vision_scale += 4
  } else if .Iron_Lamp in upgrades {
    stats.vision_range += 10
    stats.vision_extra += 5
    stats.vision_scale += 2
  }
  if player.held == .Torch {
    stats.vision_range += 5
    stats.vision_extra += 5
    stats.vision_scale += 0.5
  }

  if .Diamond_Sword in upgrades {
    stats.attack_damage = .One_Hit
  } else if .Iron_Sword in upgrades {
    stats.attack_damage = .Three_Hit
  } else {
    stats.attack_damage = .Five_Hit
  }

  if .Diamond_Axe in upgrades || cursed_axe {
    stats.tree_harvest = .One_Hit
  } else if .Iron_Axe in upgrades {
    stats.tree_harvest = .Two_Hit
  } else if .Stone_Axe in upgrades {
    stats.tree_harvest = .Three_Hit
  } else {
    stats.tree_harvest = .Four_Hit
  }

  if .Diamond_Mallet in upgrades || cursed_mallet {
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
  high_score = get_highscore()
  init_audio()
  init_sounds()
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
      }
      switch e.data.key.code {
        case "KeyR":
          input.held += { .R }
        case "KeyW":
          input.held += { .Up }
        case "KeyZ":
          input.held += { .Up }
        case "ArrowUp":
          input.held += { .Up }
        case "KeyA":
          input.held += { .Left }
        case "KeyQ":
          input.held += { .Left }
        case "KeyH":
          input.held += { .Left }
        case "ArrowLeft":
          input.held += { .Left }
        case "KeyS":
          input.held += { .Down }
        case "KeyT":
          input.held += { .Down }
        case "ArrowDown":
          input.held += { .Down }
        case "KeyD":
          input.held += { .Right }
        case "KeyG":
          input.held += { .Right }
        case "ArrowRight":
          input.held += { .Right }
      }
      js.event_prevent_default()
    })
    js.add_window_event_listener(.Key_Up, nil, proc(e : js.Event) {
      if !screen_dismiss && on_screen_text != "" {
        on_screen_text = ""
      }
      switch e.data.key.code {
        case "KeyR":
          input.held -= { .R }
        case "KeyW":
          input.held -= { .Up }
        case "KeyZ":
          input.held -= { .Up }
        case "ArrowUp":
          input.held -= { .Up }
        case "KeyA":
          input.held -= { .Left }
        case "KeyQ":
          input.held -= { .Left }
        case "KeyH":
          input.held -= { .Left }
        case "ArrowLeft":
          input.held -= { .Left }
        case "KeyS":
          input.held -= { .Down }
        case "KeyT":
          input.held -= { .Down }
        case "ArrowDown":
          input.held -= { .Down }
        case "KeyD":
          input.held -= { .Right }
        case "KeyG":
          input.held -= { .Right }
        case "ArrowRight":
          input.held -= { .Right }
      }
      js.event_prevent_default()
    })
    js.add_window_event_listener(.Pointer_Down, nil, proc(e : js.Event) {
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
      js.event_prevent_default()
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

delta_time : f32

app_defunct := false
@(export)
step :: proc(dt : f64) -> bool {
  delta_time = f32(dt)
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
    if input.pressed & { .Up, .Left, .Right, .Down } != {} {
      player.move_animation = 0
    }
    if player.move_animation > 0 {
      player.move_animation -= 4*delta_time
    } else {
      switch input.held & { .Up, .Left, .Right, .Down } {
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
          play_sound(Sound_audio[.Wood])
          validation += { .Action, .No_Move }
          player.pos = old_pos
          use_energy()
          tile.damage += stats.tree_harvest
          tile.hit = 1
          if tile.damage >= .One_Hit {
            score += 50
            tile.fill = .None
            tile.item = tree_loot[rand.int_max(len(tree_loot))]
          }
        case .Crate:
          play_sound(Sound_audio[.Wood])
          validation += { .Action, .No_Move }
          player.pos = old_pos
          use_energy()
          tile.damage += stats.tree_harvest
          tile.hit = 1
          if tile.damage >= .One_Hit {
            score += 150
            tile.fill = .None
            if tile.item == .None {
              tile.item = crate_loot[rand.int_max(len(crate_loot))]
            }
          }
        case .Crafting:
          player.pos = old_pos
          if player.held == .Wood ||
             player.held == .Stone ||
             player.held == .Leather ||
             player.held == .Coal ||
             player.held == .Iron ||
             player.held == .Diamond
          {
            validation += { .Action, .No_Move }
            play_sound(Sound_audio[.Pickup])
            if tile.item != .None {
              use_energy()
              wood := false
              stone := false
              leather := false
              coal := false
              iron := false
              diamond := false
              #partial switch tile.item {
                case .Wood:    wood = true
                case .Stone:   stone = true
                case .Leather: leather = true
                case .Coal:    coal = true
                case .Iron:    iron = true
                case .Diamond: diamond = true
              }
              #partial switch player.held {
                case .Wood:    wood = true
                case .Stone:   stone = true
                case .Leather: leather = true
                case .Coal:    coal = true
                case .Iron:    iron = true
                case .Diamond: diamond = true
              }
              switch {
                case wood && leather:
                  tile.item = .Walking_Staff
                case stone && coal:
                  tile.item = .Mortar
                case coal && wood:
                  tile.item = .Torch
                case iron && coal:
                  tile.item = .Iron_Lamp
                case diamond && coal:
                  tile.item = .Diamond_Lamp
                case diamond && iron:
                  tile.item = .Diamond_Sword
                case iron && stone:
                  tile.item = .Iron_Mallet
                case diamond && stone:
                  tile.item = .Diamond_Mallet
                case stone && wood:
                  tile.item = .Stone_Axe
                case iron && wood:
                  tile.item = .Iron_Axe
                case diamond && wood:
                  tile.item = .Diamond_Axe
                case stone && leather:
                  tile.item = .Stone_Shield
                case iron && leather:
                  tile.item = .Iron_Shield
                case diamond && leather:
                  tile.item = .Diamond_Shield
                case coal && leather:
                  tile.item = .Compass
                case wood: // x2
                  tile.item = .Wood_Mallet
                case stone: // x2
                  tile.item = .Stone_Mallet
                case leather: // x2
                  tile.item = .Vision_Tube
                case coal: // x2
                  tile.item = .Smoke_Screen
                case iron: // x2
                  tile.item = .Iron_Sword
                case diamond: // x2
                  tile.item = .Spy_Glass
              }
              player.held = .None
            } else {
              tile.item = player.held
              player.held = .None
            }
          }
        case .Altar:
          player.pos = old_pos
          if player.held != .None && tile.item == .None {
            validation += { .Action, .No_Move }
            play_sound(Sound_audio[.Pickup])
            use_energy()
            spawn := Item.None
            zombies := 0
            switch player.held {
              case .None, .Apple, .Heartapple, .Orange, .Map, .Cursed_Axe, .Cursed_Mallet:
                // should not be able to hold...
              case .Wood:
                spawn = .Cursed_Axe
                zombies = 2
              case .Stone:
                spawn = .Cursed_Mallet
                zombies = 2
              case .Coal:
                spawn = .Orange
                zombies = 2
              case .Iron:
                spawn = .Heartapple
                zombies = 2
              case .Diamond:
                spawn = altar_loot[rand.int_max(len(altar_loot))]
                zombies = 4
              case .Leather:
                spawn = .Map
                zombies = 3

              case .Torch:
                spawn = .Smoke_Screen
                zombies = 2
              case .Smoke_Screen:
                spawn = .None
                zombies = 2

              case .Walking_Staff, .Mortar, .Vision_Tube, .Spy_Glass, .Iron_Lamp, .Diamond_Lamp, .Iron_Sword, .Diamond_Sword, .Wood_Mallet, .Stone_Mallet, .Iron_Mallet, .Diamond_Mallet, .Stone_Axe, .Iron_Axe, .Diamond_Axe, .Stone_Shield, .Iron_Shield, .Diamond_Shield, .Compass:
                spawn = altar_loot[rand.int_max(len(altar_loot))]
                zombies = 4
            }
            player.held = .None
            tile.item = spawn
            spawn_zombies:
            for _ in 0..<zombies {
              pos := player.pos + Cell{ rand.int_max(11)-5, rand.int_max(11)-5 }
              ttl := 10_000
              for pos.x < 0 || pos.y < 0 || pos.x >= room.width || pos.y >= room.height ||
                  pos == player.pos ||
                  room.tiles[cell_to_idx(pos)].fill != .None ||
                  !_can_zombie_occupy(pos)
              {
                pos = player.pos + Cell{ rand.int_max(11)-5, rand.int_max(11)-5 }
                ttl -= 1
                if ttl < 0 {
                  break spawn_zombies
                }
              }
              append_elem(&room.entities, Entity{ variant = EntityZombie {
                  pos = pos,
                }})
            }
          }
        case .Stone:
          play_sound(Sound_audio[.Stone])
          validation += { .Action, .No_Move }
          player.pos = old_pos
          use_energy()
          tile.damage += stats.stone_harvest
          tile.hit = 1
          if tile.damage >= .One_Hit {
            tile.fill = .None
            #partial switch tile.item {
              case:
                score += 50
                tile.item = .Stone
              case .Coal:
                score += 100
              case .Iron:
                score += 250
              case .Diamond:
                score += 500
            }
          }
        case .Ladder_Down:
          validation += { .No_Tick }
          score += 1000
          score += 5*player.energy
          play_sound(Sound_audio[.Ladder])
          generate_room(room.level+1, false)
          if score > high_score {
            high_score = score
            set_highscore(high_score)
          }
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
        player.last_pos = old_pos
        for idx := 0; idx < len(room.entities); idx += 1 {
          if room.entities[idx].pos == player.pos {
            switch &entity in room.entities[idx].variant {
              case EntityZombie:
                player.pos = old_pos
                tile = &room.tiles[cell_to_idx(player.pos)]
                use_energy()
                play_sound(Sound_audio[.Attack])
                entity.damage += stats.attack_damage
                entity.hit = 1
                zombie_call = max(15, zombie_call+5)
                if entity.damage >= .One_Hit {
                  room.tiles[cell_to_idx(entity.pos)].item = zombie_loot[rand.int_max(len(zombie_loot))]
                  score += 250
                  unordered_remove(&room.entities, idx)
                  idx -= 1
                }
            }
          }
        }
        player.dir = new_dir
        if tile.item != .None {
          play_sound(Sound_audio[.Pickup])
          switch {
            case tile.item == .Apple:
              player.health = stats.max_health
              tile.item = .None
            case tile.item == .Heartapple:
              if stats.max_health < 12 {
                stats.max_health += 2
              }
              player.health = stats.max_health
              tile.item = .None
            case tile.item == .Orange:
              player.energy = stats.max_energy
              tile.item = .None
            case tile.item == .Map:
              reveal_exit()
              tile.item = .None
            case tile.item == .Compass && .Compass not_in upgrades:
              reveal_exit()
              upgrades += { .Compass }
              tile.item = .None
            case tile.item == .Walking_Staff && .Walking_Staff not_in upgrades:
              upgrades += { .Walking_Staff }
              tile.item = .None
            case tile.item == .Mortar && .Mortar not_in upgrades:
              upgrades += { .Mortar }
              tile.item = .None
            case tile.item == .Vision_Tube && .Vision_Tube not_in upgrades:
              upgrades += { .Vision_Tube }
              tile.item = .None
            case tile.item == .Spy_Glass && .Spy_Glass not_in upgrades:
              upgrades += { .Spy_Glass }
              tile.item = .None
            case tile.item == .Iron_Lamp && .Iron_Lamp not_in upgrades:
              upgrades += { .Iron_Lamp }
              tile.item = .None
            case tile.item == .Diamond_Lamp && .Diamond_Lamp not_in upgrades:
              upgrades += { .Diamond_Lamp }
              tile.item = .None

            case tile.item == .Iron_Sword && upgrades & { .Iron_Sword, .Diamond_Sword } == {}:
              upgrades += { .Iron_Sword }
              tile.item = .None
            case tile.item == .Diamond_Sword && upgrades & { .Diamond_Sword } == {}:
              upgrades += { .Diamond_Sword }
              tile.item = .None

            case tile.item == .Stone_Shield && upgrades & { .Stone_Shield, .Iron_Shield, .Diamond_Shield } == {}:
              upgrades += { .Stone_Shield }
              tile.item = .None
            case tile.item == .Iron_Shield && upgrades & { .Iron_Shield, .Diamond_Shield } == {}:
              upgrades += { .Iron_Shield }
              tile.item = .None
            case tile.item == .Diamond_Shield && upgrades & { .Diamond_Shield } == {}:
              upgrades += { .Diamond_Shield }
              tile.item = .None

            case tile.item == .Stone_Axe && upgrades & { .Stone_Axe, .Iron_Axe, .Diamond_Axe } == {}:
              upgrades += { .Stone_Axe }
              tile.item = .None
            case tile.item == .Iron_Axe && upgrades & { .Iron_Axe, .Diamond_Axe } == {}:
              upgrades += { .Iron_Axe }
              tile.item = .None
            case tile.item == .Diamond_Axe && upgrades & { .Diamond_Axe } == {}:
              upgrades += { .Diamond_Axe }
              tile.item = .None

            case tile.item == .Wood_Mallet && upgrades & { .Wood_Mallet, .Stone_Mallet, .Iron_Mallet, .Diamond_Mallet } == {}:
              upgrades += { .Wood_Mallet }
              tile.item = .None
            case tile.item == .Stone_Mallet && upgrades & { .Stone_Mallet, .Iron_Mallet, .Diamond_Mallet } == {}:
              upgrades += { .Stone_Mallet }
              tile.item = .None
            case tile.item == .Iron_Mallet && upgrades & { .Iron_Mallet, .Diamond_Mallet } == {}:
              upgrades += { .Iron_Mallet }
              tile.item = .None
            case tile.item == .Diamond_Mallet && upgrades & { .Diamond_Mallet } == {}:
              upgrades += { .Diamond_Mallet }
              tile.item = .None
            case tile.item == .Cursed_Axe:
              cursed_axe = true
              tile.item = .None
            case tile.item == .Cursed_Mallet:
              cursed_mallet = true
              tile.item = .None

            case:
              player.held, tile.item = tile.item, player.held
          }
        }
        player.move_animation = 1
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
      rect_cut_left(&hud_rect, 8)
      equipment_rect := rect_cut_left(&hud_rect, 72)
      rect_cut_top(&equipment_rect, 8)
      if .Diamond_Sword in upgrades {
        draw_screen_sprite(.Equipment_Sword_Diamond, rect_cut_top(&equipment_rect, 72))
      } else if .Iron_Sword in upgrades {
        draw_screen_sprite(.Equipment_Sword_Iron, rect_cut_top(&equipment_rect, 72))
      } else {
        draw_screen_sprite(.Equipment_Sword_Socket, rect_cut_top(&equipment_rect, 72))
      }
      if .Diamond_Shield in upgrades {
        draw_screen_sprite(.Equipment_Shield_Diamond, rect_cut_top(&equipment_rect, 72))
      } else if .Iron_Shield in upgrades {
        draw_screen_sprite(.Equipment_Shield_Iron, rect_cut_top(&equipment_rect, 72))
      } else if .Stone_Shield in upgrades {
        draw_screen_sprite(.Equipment_Shield_Stone, rect_cut_top(&equipment_rect, 72))
      } else {
        draw_screen_sprite(.Equipment_Shield_Socket, rect_cut_top(&equipment_rect, 72))
      }
      if cursed_axe {
        draw_screen_sprite(.Cursed_Axe, rect_cut_top(&equipment_rect, 72))
      } else if .Diamond_Axe in upgrades {
        draw_screen_sprite(.Equipment_Axe_Diamond, rect_cut_top(&equipment_rect, 72))
      } else if .Iron_Axe in upgrades {
        draw_screen_sprite(.Equipment_Axe_Iron, rect_cut_top(&equipment_rect, 72))
      } else if .Stone_Axe in upgrades {
        draw_screen_sprite(.Equipment_Axe_Stone, rect_cut_top(&equipment_rect, 72))
      } else {
        draw_screen_sprite(.Equipment_Axe_Socket, rect_cut_top(&equipment_rect, 72))
      }
      if cursed_mallet {
        draw_screen_sprite(.Cursed_Mallet, rect_cut_top(&equipment_rect, 72))
      } else if .Diamond_Mallet in upgrades {
        draw_screen_sprite(.Equipment_Mallet_Diamond, rect_cut_top(&equipment_rect, 72))
      } else if .Iron_Mallet in upgrades {
        draw_screen_sprite(.Equipment_Mallet_Iron, rect_cut_top(&equipment_rect, 72))
      } else if .Stone_Mallet in upgrades {
        draw_screen_sprite(.Equipment_Mallet_Stone, rect_cut_top(&equipment_rect, 72))
      } else if .Wood_Mallet in upgrades {
        draw_screen_sprite(.Equipment_Mallet_Wood, rect_cut_top(&equipment_rect, 72))
      } else {
        draw_screen_sprite(.Equipment_Mallet_Socket, rect_cut_top(&equipment_rect, 72))
      }
      if .Walking_Staff in upgrades {
        draw_screen_sprite(.Upgrade_Walking_Staff, rect_cut_top(&equipment_rect, 72))
      }
      if .Mortar in upgrades {
        draw_screen_sprite(.Upgrade_Mortar, rect_cut_top(&equipment_rect, 72))
      }
      if .Spy_Glass in upgrades {
        draw_screen_sprite(.Upgrade_Spy_Glass, rect_cut_top(&equipment_rect, 72))
      } else if .Vision_Tube in upgrades {
        draw_screen_sprite(.Upgrade_Vision_Tube, rect_cut_top(&equipment_rect, 72))
      }
      if .Diamond_Lamp in upgrades {
        draw_screen_sprite(.Upgrade_Diamond_Lamp, rect_cut_top(&equipment_rect, 72))
      } else if .Iron_Lamp in upgrades {
        draw_screen_sprite(.Upgrade_Iron_Lamp, rect_cut_top(&equipment_rect, 72))
      }
      if .Compass in upgrades {
        draw_screen_sprite(.Item_Compass, rect_cut_top(&equipment_rect, 72))
      }
      rect_cut_left(&hud_rect, 8)
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

      if player.health <= 0 {
        draw_screen_text(fmt.tprint(score), { f32(display_size.x)-40, f32(display_size.y)-40 }, scale = 15, pivot = { 1, 1 })
        draw_screen_text(fmt.tprint(high_score), { f32(display_size.x)-30, f32(display_size.y)-125 }, scale = 8, pivot = { 1, 1 }, color = (score > 0 && score == high_score) ? C_YELLOW : C_GRAY)
        draw_screen_text("highscore^", { f32(display_size.x)-60, f32(display_size.y)-190 }, scale = 8, pivot = { 1, 1 }, color = C_YELLOW)
      } else {
        draw_screen_text(fmt.tprint(score), { f32(display_size.x)-15, f32(display_size.y)-20 }, scale = 4, pivot = { 1, 1 })
        draw_screen_text(fmt.tprint(high_score), { f32(display_size.x)-15, f32(display_size.y)-50 }, scale = 3, pivot = { 1, 1 }, color = (score > 0 && score == high_score) ? C_YELLOW : C_GRAY)
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
  play_sound(Sound_audio[.Hurt])
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

foreign import game_js "game_js"
@(default_calling_convention="contextless")
foreign game_js {
  get_highscore :: proc() -> int ---
  set_highscore :: proc(score : int) ---
}
