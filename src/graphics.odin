package main

import "core:fmt"
import "core:image/png"
import "core:math"
import "core:math/linalg/glsl"
import "core:sys/wasm/js"

import wgl "vendor:wasm/WebGL"

Sprite :: enum {
  None,
  Solid,

  Player_Left,
  Player_Left_Walk,
  Player_Down,
  Player_Down_Walk,
  Player_Up,
  Player_Up_Walk,
  Player_Left_Hold,
  Player_Left_Walk_Hold,
  Player_Down_Hold,
  Player_Down_Walk_Hold,
  Player_Up_Hold,
  Player_Up_Walk_Hold,

  Ladder_Down,
  Ladder_Up,
  Tree,
  Crafting,
  Crate,
  Altar,

  Glyph_Unknown,
  Glyph_Floor,
  Glyph_Ladder,
  Glyph_Wall,
  Glyph_Tree,
  Glyph_Crafting,
  Glyph_Item,
  Glyph_Crate,
  Glyph_Water,
  Glyph_Altar,

  Floor_Stone,
  Floor_Grass,
  Floor_Dirt,
  Floor_Sand,
  Floor_Water,

  Wall,
  Wall_Sockets,
  Wall_Fillins,

  Item_Wood,
  Item_Stone,
  Item_Coal,
  Item_Iron,
  Item_Diamond,
  Item_Leather,

  Item_Apple,
  Item_Heartapple,
  Item_Orange,
  Item_Map,
  Item_Compass,

  Special_Torch,
  Special_Smoke_Screen,

  Upgrade_Walking_Staff,
  Upgrade_Mortar,
  Upgrade_Vision_Tube,
  Upgrade_Spy_Glass,
  Upgrade_Iron_Lamp,
  Upgrade_Diamond_Lamp,

  Cursed_Axe,
  Cursed_Mallet,

  Equipment_Sword_Socket,
  Equipment_Sword_Iron,
  Equipment_Sword_Diamond,

  Equipment_Mallet_Socket,
  Equipment_Mallet_Cursed,
  Equipment_Mallet_Wood,
  Equipment_Mallet_Stone,
  Equipment_Mallet_Iron,
  Equipment_Mallet_Diamond,

  Equipment_Axe_Socket,
  Equipment_Axe_Cursed,
  Equipment_Axe_Stone,
  Equipment_Axe_Iron,
  Equipment_Axe_Diamond,

  Equipment_Shield_Socket,
  Equipment_Shield_Stone,
  Equipment_Shield_Iron,
  Equipment_Shield_Diamond,

  UI_Heart_0,
  UI_Heart_1,
  UI_Heart_2,
  UI_Bolt_0,
  UI_Bolt_1,
  UI_Bolt_2,
  UI_Bolt_3,
  UI_Shield_0,
  UI_Shield_1,
  UI_Shield_2,
}

