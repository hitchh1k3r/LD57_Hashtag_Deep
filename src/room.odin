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
  health : int,
  energy : int,
  total_health : int,
  total_energy : int,
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

GAME_SEED :: 4201020
room : Room

generate_room :: proc(level : int, start_at_exit : bool) {
  zombie_call = 0
  player.energy = player.total_energy
  screen_dismiss = true
  on_screen_text = get_wizdom()
  room.level = level
  rand.reset(u64(level))
  room.width = 8 + rand.int_max(32)
  room.height = 8 + rand.int_max(16)
  room.tiles = make([]Tile, room.width*room.height)
  room.entities = make([dynamic]Entity)
  idx := 0
  scale := 0.01
  for y in 0..<room.height {
    for x in 0..<room.width {
      tile := &room.tiles[idx]
      idx += 1

      mat_val := 0.5 + 0.5*noise.noise_2d(GAME_SEED + i64(room.level), scale*noise.Vec2{ f64(x), f64(y) })
      if mat_val < 0.1 {
        tile.floor = .Water
      } else if mat_val < 0.15 {
        tile.floor = .Sand
      } else if mat_val < 0.33 {
        tile.floor = .Dirt
      } else if mat_val < 0.5 {
        tile.floor = .Grass
      } else {
        tile.floor = .Stone
      }

      switch tile.floor {
        case .None, .Water, .Sand:
        case .Dirt:
          if mat_val*rand.float32() > 0.275 {
            tile.fill = .Tree
          }
          if rand.float32() > 0.995 {
            append_elem(&room.entities, Entity{ variant = EntityZombie {
                pos = { x, y },
              }})
          }
        case .Grass:
          if mat_val*rand.float32() > 0.35 {
            tile.fill = .Tree
          } else if mat_val*rand.float32() > 0.75 {
            tile.item = .Wood
          }
        case .Stone:
          if mat_val*rand.float32() > 0.5 {
            tile.fill = .Stone
            if mat_val*rand.float32() > 0.8 {
              tile.item = .Coal
            }
          } else if mat_val*rand.float32() > 0.75 {
            tile.item = .Stone
          }
      }
    }
  }
  player.pos = { rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  for room.tiles[cell_to_idx(player.pos)].floor == .Water {
    player.pos = { rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  }
  ladder_pos := Cell{ rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  for ladder_pos == player.pos ||
      room.tiles[cell_to_idx(ladder_pos)].floor == .Water
  {
    ladder_pos = Cell{ rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  }
  if level == 0 {
    room.tiles[cell_to_idx(player.pos)].fill = .None
  } else {
    room.tiles[cell_to_idx(player.pos)].fill = .Ladder_Up
  }
  room.tiles[cell_to_idx(ladder_pos)].fill = .Ladder_Down
  if start_at_exit {
    player.pos, ladder_pos = ladder_pos, player.pos
  }
  fill_vision(player.pos, { .Vision }, PLAYER_VISION, { .Known }, PLAYER_VISION+KNOWLEDGE_EXTRA)
  fill_vision(ladder_pos, { .Known }, 20)
  camera_pos = { f32(ladder_pos.x), f32(ladder_pos.y) }
}

cell_to_idx :: proc(cell : Cell) -> int {
  return (cell.y * room.width) + cell.x
}

update_room :: proc() {
  room.turn += 1
  for &tile in room.tiles {
    tile.flags -= { .Vision }
  }
  for &entity in room.entities {
    if zombie_call > 0 {
      zombie_call -= 1
    }
    switch &entity in entity.variant {
      case EntityZombie:
        update_zombie(&entity)
    }
  }
  fill_vision(player.pos, { .Vision }, PLAYER_VISION, { .Known }, PLAYER_VISION+KNOWLEDGE_EXTRA)
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
    if tile.fill != .None ||
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
    if dir.x < 0 {
      if _can_move_to(zombie.pos + { -1, 0 }) {
        zombie.pos += { -1, 0 }
        zombie.dir = .Left
      }
    } else if dir.x > 0 {
      if _can_move_to(zombie.pos + { 1, 0 }) {
        zombie.pos += { 1, 0 }
        zombie.dir = .Right
      }
    } else if dir.y < 0 {
      if _can_move_to(zombie.pos + {  0, -1 }) {
        zombie.pos += {  0, -1 }
        zombie.dir = .Up
      }
    } else if dir.y > 0 {
      if _can_move_to(zombie.pos + { 0,  1 }) {
        zombie.pos += { 0,  1 }
        zombie.dir = .Down
      }
    }
    if zombie.pos == player.pos {
      zombie.pos = old_pos
      player.health -= 1
      player.hit = 1
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
        overlay := Sprite.Solid
        switch tile.fill {
          case .None:
          case .Tree:
            draw_sprite(.Tree, tile_pos, { 0.5, 0.66 })
          case .Crate:
            draw_sprite(.Crate, tile_pos, { 0.5, 0.66 })
          case .Stone:
            switch tile.item {
              case .None, .Wood, .Stone:
                draw_sprite(.Wall, tile_pos, { 0.5, 0.75 })
              case .Coal:
                draw_sprite(.Wall_Sockets, tile_pos, { 0.5, 0.75 })
                draw_sprite(.Wall_Fillins, tile_pos, { 0.5, 0.75 }, { 0.3, 0.1, 0.5, 1 })
            }
          case .Ladder_Down:
            draw_sprite(.Ladder_Down, tile_pos, { 0.5, 0.66 })
          case .Ladder_Up:
            overlay = .Ladder_Up
        }
        switch tile.item {
          case .None:
          case .Wood:
            draw_sprite(.Item_Wood, tile_pos)
          case .Stone:
            draw_sprite(.Item_Stone, tile_pos)
          case .Coal:
            draw_sprite(.Item_Coal, tile_pos)
        }
        draw_entities({ x, y })
        if overlay != .Solid {
          // TODO (hitch) 2025-04-05 We don't have a correct pivot for overlays
          draw_sprite(overlay, tile_pos, { 0.5, 0.66 })
        }
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
          switch entity.held {
            case .None:
            case .Wood:
              draw_sprite(.Item_Wood, held_pos, { 0.5, 0.75 })
            case .Stone:
              draw_sprite(.Item_Stone, held_pos, { 0.5, 0.75 })
            case .Coal:
              draw_sprite(.Item_Coal, held_pos, { 0.5, 0.75 })
          }
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
    draw_sprite(sprites[player.dir], tile_pos, { 0.5, 0.75 }, tint = math.lerp(C_WHITE, C_RED, player.hit), flip_x = (player.dir == .Right))
    held_pos := tile_pos
    held_pos.y -= 0.875
    switch player.held {
      case .None:
      case .Wood:
        draw_sprite(.Item_Wood, held_pos, { 0.5, 0.75 })
      case .Stone:
        draw_sprite(.Item_Stone, held_pos, { 0.5, 0.75 })
      case .Coal:
        draw_sprite(.Item_Coal, held_pos, { 0.5, 0.75 })
    }
  }
}
