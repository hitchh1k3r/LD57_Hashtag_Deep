package main

import "core:fmt"
import "core:image/png"
import "core:math"
import "core:math/linalg/glsl"
import "core:sys/wasm/js"

import wgl "vendor:wasm/WebGL"

Sprite :: enum {
  Solid,
  Text,
  Click_To_Play,

  Glyph_Unknown,
  Glyph_Ladder,
  Glyph_Player,
  Glyph_Floor,
  Glyph_Wall,
  Glyph_Chest_Closed,
  Glyph_Chest_Opened,
  Glyph_Tree,

  Floor,
  Wall,

  Up_Ladder,
  Ladder,
  Chest_Closed,
  Chest_Opened,

  Player_Down,
  Tree,

  Harvest_1,
  Harvest_2,
  Harvest_3,

  Item_Wood,
  Item_Stone,
  Item_Coal,
}

ATLAS_SIZE :: 2048
Sprite_atlas :=     [Sprite][4]f32{
  .Solid =                  [4]f32{  0,  29,  1,  1 } * 64,
  .Text =                   [4]f32{  0, 231,  1,  1 } *  8,
  .Click_To_Play =          [4]f32{  0,  30, 10,  2 } * 64,

  .Glyph_Unknown =          [4]f32{  0,   0,  1,  1 } * 64,
  .Glyph_Ladder =           [4]f32{  0,   1,  1,  1 } * 64,
  .Glyph_Player =           [4]f32{  0,   2,  1,  2 } * 64,
  .Glyph_Floor =            [4]f32{  0,   4,  1,  2 } * 64,
  .Glyph_Wall =             [4]f32{  0,   6,  1,  2 } * 64,
  .Glyph_Chest_Closed =     [4]f32{  0,   8,  1,  2 } * 64,
  .Glyph_Chest_Opened =     [4]f32{  2,   8,  1,  2 } * 64,
  .Glyph_Tree =             [4]f32{  2,   6,  1,  2 } * 64,

  .Floor =                  [4]f32{  1,   4,  1,  2 } * 64,
  .Wall =                   [4]f32{  1,   6,  1,  2 } * 64,

  .Up_Ladder =              [4]f32{  2,   0,  1,  2 } * 64,
  .Ladder =                 [4]f32{  1,   0,  1,  2 } * 64,
  .Chest_Closed =           [4]f32{  1,   8,  1,  2 } * 64,
  .Chest_Opened =           [4]f32{  3,   8,  1,  2 } * 64,

  .Player_Down =            [4]f32{  1,   2,  1,  2 } * 64,
  .Tree =                   [4]f32{  3,   6,  1,  2 } * 64,

  .Item_Wood =              [4]f32{  0,  10,  1,  1 } * 64,
  .Item_Stone =             [4]f32{  1,  10,  1,  1 } * 64,
  .Item_Coal =              [4]f32{  2,  10,  1,  1 } * 64,

  .Harvest_1 =              [4]f32{  0,  11,  1,  1 } * 64,
  .Harvest_2 =              [4]f32{  1,  11,  1,  2 } * 64,
  .Harvest_3 =              [4]f32{  2,  11,  1,  2 } * 64,
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
  'r' = 2,
  's' = 2,
  't' = 3,
  'u' = 3,
  'v' = 3,
  'w' = 5,
  'x' = 3,
  'y' = 3,
  'z' = 3,
}

Color :: [4]f32
C_WHITE   :: Color{ 1.00, 1.00, 1.00, 1.00 }
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
  display_rect.arr *= radius*64
  display_rect.pos -= center*64
}

draw_sprite :: proc(sprite : Sprite, pos : V2, pivot := V2(0.5), tint := C_WHITE) {
  src := Sprite_atlas[sprite]
  offset := V2{ src[2], src[3] } * pivot
  pos := 64*pos - offset
  pos.x = math.round(pos.x)
  pos.y = math.round(pos.y)
  pos += display_rect.pos
  pos /= display_rect.size
  pos += 0.5
  dst := [4]f32{ pos.x, pos.y, pos.x+src[2]/display_rect.w, pos.y+src[3]/display_rect.h }
  src[2] += src[0]
  src[3] += src[1]
  src /= ATLAS_SIZE
  INSET :: 0.000001
  append(&draw_buffer,
      DrawVertex{ { dst[0], dst[1] }, { src[0]+INSET, src[1]-INSET }, tint },
      DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[3]-INSET }, tint },
      DrawVertex{ { dst[2], dst[1] }, { src[2]+INSET, src[1]-INSET }, tint },
      DrawVertex{ { dst[0], dst[3] }, { src[0]+INSET, src[3]-INSET }, tint },
      DrawVertex{ { dst[2], dst[3] }, { src[2]+INSET, src[3]-INSET }, tint },
      DrawVertex{ { dst[2], dst[1] }, { src[2]+INSET, src[1]-INSET }, tint },
    )
}

meassure_text :: proc(str : string) -> (width : f32) {
  for r in str {
    width += TEXT_SPACING[r]+1
  }
  width -= 1
  return
}

draw_string :: proc(str : string, pos : V2, pivot := V2(0.5), color := C_WHITE) {
  offset := V2{ meassure_text(str), 8 } * pivot
  pos := 64*pos - offset
  pos.x = math.round(pos.x)
  pos.y = math.round(pos.y)
  pos += display_rect.pos
  pos /= display_rect.size
  pos += 0.5
  for r in str {
    if r >= '!' && r <= 'z' {
      src := Sprite_atlas[.Text]
      src[0] += 8*f32(r-'!')
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
  img, _ := png.load_from_bytes(#load("../res/spritesheet.png"))
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