ATLAS_SIZE :: 512
Sprite_atlas :=       [Sprite][4]f32{
  .None = {},
  .Solid =                    [4]f32{ 210,  19,  3,  3 },

  .Player_Left =              [4]f32{   0,  28, 32, 48 },
  .Player_Left_Walk =         [4]f32{  32,  28, 32, 48 },
  .Player_Down =              [4]f32{  64,  28, 32, 48 },
  .Player_Down_Walk =         [4]f32{  96,  28, 32, 48 },
  .Player_Up =                [4]f32{ 128,  28, 32, 48 },
  .Player_Up_Walk =           [4]f32{ 160,  28, 32, 48 },
  .Player_Left_Hold =         [4]f32{ 192,  28, 32, 48 },
  .Player_Left_Walk_Hold =    [4]f32{ 224,  28, 32, 48 },
  .Player_Down_Hold =         [4]f32{ 256,  28, 32, 48 },
  .Player_Down_Walk_Hold =    [4]f32{ 288,  28, 32, 48 },
  .Player_Up_Hold =           [4]f32{ 320,  28, 32, 48 },
  .Player_Up_Walk_Hold =      [4]f32{ 352,  28, 32, 48 },

  .Ladder_Down =              [4]f32{   0,  76, 32, 48 },
  .Ladder_Up =                [4]f32{  32,  76, 32, 48 },
  .Tree =                     [4]f32{  64,  76, 32, 48 },
  .Crafting =                 [4]f32{  96,  76, 32, 48 },
  .Crate =                    [4]f32{ 128,  76, 32, 48 },
  .Altar =                    [4]f32{ 160,  76, 32, 48 },

  .Glyph_Unknown =            [4]f32{   0, 124, 32, 32 },
  .Glyph_Floor =              [4]f32{  32, 124, 32, 32 },
  .Glyph_Ladder =             [4]f32{  64, 124, 32, 32 },
  .Glyph_Wall =               [4]f32{  96, 124, 32, 32 },
  .Glyph_Tree =               [4]f32{ 128, 124, 32, 32 },
  .Glyph_Crafting =           [4]f32{ 160, 124, 32, 32 },
  .Glyph_Item =               [4]f32{ 192, 124, 32, 32 },
  .Glyph_Crate =              [4]f32{ 224, 124, 32, 32 },
  .Glyph_Water =              [4]f32{ 256, 124, 32, 32 },
  .Glyph_Altar =              [4]f32{ 288, 124, 32, 32 },

  .Floor_Stone =              [4]f32{   0, 156, 32, 32 },
  .Floor_Grass =              [4]f32{  32, 156, 32, 32 },
  .Floor_Dirt =               [4]f32{  64, 156, 32, 32 },
  .Floor_Sand =               [4]f32{  96, 156, 32, 32 },
  .Floor_Water =              [4]f32{ 128, 156, 32, 32 },

  .Wall =                     [4]f32{   0, 188, 32, 64 },
  .Wall_Sockets =             [4]f32{  32, 188, 32, 64 },
  .Wall_Fillins =             [4]f32{  64, 188, 32, 64 },

  .Item_Wood =                [4]f32{   0, 252, 24, 24 },
  .Item_Stone =               [4]f32{  24, 252, 24, 24 },
  .Item_Coal =                [4]f32{  48, 252, 24, 24 },
  .Item_Iron =                [4]f32{  72, 252, 24, 24 },
  .Item_Diamond =             [4]f32{  96, 252, 24, 24 },
  .Item_Leather =             [4]f32{ 120, 252, 24, 24 },

  .Item_Apple =               [4]f32{ 144, 252, 24, 24 },
  .Item_Heartapple =          [4]f32{ 168, 252, 24, 24 },
  .Item_Orange =              [4]f32{ 192, 252, 24, 24 },
  .Item_Map =                 [4]f32{ 216, 252, 24, 24 },
  .Item_Compass =             [4]f32{ 240, 252, 24, 24 },

  .Special_Torch =            [4]f32{   0, 276, 24, 24 },
  .Special_Smoke_Screen =     [4]f32{  24, 276, 24, 24 },

  .Upgrade_Walking_Staff =    [4]f32{  48, 276, 24, 24 },
  .Upgrade_Mortar =           [4]f32{  72, 276, 24, 24 },
  .Upgrade_Vision_Tube =      [4]f32{  96, 276, 24, 24 },
  .Upgrade_Spy_Glass =        [4]f32{ 120, 276, 24, 24 },
  .Upgrade_Iron_Lamp =        [4]f32{ 144, 276, 24, 24 },
  .Upgrade_Diamond_Lamp =     [4]f32{ 168, 276, 24, 24 },

  .Cursed_Axe =               [4]f32{  24, 348, 24, 24 },
  .Cursed_Mallet =            [4]f32{  24, 324, 24, 24 },

  .Equipment_Sword_Socket =   [4]f32{   0, 300, 24, 24 },
  .Equipment_Sword_Iron =     [4]f32{  24, 300, 24, 24 },
  .Equipment_Sword_Diamond =  [4]f32{  48, 300, 24, 24 },

  .Equipment_Mallet_Socket =  [4]f32{   0, 324, 24, 24 },
  .Equipment_Mallet_Cursed =  [4]f32{  24, 324, 24, 24 },
  .Equipment_Mallet_Wood =    [4]f32{  48, 324, 24, 24 },
  .Equipment_Mallet_Stone =   [4]f32{  72, 324, 24, 24 },
  .Equipment_Mallet_Iron =    [4]f32{  96, 324, 24, 24 },
  .Equipment_Mallet_Diamond = [4]f32{ 120, 324, 24, 24 },

  .Equipment_Axe_Socket =     [4]f32{   0, 348, 24, 24 },
  .Equipment_Axe_Cursed =     [4]f32{  24, 348, 24, 24 },
  .Equipment_Axe_Stone =      [4]f32{  48, 348, 24, 24 },
  .Equipment_Axe_Iron =       [4]f32{  72, 348, 24, 24 },
  .Equipment_Axe_Diamond =    [4]f32{  96, 348, 24, 24 },

  .Equipment_Shield_Socket =  [4]f32{   0, 372, 24, 24 },
  .Equipment_Shield_Stone =   [4]f32{  24, 372, 24, 24 },
  .Equipment_Shield_Iron =    [4]f32{  48, 372, 24, 24 },
  .Equipment_Shield_Diamond = [4]f32{  72, 372, 24, 24 },

  .UI_Heart_0 =               [4]f32{   0, 496, 16, 16 },
  .UI_Heart_1 =               [4]f32{  16, 496, 16, 16 },
  .UI_Heart_2 =               [4]f32{  32, 496, 16, 16 },
  .UI_Bolt_0 =                [4]f32{  48, 496, 16, 16 },
  .UI_Bolt_1 =                [4]f32{  64, 496, 16, 16 },
  .UI_Bolt_2 =                [4]f32{  80, 496, 16, 16 },
  .UI_Bolt_3 =                [4]f32{  96, 496, 16, 16 },
  .UI_Shield_0 =              [4]f32{ 112, 496, 16, 16 },
  .UI_Shield_1 =              [4]f32{ 128, 496, 16, 16 },
  .UI_Shield_2 =              [4]f32{ 144, 496, 16, 16 },
}

