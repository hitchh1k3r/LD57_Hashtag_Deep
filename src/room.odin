package main

import "core:math"
import "core:math/noise"
import "core:math/rand"

Room :: struct {
  level : int,
  turn : int,
  tiles : []Tile,
  width : int,
  height : int,
  ladder_pos : Cell,
  entities : [dynamic]Entity,
}

Entity :: struct #raw_union {
  using _ : struct {
    pos : Cell,
  },
  variant : union {
    EntityZombie,
  }
}
EntityPlayer :: struct {
  pos : Cell,
  dir : Direction,
  held : Item,
  hit : f32,
  energy_hit : f32,
  shield_hit : f32,
  health : int,
  shields : int,
  energy : int,
}
EntityZombie :: struct {
  pos : Cell,
  dir : Direction,
  held : Item,
  damage : Damage,
  hit : f32,
}

TileFloor :: enum {
  None,
  Grass,
  Dirt,
  Sand,
  Water,
  Stone,
}

TileFill :: enum {
  None,
  Tree,
  Crate,
  Stone,
  Ladder_Down,
  Ladder_Up,
}

Item :: enum {
  None,

  Wood,
  Stone,
  Coal,
  Iron,
  Diamond,

  Torch,
  Smoke_Screen,

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

Item_sprite := [Item]Sprite{
  .None = .None,

  .Wood = .Item_Wood,
  .Stone = .Item_Stone,
  .Coal = .Item_Coal,
  .Iron = .Item_Coal,
  .Diamond = .Item_Coal,

  .Torch = .Item_Coal,
  .Smoke_Screen = .Item_Coal,

  .Walking_Staff = .Item_Coal,
  .Mortar = .Item_Coal,
  .Vision_Tube = .Item_Coal,
  .Spy_Glass = .Item_Coal,
  .Iron_Lamp = .Item_Coal,
  .Diamond_Lamp = .Item_Coal,
  .Iron_Sword = .Item_Coal,
  .Diamond_Sword = .Item_Coal,
  .Wood_Mallet = .Item_Coal,
  .Stone_Mallet = .Item_Coal,
  .Iron_Mallet = .Item_Coal,
  .Diamond_Mallet = .Item_Coal,
  .Stone_Axe = .Item_Coal,
  .Iron_Axe = .Item_Coal,
  .Diamond_Axe = .Item_Coal,
  .Stone_Shield = .Item_Coal,
  .Iron_Shield = .Item_Coal,
  .Diamond_Shield = .Item_Coal,
  .Compass = .Item_Coal,
}

Tile :: struct {
  floor : TileFloor,
  fill : TileFill,
  item : Item,
  damage : int,
  flags : TileFlags,
}

TileFlags :: bit_set[TileFlag; u8]
TileFlag :: enum {
  Known,
  Vision,
  Light,
}

room : Room

generate_room :: proc(level : int, start_at_exit : bool) {
  if room.tiles != nil {
    delete(room.tiles)
  }
  zombie_call = 0
  player.shields = stats.max_shields
  player.energy = stats.max_energy
  screen_dismiss = true
  ok : bool
  if on_screen_text, ok = level_thoughts[level]; !ok {
    on_screen_text = get_wizdom()
  }
  room.level = level
  rand.reset(u64(level))
  room.width = 8 + level + rand.int_max(level+2)
  room.height = 8 + level + rand.int_max(level+2)
  min_exit_dist := min(room.width, room.height)-1
  room.tiles = make([]Tile, room.width*room.height)
  room.entities = make([dynamic]Entity)
  idx := 0
  for y in 0..<room.height {
    for x in 0..<room.width {
      tile := &room.tiles[idx]
      idx += 1

      ELEVATION_SCALE := 0.01
      DECORATION_SCALE := 0.075
      elevation := noise.noise_2d(generator_seed + i64(room.level), ELEVATION_SCALE*noise.Vec2{ f64(x), f64(y) })
      decoration := noise.noise_2d(generator_seed + 1000 + i64(room.level), DECORATION_SCALE*noise.Vec2{ f64(x), f64(y) })
      elevation = math.remap(elevation, -1, 1, 0.2 * 5/(f32(level)+5), 1 - 0.575 * 10/(f32(level)+10))
      decoration = math.remap(decoration, -1, 1, 0, 1)

      if elevation < 0.10 {
        tile.floor = .Water // [ 0.00, 0.10 ] 10
      } else if elevation < 0.15 {
        tile.floor = .Sand //  [ 0.10, 0.15 ]  5
      } else if elevation < 0.45 {
        tile.floor = .Grass // [ 0.15, 0.45 ] 30
      } else if elevation < 0.50 {
        tile.floor = .Dirt //  [ 0.45, 0.50 ]  5
      } else {
        tile.floor = .Stone // [ 0.50, 1.00 ] 50
      }

      switch tile.floor {
        case .None, .Water, .Sand:
        case .Dirt:
          if decoration*rand.float32() > 0.9 {
            append_elem(&room.entities, Entity{ variant = EntityZombie {
                pos = { x, y },
              }})
          }
        case .Grass:
          if decoration*rand.float32() > 0.6 {
            tile.fill = .Tree
          }
        case .Stone:
          if decoration*rand.float32() > 0.5 {
            tile.fill = .Stone
            if elevation*decoration*rand.float32() > 0.5 {
              tile.item = .Coal
            }
          } else if decoration*rand.float32() > 0.8 {
            append_elem(&room.entities, Entity{ variant = EntityZombie {
                pos = { x, y },
              }})
          }
      }
    }
  }
  player.pos = { rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  for room.tiles[cell_to_idx(player.pos)].floor == .Water {
    player.pos = { rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  }
  room.ladder_pos = Cell{ rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  ttl := 10_000
  dist :: proc(a, b : Cell) -> int {
    d := a - b
    return abs(d.x) + abs(d.y)
  }
  for dist(room.ladder_pos, player.pos) < min_exit_dist ||
      room.tiles[cell_to_idx(room.ladder_pos)].floor == .Water
  {
    room.ladder_pos = Cell{ rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
    ttl -= 1
    if ttl < 0 {
      break
    }
  }
  if level == 0 {
    room.tiles[cell_to_idx(player.pos)].fill = .None
  } else {
    room.tiles[cell_to_idx(player.pos)].fill = .Ladder_Up
  }
  room.tiles[cell_to_idx(room.ladder_pos)].fill = .Ladder_Down
  if start_at_exit {
    player.pos, room.ladder_pos = room.ladder_pos, player.pos
  }
  fill_vision(player.pos, { .Vision }, stats.vision_range, { .Known }, stats.vision_range+stats.vision_extra)
  camera_pos = { f32(player.pos.x), f32(player.pos.y) }
  if .Compass in upgrades {
    reveal_exit()
  }
}

reveal_exit :: proc() {
  fill_vision(room.ladder_pos, { .Known }, 20)
  camera_pos = { f32(room.ladder_pos.x), f32(room.ladder_pos.y) }
  scroll_speed = 5
}

cell_to_idx :: proc(cell : Cell) -> int {
  return (cell.y * room.width) + cell.x
}

update_room :: proc() {
  room.turn += 1
  for &tile in room.tiles {
    tile.flags -= { .Vision }
  }
  if zombie_call > 0 {
    zombie_call -= 1
  }
  for &entity in room.entities {
    switch &entity in entity.variant {
      case EntityZombie:
        update_zombie(&entity)
    }
  }
  update_stats()
  fill_vision(player.pos, { .Vision }, stats.vision_range, { .Known }, stats.vision_range+stats.vision_extra)
}

zombie_call : int
update_zombie :: proc(zombie : ^EntityZombie) {
  _can_move_to :: proc(pos : Cell) -> bool {
    if pos.x < 0 || pos.y < 0 ||
       pos.x >= room.width || pos.y >= room.height
    {
      return false
    }
    tile := room.tiles[cell_to_idx(pos)]
    if (tile.fill != .None && tile.fill != .Ladder_Down && tile.fill != .Ladder_Up) ||
       tile.floor == .None ||
       tile.floor == .Water
    {
      return false
    }
    for entity in room.entities {
      if entity.pos == pos {
        switch entity in entity.variant {
          case EntityZombie:
            return false
        }
      }
    }
    return true
  }

  move:
  if (room.turn % 2) == 0 {
    dir := player.pos - zombie.pos
    if zombie_call <= 0 {
      if abs(dir.x) + abs(dir.y) > 5 {
        break move
      }
    }
    old_pos := zombie.pos
    if dir.x < 0 && _can_move_to(zombie.pos + { -1, 0 }) {
      zombie.pos += { -1, 0 }
      zombie.dir = .Left
    } else if dir.x > 0 && _can_move_to(zombie.pos + { 1, 0 }) {
      zombie.pos += { 1, 0 }
      zombie.dir = .Right
    } else if dir.y < 0 && _can_move_to(zombie.pos + {  0, -1 }) {
      zombie.pos += {  0, -1 }
      zombie.dir = .Up
    } else if dir.y > 0 && _can_move_to(zombie.pos + { 0,  1 }) {
      zombie.pos += { 0,  1 }
      zombie.dir = .Down
    }
    if zombie.pos == player.pos {
      zombie.pos = old_pos
      damage_player(false)
    }

    tile := &room.tiles[cell_to_idx(zombie.pos)]
    if tile.item != .None {
      tile.item, zombie.held = zombie.held, tile.item
    }
  }
}

fill_vision :: proc(source : Cell, a_flags : TileFlags, a_radius : int, b_flags := TileFlags{}, b_radius := 0) {
  _fill_vision(source, {  0, -1 }, { -1,  0 }, {  1,  0 }, a_flags, a_radius, b_flags, b_radius)
  _fill_vision(source, {  0,  1 }, {  1,  0 }, { -1,  0 }, a_flags, a_radius, b_flags, b_radius)
  _fill_vision(source, { -1,  0 }, {  0,  1 }, {  0, -1 }, a_flags, a_radius, b_flags, b_radius)
  _fill_vision(source, {  1,  0 }, {  0, -1 }, {  0,  1 }, a_flags, a_radius, b_flags, b_radius)
  _blocks_vision :: proc(tile : Tile) -> int {
    switch tile.fill {
      case .None:
        return 5
      case .Tree:
        return 20
      case .Crate:
        return 10
      case .Stone:
        return 100
      case .Ladder_Down, .Ladder_Up:
        return 5
    }
    return max(int)
  }
  _fill_vision :: proc(start : Cell, dir : Cell, left_dir : Cell, right_dir : Cell, a_flags : TileFlags, a_radius : int, b_flags : TileFlags, b_radius : int) {
    cell := start
    max_left := max(int)
    max_right := max(int)
    a_range := a_radius
    b_range := b_radius
    for (a_range >= 0 || b_range >= 0) &&
        cell.x >= 0 && cell.x < room.width &&
        cell.y >= 0 && cell.y < room.height
    {
      idx := cell_to_idx(cell)
      tile := &room.tiles[idx]
      if a_range > 0 {
        tile.flags += a_flags
      }
      if b_range > 0 {
        tile.flags += b_flags
      }
      a_range -= _blocks_vision(tile^)
      b_range -= _blocks_vision(tile^)
      cell += dir

      left := cell + left_dir
      left_a_range := a_range
      left_b_range := b_range
      left_dist := 0
      for (left_a_range >= 0 || left_b_range >= 0) && left_dist <= max_left &&
          left.x >= 0 && left.x < room.width &&
          left.y >= 0 && left.y < room.height
      {
        defer {
          left += left_dir
          left_dist += 1
        }
        idx := cell_to_idx(left)
        tile := &room.tiles[idx]
        if left_a_range > 0 {
          tile.flags += a_flags
        }
        if left_b_range > 0 {
          tile.flags += b_flags
        }
        left_a_range -= _blocks_vision(tile^)
        left_b_range -= _blocks_vision(tile^)
      }

      right := cell + right_dir
      right_a_range := a_range
      right_b_range := b_range
      right_dist := 0
      for (right_a_range >= 0 || right_b_range >= 0) && right_dist <= max_right &&
          right.x >= 0 && right.x < room.width &&
          right.y >= 0 && right.y < room.height
      {
        defer {
          right += right_dir
          right_dist += 1
        }
        idx := cell_to_idx(right)
        tile := &room.tiles[idx]
        if right_a_range > 0 {
          tile.flags += a_flags
        }
        if right_b_range > 0 {
          tile.flags += b_flags
        }
        right_a_range -= _blocks_vision(tile^)
        right_b_range -= _blocks_vision(tile^)
      }
    }
  }
}

draw_room :: proc() {
  idx := 0
  row_pos : V2
  for y in 0..<room.height {
    defer row_pos.y += 1
    tile_pos := row_pos
    for x in 0..<room.width {
      defer tile_pos.x += 1
      defer idx += 1
      tile := room.tiles[idx]
      if tile.flags & { .Vision, .Light } != {} {
        switch tile.floor {
          case .None:
          case .Grass:
            draw_sprite(.Floor_Grass, tile_pos, { 0.5, 0.5 })
          case .Dirt:
            draw_sprite(.Floor_Dirt, tile_pos, { 0.5, 0.5 })
          case .Sand:
            draw_sprite(.Floor_Sand, tile_pos, { 0.5, 0.5 })
          case .Stone:
            draw_sprite(.Floor_Stone, tile_pos, { 0.5, 0.5 })
          case .Water:
            draw_sprite(.Floor_Water, tile_pos, { 0.5, 0.5 })
        }
        overlay := Sprite.None
        switch tile.fill {
          case .None:
            draw_sprite(Item_sprite[tile.item], tile_pos)
          case .Tree:
            draw_sprite(.Tree, tile_pos, { 0.5, 0.66 })
          case .Crate:
            draw_sprite(.Crate, tile_pos, { 0.5, 0.66 })
          case .Stone:
            #partial switch tile.item {
              case:
                draw_sprite(.Wall, tile_pos, { 0.5, 0.75 })
              case .Coal:
                draw_sprite(.Wall_Sockets, tile_pos, { 0.5, 0.75 })
                draw_sprite(.Wall_Fillins, tile_pos, { 0.5, 0.75 }, { 0.3, 0.1, 0.45, 1 })
              case .Iron:
                draw_sprite(.Wall_Sockets, tile_pos, { 0.5, 0.75 })
                draw_sprite(.Wall_Fillins, tile_pos, { 0.5, 0.75 }, { 0.5, 0.4, 0.2, 1 })
              case .Diamond:
                draw_sprite(.Wall_Sockets, tile_pos, { 0.5, 0.75 })
                draw_sprite(.Wall_Fillins, tile_pos, { 0.5, 0.75 }, { 0.5, 0.5, 0.75, 1 })
            }
          case .Ladder_Down:
            draw_sprite(.Ladder_Down, tile_pos, { 0.5, 0.66 })
          case .Ladder_Up:
            overlay = .Ladder_Up
        }
        draw_entities({ x, y })
        // TODO (hitch) 2025-04-05 We don't have a correct pivot for overlays
        draw_sprite(overlay, tile_pos, { 0.5, 0.66 })
      } else if tile.flags & { .Known } != {} {
        floor_glyph := Sprite.Glyph_Unknown
        switch tile.floor {
          case .None:
          case .Grass, .Dirt, .Sand, .Stone:
            floor_glyph = .Glyph_Floor
          case .Water:
            // TODO
            // floor_glyph = .Glyph_Water
        }
        switch tile.fill {
          case .None:
            draw_sprite(floor_glyph, tile_pos, { 0.5, 0.5 }, { 1, 1, 1, 0.25 })
          case .Tree:
            draw_sprite(.Glyph_Tree, tile_pos, { 0.5, 0.5 })
          case .Crate:
            draw_sprite(.Glyph_Crate, tile_pos, { 0.5, 0.5 })
          case .Stone:
            draw_sprite(.Glyph_Wall, tile_pos, { 0.5, 0.5 })
          case .Ladder_Down, .Ladder_Up:
            draw_sprite(.Glyph_Ladder, tile_pos, { 0.5, 0.5 })
        }
      } else {
        draw_sprite(.Glyph_Unknown, tile_pos, { 0.5, 0.5 }, { 1, 1, 1, 0.05 })
      }
    }
  }
}

draw_entities :: proc(pos : Cell) {
  tile_pos := V2{ f32(pos.x), f32(pos.y) }
  for &entity in room.entities {
    if entity.pos == pos {
      switch &entity in entity.variant {
        case EntityZombie:
          sprites := [Direction]Sprite {
            .Up = .Player_Up,
            .Left = .Player_Left,
            .Right = .Player_Left,
            .Down = .Player_Down,
          }
          if (room.turn % 2) == 1 {
            sprites = {
              .Up = .Player_Up_Hold,
              .Left = .Player_Left_Hold,
              .Right = .Player_Left_Hold,
              .Down = .Player_Down_Hold,
            }
          }
          if entity.hit > 0 {
            entity.hit -= 0.02
            if entity.hit < 0 {
              entity.hit = 0
            }
          }
          draw_sprite(sprites[entity.dir], tile_pos, { 0.5, 0.75 }, tint = math.lerp(C_GREEN, C_RED, entity.hit), flip_x = (entity.dir == .Right))
          held_pos := tile_pos
          held_pos.y -= 0.875
          draw_sprite(Item_sprite[entity.held], held_pos, { 0.5, 0.75 })
      }
    }
  }
  if player.pos == pos {
    sprites := [Direction]Sprite {
      .Up = .Player_Up,
      .Left = .Player_Left,
      .Right = .Player_Left,
      .Down = .Player_Down,
    }
    if player.held != .None {
      sprites = {
        .Up = .Player_Up_Hold,
        .Left = .Player_Left_Hold,
        .Right = .Player_Left_Hold,
        .Down = .Player_Down_Hold,
      }
    }
    if player.hit > 0 {
      player.hit -= 0.02
      if player.hit < 0 {
        player.hit = 0
      }
    }
    if player.shield_hit > 0 {
      player.shield_hit -= 0.02
      if player.shield_hit < 0 {
        player.shield_hit = 0
      }
    }
    if player.energy_hit > 0 {
      player.energy_hit -= 0.0075
      if player.energy_hit < 0 {
        player.energy_hit = 0
      }
    }
    draw_sprite(sprites[player.dir], tile_pos, { 0.5, 0.75 }, tint = math.lerp(math.lerp(math.lerp(C_WHITE, C_GRAY, player.shield_hit), C_YELLOW, player.energy_hit), C_RED, player.hit), flip_x = (player.dir == .Right))
    held_pos := tile_pos
    held_pos.y -= 0.875
    draw_sprite(Item_sprite[player.held], held_pos, { 0.5, 0.75 })
  }
}
