package main

import "core:math/rand"

Room :: struct {
  tile_flags : []TileFlags,
  tiles : []Tile,
  width : int,
  height : int,
}

Tile :: enum {
  Floor,
  Wall,
  Up_Ladder,
  Ladder,
}

TileFlags :: bit_set[TileFlag; u8]
TileFlag :: enum {
  Known,
  Vision,
  Light,
}

room : Room

generate_room :: proc() {
  room.width = 8 + rand.int_max(32)
  room.height = 8 + rand.int_max(16)
  room.tiles = make([]Tile, room.width*room.height)
  room.tile_flags = make([]TileFlags, room.width*room.height)
  player.pos = { rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  for &t in room.tiles {
    if rand.int_max(100) < 10 {
      t = .Wall
    }
  }
  ladder_pos := Cell{ rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  for ladder_pos == player.pos {
    ladder_pos = Cell{ rand.int_max(room.width-2)+1, rand.int_max(room.height-2)+1 }
  }
  room.tiles[cell_to_idx(player.pos)] = .Up_Ladder
  room.tiles[cell_to_idx(ladder_pos)] = .Ladder
  fill_vision(player.pos, { .Vision, .Known }, 5)
}

cell_to_idx :: proc(cell : Cell) -> int {
  return (cell.y * room.width) + cell.x
}

update_room :: proc() {
  for &s in room.tile_flags {
    s -= { .Vision }
  }
  fill_vision(player.pos, { .Vision, .Known }, 5)
}

fill_vision :: proc(source : Cell, add_flags : TileFlags, radius : int) {
  _fill_vision(source, {  0, -1 }, { -1,  0 }, {  1,  0 }, add_flags, radius)
  _fill_vision(source, {  0,  1 }, {  1,  0 }, { -1,  0 }, add_flags, radius)
  _fill_vision(source, { -1,  0 }, {  0,  1 }, {  0, -1 }, add_flags, radius)
  _fill_vision(source, {  1,  0 }, {  0, -1 }, {  0,  1 }, add_flags, radius)
  _fill_vision :: proc(start : Cell, dir : Cell, left_dir : Cell, right_dir : Cell, add_flags : TileFlags, radius : int) {
    cell := start
    max_left := max(int)
    max_right := max(int)
    range := radius
    look_dir:
    for range >= 0 &&
        cell.x >= 0 && cell.x < room.width &&
        cell.y >= 0 && cell.y < room.height
    {
      range -= 1
      idx := cell_to_idx(cell)
      room.tile_flags[idx] += add_flags
      switch room.tiles[idx] {
        case .Floor, .Ladder, .Up_Ladder:
        case .Wall:
          break look_dir
      }
      cell += dir

      left_range := range
      left := cell + left_dir
      left_dist := 0
      look_left:
      for left_range >= 0 && left_dist <= max_left &&
          left.x >= 0 && left.x < room.width &&
          left.y >= 0 && left.y < room.height
      {
        left_range -= 1
        defer {
          left += left_dir
          left_dist += 1
        }
        idx := cell_to_idx(left)
        room.tile_flags[idx] += add_flags
        switch room.tiles[idx] {
          case .Floor, .Ladder, .Up_Ladder:
          case .Wall:
            max_left = left_dist
            break look_left
        }
      }

      right_range := range
      right := cell + right_dir
      right_dist := 0
      look_right:
      for right_range >= 0 && right_dist <= max_right &&
          right.x >= 0 && right.x < room.width &&
          right.y >= 0 && right.y < room.height
      {
        right_range -= 1
        defer {
          right += right_dir
          right_dist += 1
        }
        idx := cell_to_idx(right)
        room.tile_flags[idx] += add_flags
        switch room.tiles[idx] {
          case .Floor, .Ladder, .Up_Ladder:
          case .Wall:
            max_right = right_dist
            break look_right
        }
      }
    }
  }
}


draw_room :: proc() {
  i := 0
  row_pos : V2
  for y in 0..<room.height {
    defer row_pos.y += 1
    tile_pos := row_pos
    for x in 0..<room.width {
      defer tile_pos.x += 1
      defer i += 1
      player_cell := (player.pos == { x, y })
      overlay := Sprite.Solid
      switch room.tiles[i] {
        case .Floor:
          if room.tile_flags[i] & { .Vision, .Light } != {} {
            draw_sprite(.Floor, tile_pos, { 0.5, 0.75 })
          } else if .Known in room.tile_flags[i] && !player_cell {
            draw_sprite(.Glyph_Floor, tile_pos, { 0.5, 0.75 })
          }
        case .Up_Ladder:
          if room.tile_flags[i] & { .Vision, .Light } != {} {
            draw_sprite(.Floor, tile_pos, { 0.5, 0.75 })
            overlay = .Up_Ladder
          } else if !player_cell {
            draw_sprite(.Glyph_Floor, tile_pos, { 0.5, 0.75 })
          }
        case .Ladder:
          if room.tile_flags[i] & { .Vision, .Light } != {} {
            draw_sprite(.Floor, tile_pos, { 0.5, 0.75 })
            draw_sprite(.Ladder, tile_pos, { 0.5, 0.75 })
          } else if !player_cell {
            draw_sprite(.Glyph_Ladder, tile_pos, { 0.5, 0.75 })
          }
        case .Wall:
          if room.tile_flags[i] & { .Vision, .Light } != {} {
            draw_sprite(.Wall, tile_pos, { 0.5, 0.75 })
          } else if .Known in room.tile_flags[i] && !player_cell {
            draw_sprite(.Glyph_Wall, tile_pos, { 0.5, 0.75 })
          }
      }
      if player_cell {
        if room.tile_flags[i] & { .Vision, .Light } != {} {
          draw_sprite(.Player_Down, tile_pos, { 0.5, 0.75 })
        } else if .Known in room.tile_flags[i] {
          draw_sprite(.Glyph_Player, tile_pos, { 0.5, 0.75 })
        }
      }
      if overlay != .Solid {
        draw_sprite(overlay, tile_pos, { 0.5, 0.75 })
      }
    }
  }
}