TEXT_SPACING := [256]f32 {
  '!' = 1,
  ' ' = 2,
  '"' = 3,
  '#' = 6,
  '$' = 3,
  '%' = 3,
  '&' = 4,
  '\'' = 1,
  '(' = 2,
  ')' = 2,
  '*' = 3,
  '+' = 3,
  ',' = 2,
  '-' = 3,
  '.' = 2,
  '/' = 3,
  '0' = 4,
  '1' = 2,
  '2' = 3,
  '3' = 3,
  '4' = 3,
  '5' = 3,
  '6' = 4,
  '7' = 3,
  '8' = 4,
  '9' = 4,
  ':' = 2,
  ';' = 2,
  '<' = 3,
  '=' = 3,
  '>' = 3,
  '?' = 3,
  '@' = 4,
  'A' = 4,
  'B' = 4,
  'C' = 4,
  'D' = 4,
  'E' = 3,
  'F' = 3,
  'G' = 4,
  'H' = 4,
  'I' = 3,
  'J' = 4,
  'K' = 4,
  'L' = 3,
  'M' = 5,
  'N' = 4,
  'O' = 4,
  'P' = 4,
  'Q' = 4,
  'R' = 4,
  'S' = 4,
  'T' = 3,
  'U' = 4,
  'V' = 5,
  'W' = 5,
  'X' = 3,
  'Y' = 3,
  'Z' = 3,
  '[' = 2,
  '\\' = 3,
  ']' = 2,
  '^' = 3,
  '_' = 3,
  '`' = 2,
  'a' = 4,
  'b' = 4,
  'c' = 3,
  'd' = 4,
  'e' = 3,
  'f' = 3,
  'g' = 3,
  'h' = 3,
  'i' = 1,
  'j' = 2,
  'k' = 3,
  'l' = 2,
  'm' = 5,
  'n' = 3,
  'o' = 3,
  'p' = 3,
  'q' = 3,
  'r' = 3,
  's' = 2,
  't' = 3,
  'u' = 3,
  'v' = 3,
  'w' = 5,
  'x' = 3,
  'y' = 3,
  'z' = 4,
}

Color :: [4]f32
C_WHITE   :: Color{ 1.00, 1.00, 1.00, 1.00 }
C_RED     :: Color{ 1.00, 0.00, 0.00, 1.00 }
C_GREEN   :: Color{ 0.25, 1.00, 0.25, 1.00 }
C_YELLOW  :: Color{ 1.00, 1.00, 0.25, 1.00 }
C_GRAY    :: Color{ 0.50, 0.50, 0.50, 1.00 }
C_BLUE    :: Color{ 0.25, 0.25, 1.00, 1.00 }
C_BROWN   :: Color{ 0.75, 0.50, 0.25, 1.00 }

DrawVertex :: struct {
  pos : [2]f32,
  uv : [2]f32,
  color : Color,
}

draw_buffer : [dynamic]DrawVertex
display_rect : Rect

set_camera :: proc(center : V2, radius : f32) {
  _, display_rect = rect_fit(rect_screen(), 1, .Contain)
  display_rect.pos -= 0.5
  display_rect.y *= -1
  display_rect.h *= -1
  display_rect.arr *= radius*32
  display_rect.pos -= center*32
}

