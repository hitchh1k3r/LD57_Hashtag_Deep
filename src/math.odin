package main

import "core:math"
import "core:math/linalg"

// Math Constants //////////////////////////////////////////////////////////////////////////////////

  PI :: math.PI
  TAU :: math.TAU

  RAD_PER_DEG :: linalg.RAD_PER_DEG
  DEG_PER_RAD :: linalg.DEG_PER_RAD

// Interpolation ///////////////////////////////////////////////////////////////////////////////////

  half_life_interp :: proc(half_life : f32, delta_time := DELTA_TIME) -> f32 {
    return 1 - math.pow(0.5, f32(delta_time) / half_life)
  }

  ease :: proc(t : f32, ease_in := true, ease_out := true) -> f32 {
    if ease_in && !ease_out {
      return t * t
    } else if ease_out && !ease_in {
      return 1 - ((1-t) * (1-t))
    } else if ease_in && ease_out {
      if t < 0.5 {
        return 2 * t * t
      } else {
        t := -2*t + 2
        return 1 - (t*t)/2
      }
    }
    return t
  }

// Vectors /////////////////////////////////////////////////////////////////////////////////////////

  V2 :: [2]f32
  V3 :: [3]f32
  V4 :: [4]f32

  V2_ZERO  :: V2{  0,  0 }
  V2_LEFT  :: V2{ -1,  0 }
  V2_RIGHT :: V2{  1,  0 }
  V2_DOWN  :: V2{  0, -1 }
  V2_UP    :: V2{  0,  1 }

  V3_ZERO     :: V3{  0,  0,  0 }
  V3_LEFT     :: V3{ -1,  0,  0 }
  V3_RIGHT    :: V3{  1,  0,  0 }
  V3_DOWN     :: V3{  0, -1,  0 }
  V3_UP       :: V3{  0,  1,  0 }
  V3_FORWARD  :: V3{  0,  0, -1 }
  V3_BACKWARD :: V3{  0,  0,  1 }

  v3 :: proc{ v3__x_yz, v3__xy_z }

    v3__x_yz :: proc(x : f32, yz : V2) -> V3 {
      return V3{ x, yz[0], yz[1] }
    }

    v3__xy_z :: proc(xy : V2, z : f32) -> V3 {
      return V3{ xy[0], xy[1], z }
    }

  v4 :: proc{ v4__xyz_w, v4__x_yzw, v4__xy_z_w, v4__x_yz_w, v4__x_y_zw, v4__xy_zw }

    v4__xyz_w :: proc(xyz : V3, w : f32) -> V4 {
      return V4{ xyz[0], xyz[1], xyz[2], w }
    }

    v4__x_yzw :: proc(x : f32, yzw : V3) -> V4 {
      return V4{ x, yzw[0], yzw[1], yzw[2] }
    }

    v4__xy_z_w :: proc(xy : V2, z : f32, w : f32) -> V4 {
      return V4{ xy[0], xy[1], z, w }
    }

    v4__x_yz_w :: proc(x : f32, yz : V2, w : f32) -> V4 {
      return V4{ x, yz[0], yz[1], w }
    }

    v4__x_y_zw :: proc(x : f32, y : f32, zw : V2) -> V4 {
      return V4{ x, y, zw[0], zw[1] }
    }

    v4__xy_zw :: proc(xy : V2, zw : V2) -> V4 {
      return V4{ xy[0], xy[1], zw[0], zw[1] }
    }

// Cell ////////////////////////////////////////////////////////////////////////////////////////////

  Cell :: [2]int

  cell_to_v2 :: proc(cell : Cell) -> V2 {
    return { f32(cell.x), f32(cell.y) }
  }

// Rectangles //////////////////////////////////////////////////////////////////////////////////////

  Rect :: struct {
    using _ : struct #raw_union {
      arr : [4]f32,
      using _ : struct {
        using _ : struct #raw_union {
          using _ : struct {
            x, y : f32,
          },
          pos : [2]f32,
        },
        using _ : struct #raw_union {
          using _ : struct {
            w, h : f32,
          },
          size : [2]f32,
        },
      },
    },
  }

  RECT_UNORM := Rect{ pos = 0, size = 1 }

  rect_contains :: proc(rect : Rect, pos : [2]f32) -> bool {
    pos := pos - rect.pos
    return pos.x >= 0 &&
           pos.y >= 0 &&
           pos.x <= rect.w &&
           pos.y <= rect.h
  }

  rect_center :: proc(rect : Rect, interp := [2]f32{ 0.5, 0.5 }) -> [2]f32 {
    return rect.pos + rect.size*interp
  }

  rect_aspect :: proc(rect : Rect) -> f32 {
    return rect.w / rect.h
  }

  rect_screen :: proc() -> Rect {
    return { pos = 0, size = { f32(display_size.x), f32(display_size.y) } }
  }

  rect_anchored :: proc(pos : [2]f32, size : [2]f32, pivot := [2]f32{ 0.5, 0.5 }) -> (rect : Rect) {
    rect.size = size
    rect.pos = pos - size*pivot
    return
  }

  rect_fit :: proc(container : Rect, aspect : f32, mode : enum{ Contain, Cover }, pivot := [2]f32{ 0.5, 0.5 }) -> (dst : Rect, src : Rect) {
    size := container.size
    switch mode {
      case .Contain:
        if rect_aspect(container) > aspect {
          size.x = size.y * aspect
        } else {
          size.y = size.x / aspect
        }
      case .Cover:
        if rect_aspect(container) > aspect {
          size.y = size.x / aspect
        } else {
          size.x = size.y * aspect
        }
    }

    origin := container.pos + container.size*pivot
    dst = rect_anchored(origin, size, pivot)

    container_max := container.pos + container.size
    src.pos = (container.pos-dst.pos) / dst.size
    src_max := (container_max-dst.pos) / dst.size
    src.size = src_max - src.pos
    return
  }

  rect_inset :: proc(rect : Rect, amount : f32) -> Rect {
    return Rect{ pos=(rect.pos+amount), size=(rect.size - 2*amount) }
  }

  rect_cut_left :: proc(parent : ^Rect, amount : f32) -> (child : Rect) {
    child = parent^
    child.w = amount
    parent.x += amount
    parent.w -= amount
    return
  }

  rect_cut_right :: proc(parent : ^Rect, amount : f32) -> (child : Rect) {
    child = parent^
    child.x += child.w-amount
    child.w = amount
    parent.w -= amount
    return
  }

  rect_cut_top :: proc(parent : ^Rect, amount : f32) -> (child : Rect) {
    child = parent^
    child.y += child.h-amount
    child.h = amount
    parent.h -= amount
    return
  }

  rect_cut_bottom :: proc(parent : ^Rect, amount : f32) -> (child : Rect) {
    child = parent^
    child.h = amount
    parent.y += amount
    parent.h -= amount
    return
  }