draw_screen_sprite :: proc(sprite : Sprite, dst : Rect, tint := C_WHITE) {
  if sprite == .None {
    return
  }
  src := Sprite_atlas[sprite]
  src[2] += src[0]
  src[3] += src[1]
  src /= ATLAS_SIZE
  //  0,  0 = -1,  1
  // Dw, Dh =  1, -1
  half_screen_size := [2]f32{ f32(display_size.x), f32(display_size.y) } / 2
  dst := [4]f32{ dst.x, dst.y, dst.x+dst.w, dst.y+dst.h }
  dst[0] = (dst[0] / half_screen_size.x) - 1
  dst[1] = (dst[1] / half_screen_size.y) - 1
  dst[2] = (dst[2] / half_screen_size.x) - 1
  dst[3] = (dst[3] / half_screen_size.y) - 1
  INSET :: 0.00001
  append(&draw_buffer,
      DrawVertex{ { dst[0], dst[1] }, { src[0]+INSET, src[3]+INSET }, tint },
      DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[1]-INSET }, tint },
      DrawVertex{ { dst[2], dst[1] }, { src[2]-INSET, src[3]+INSET }, tint },
      DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[1]-INSET }, tint },
      DrawVertex{ { dst[2], dst[3] }, { src[2]-INSET, src[1]-INSET }, tint },
      DrawVertex{ { dst[2], dst[1] }, { src[2]-INSET, src[3]+INSET }, tint },
    )
}

draw_sprite :: proc(sprite : Sprite, pos : V2, pivot := V2(0.5), tint := C_WHITE, flip_x := false) {
  if sprite == .None {
    return
  }
  src := Sprite_atlas[sprite]
  offset := V2{ src[2], src[3] } * pivot
  pos := 32*pos - offset
  pos += display_rect.pos
  pos /= display_rect.size
  pos += 0.5
  dst := [4]f32{ pos.x, pos.y, pos.x+src[2]/display_rect.w, pos.y+src[3]/display_rect.h }
  src[2] += src[0]
  src[3] += src[1]
  if flip_x {
    src[0], src[2] = src[2], src[0]
    // flip_y:
    // src[1], src[3] = src[3], src[1]
  }
  src /= ATLAS_SIZE
  INSET :: 0.00001
  append(&draw_buffer,
      DrawVertex{ { dst[0], dst[1] }, { src[0]+INSET, src[1]+INSET }, tint },
      DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[3]-INSET }, tint },
      DrawVertex{ { dst[2], dst[1] }, { src[2]-INSET, src[1]+INSET }, tint },
      DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[3]-INSET }, tint },
      DrawVertex{ { dst[2], dst[3] }, { src[2]-INSET, src[3]-INSET }, tint },
      DrawVertex{ { dst[2], dst[1] }, { src[2]-INSET, src[1]+INSET }, tint },
    )
}

meassure_text :: proc(str : string) -> (width : f32) {
  for r in str {
    width += TEXT_SPACING[r]+1
  }
  width -= 1
  return
}

draw_screen_text :: proc(str : string, pos : V2, scale := f32(2), pivot := V2(0.5), color := C_WHITE) {
  offset := V2{ meassure_text(str), 8 } * pivot
  pos := pos - offset*scale
  half_screen_size := [2]f32{ f32(display_size.x), f32(display_size.y) } / 2
  pos = (pos / half_screen_size) - 1
  for r in str {
    if r >= '!' && r <= 'z' {
      src := [4]f32{ f32(8*(r-'!')), 0, 8, 14 }
      if r >= 'a' {
        src[0] = f32(8*(r-'a'))
        src[1] = 14
      }
      dst := [4]f32{ pos.x, pos.y, pos.x+src[2]*scale/half_screen_size.x, pos.y+src[3]*scale/half_screen_size.y }
      src[2] += src[0]
      src[3] += src[1]
      src /= ATLAS_SIZE
      INSET :: 0.000001
      append(&draw_buffer,
          DrawVertex{ { dst[0], dst[1] }, { src[0]+INSET, src[3]-INSET }, color },
          DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[1]-INSET }, color },
          DrawVertex{ { dst[2], dst[1] }, { src[2]+INSET, src[3]-INSET }, color },
          DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[1]-INSET }, color },
          DrawVertex{ { dst[2], dst[3] }, { src[2]+INSET, src[1]-INSET }, color },
          DrawVertex{ { dst[2], dst[1] }, { src[2]+INSET, src[3]-INSET }, color },
        )
    }
    pos.x += (TEXT_SPACING[r]+1)*scale/half_screen_size.x
  }
}

draw_string :: proc(str : string, pos : V2, pivot := V2(0.5), color := C_WHITE) {
  offset := V2{ meassure_text(str), 8 } * pivot
  pos := 32*pos - offset
  pos += display_rect.pos
  pos /= display_rect.size
  pos += 0.5
  for r in str {
    if r >= '!' && r <= 'z' {
      src := [4]f32{ f32(8*(r-'!')), 0, 8, 14 }
      if r >= 'a' {
        src[0] = f32(8*(r-'a'))
        src[1] = 14
      }
      dst := [4]f32{ pos.x, pos.y, pos.x+src[2]/display_rect.w, pos.y+src[3]/display_rect.h }
      src[2] += src[0]
      src[3] += src[1]
      src /= ATLAS_SIZE
      INSET :: 0.000001
      append(&draw_buffer,
          DrawVertex{ { dst[0], dst[1] }, { src[0]+INSET, src[1]-INSET }, color },
          DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[3]-INSET }, color },
          DrawVertex{ { dst[2], dst[1] }, { src[2]+INSET, src[1]-INSET }, color },
          DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[3]-INSET }, color },
          DrawVertex{ { dst[2], dst[3] }, { src[2]+INSET, src[3]-INSET }, color },
          DrawVertex{ { dst[2], dst[1] }, { src[2]+INSET, src[1]-INSET }, color },
        )
    }
    pos.x += (TEXT_SPACING[r]+1)/display_rect.size.x
  }
}

init_graphics :: proc() {
  if !wgl.CreateCurrentContextById("canvas", { .disableAntialias, .disableAlpha, .disableDepth }) {
    crash("Could not create WebGL context")
  }

  prog : wgl.Program
  ok : bool
  if prog, ok = wgl.CreateProgramFromStrings({VS}, {FS}); !ok {
    crash("Could not create program")
  }

  wgl.Enable(wgl.BLEND)
  wgl.BlendFunc(wgl.SRC_ALPHA, wgl.ONE_MINUS_SRC_ALPHA)

  wgl.UseProgram(prog)
  vert_buffer := wgl.CreateBuffer()
  attr_pos := wgl.GetAttribLocation(prog, "a_position")
  attr_tex := wgl.GetAttribLocation(prog, "a_texcoord")
  attr_tint := wgl.GetAttribLocation(prog, "a_color")
  wgl.EnableVertexAttribArray(attr_pos)
  wgl.EnableVertexAttribArray(attr_tex)
  wgl.EnableVertexAttribArray(attr_tint)
  wgl.BindBuffer(wgl.ARRAY_BUFFER, vert_buffer)
  wgl.VertexAttribPointer(attr_pos, 2, wgl.FLOAT, false, size_of(DrawVertex), offset_of(DrawVertex, pos))
  wgl.VertexAttribPointer(attr_tex, 2, wgl.FLOAT, false, size_of(DrawVertex), offset_of(DrawVertex, uv))
  wgl.VertexAttribPointer(attr_tint, 4, wgl.FLOAT, false, size_of(DrawVertex), offset_of(DrawVertex, color))

  sprite_texture := wgl.CreateTexture()
  wgl.BindTexture(wgl.TEXTURE_2D, sprite_texture)
  img, _ := png.load_from_bytes(#load("../res/atlas.png"))
  wgl.TexImage2DSlice(wgl.TEXTURE_2D, 0, wgl.RGBA, ATLAS_SIZE, ATLAS_SIZE, 0, wgl.RGBA, wgl.UNSIGNED_BYTE, img.pixels.buf[:])
  wgl.TexParameteri(wgl.TEXTURE_2D, wgl.TEXTURE_MIN_FILTER, i32(wgl.NEAREST))
  wgl.TexParameteri(wgl.TEXTURE_2D, wgl.TEXTURE_MAG_FILTER, i32(wgl.NEAREST))
}

render :: proc() {
  wgl.Viewport(0, 0, display_size.x, display_size.y)
  wgl.Clear(wgl.COLOR_BUFFER_BIT)

  wgl.BufferDataSlice(wgl.ARRAY_BUFFER, draw_buffer[:], wgl.DYNAMIC_DRAW)
  wgl.DrawArrays(wgl.TRIANGLES, 0, len(draw_buffer))
  clear(&draw_buffer)
}

VS :: `
  attribute vec4 a_position;
  attribute vec2 a_texcoord;
  attribute vec4 a_color;

  varying vec2 v_texcoord;
  varying vec4 v_color;

  void main() {
    gl_Position = a_position;
    v_texcoord = a_texcoord;
    v_color = a_color;
  }
  `

FS :: `
  precision mediump float;

  varying vec2 v_texcoord;
  varying vec4 v_color;

  uniform sampler2D u_texture;

  void main() {
    vec4 col = v_color * texture2D(u_texture, v_texcoord);
    if (col.a < 0.01) {
      discard;
    }
    gl_FragColor = col;
  }
  `
