package main

import "base:runtime"

import "core:fmt"
import "core:image/png"
import "core:math/linalg/glsl"
import "core:os"
import "core:sys/wasm/js"

import wgl "vendor:wasm/WebGL"

Sprite :: enum {
  TowerCard_Back,
  TowerCard_Front,
  MobCard_Back,
  MobCard_Front,
  PathTile_Back,
  PathTile_Front,
  Rune_Red,
  Rune_Blue,
  Rune_Green,
  Rune_Purple,
  Rune_Yellow,
  Rune_Gray,
  Cost_Red,
  Cost_Blue,
  Cost_Green,
  Cost_Purple,
  Cost_Yellow,
  Cost_Gray,
  Cost_1,
  Cost_2,
  Cost_3,
  Cost_4,
  Cost_5,
  Cost_6,
  Cost_7,
  Cost_8,
  Cost_9,
}

ATLAS_SIZE :: 2048
Sprite_atlas := [Sprite][4]f32{
  .TowerCard_Back =     [4]f32{  0,  0,  4,  6 } * 16,
  .TowerCard_Front =    [4]f32{  4,  0,  4,  6 } * 16,
  .MobCard_Back =       [4]f32{  0,  6,  4,  6 } * 16,
  .MobCard_Front =      [4]f32{  4,  6,  4,  6 } * 16,
  .PathTile_Back =      [4]f32{  0, 12,  4,  5 } * 16,
  .PathTile_Front =     [4]f32{  4, 12,  4,  5 } * 16,
  .Rune_Red =           [4]f32{  0, 31,  2,  2 } * 16,
  .Rune_Blue =          [4]f32{  2, 31,  2,  2 } * 16,
  .Rune_Green =         [4]f32{  4, 31,  2,  2 } * 16,
  .Rune_Purple =        [4]f32{  6, 31,  2,  2 } * 16,
  .Rune_Yellow =        [4]f32{  8, 31,  2,  2 } * 16,
  .Rune_Gray =          [4]f32{ 10, 31,  2,  2 } * 16,
  .Cost_Red =           [4]f32{  0, 33,  1,  1 } * 16,
  .Cost_Blue =          [4]f32{  1, 33,  1,  1 } * 16,
  .Cost_Green =         [4]f32{  2, 33,  1,  1 } * 16,
  .Cost_Purple =        [4]f32{  3, 33,  1,  1 } * 16,
  .Cost_Yellow =        [4]f32{  4, 33,  1,  1 } * 16,
  .Cost_Gray =          [4]f32{  5, 33,  1,  1 } * 16,
  .Cost_1 =             [4]f32{  6, 33,  1,  1 } * 16,
  .Cost_2 =             [4]f32{  7, 33,  1,  1 } * 16,
  .Cost_3 =             [4]f32{  8, 33,  1,  1 } * 16,
  .Cost_4 =             [4]f32{  9, 33,  1,  1 } * 16,
  .Cost_5 =             [4]f32{ 10, 33,  1,  1 } * 16,
  .Cost_6 =             [4]f32{ 11, 33,  1,  1 } * 16,
  .Cost_7 =             [4]f32{ 12, 33,  1,  1 } * 16,
  .Cost_8 =             [4]f32{ 13, 33,  1,  1 } * 16,
  .Cost_9 =             [4]f32{ 14, 33,  1,  1 } * 16,
}

V2 :: [2]f32
Color :: [4]f32
DrawVertex :: struct {
  pos : [2]f32,
  uv : [2]f32,
}

main :: proc() {
  fmt.println("Initializing...")

  if !wgl.CreateCurrentContextById("canvas", { .disableAntialias, .disableAlpha, .disableDepth }) {
    crash("Could not create WebGL context")
  }
  display_size = { 640, 480 }
  js.set_element_key_f64("canvas", "width", f64(display_size.x))
  js.set_element_key_f64("canvas", "height", f64(display_size.y))

  js.set_element_key_string("body", "style", "background:rgb(200, 100, 0);")
  wgl.ClearColor(1, 0.5, 0, 1)

  prog : wgl.Program
  ok : bool
  if prog, ok = wgl.CreateProgramFromStrings({VS}, {FS}); !ok {
    crash("Could not create program")
  }
  uni_matrix = wgl.GetUniformLocation(prog, "u_matrix")

  wgl.UseProgram(prog)
  vert_buffer := wgl.CreateBuffer()
  attr_pos := wgl.GetAttribLocation(prog, "a_position")
  attr_tex := wgl.GetAttribLocation(prog, "a_texcoord")
  wgl.EnableVertexAttribArray(attr_pos)
  wgl.EnableVertexAttribArray(attr_tex)
  wgl.BindBuffer(wgl.ARRAY_BUFFER, vert_buffer)
  wgl.VertexAttribPointer(attr_pos, 2, wgl.FLOAT, false, size_of(DrawVertex), offset_of(DrawVertex, pos))
  wgl.VertexAttribPointer(attr_tex, 2, wgl.FLOAT, false, size_of(DrawVertex), offset_of(DrawVertex, uv))

  sprite_texture := wgl.CreateTexture()
  wgl.BindTexture(wgl.TEXTURE_2D, sprite_texture)
  img, _ := png.load_from_bytes(#load("../res/spritesheet.png"))
  wgl.TexImage2DSlice(wgl.TEXTURE_2D, 0, wgl.RGBA, ATLAS_SIZE, ATLAS_SIZE, 0, wgl.RGBA, wgl.UNSIGNED_BYTE, img.pixels.buf[:])
  wgl.TexParameteri(wgl.TEXTURE_2D, wgl.TEXTURE_MIN_FILTER, i32(wgl.NEAREST))
  wgl.TexParameteri(wgl.TEXTURE_2D, wgl.TEXTURE_MAG_FILTER, i32(wgl.NEAREST))

  fmt.println("Starting...")
}

draw_buffer : [dynamic]DrawVertex

draw_sprite :: proc(sprite : Sprite, x, y : f32) {
  src := Sprite_atlas[sprite]
  dst := [4]f32{ x, y, x+src[2], y+src[3] }
  src[2] += src[0]
  src[3] += src[1]
  src /= ATLAS_SIZE
  append(&draw_buffer,
      DrawVertex{ { dst[0], dst[1] }, { src[0], src[1] } },
      DrawVertex{ { dst[0], dst[3] }, { src[0], src[3] } },
      DrawVertex{ { dst[2], dst[1] }, { src[2], src[1] } },
      DrawVertex{ { dst[0], dst[3] }, { src[0], src[3] } },
      DrawVertex{ { dst[2], dst[3] }, { src[2], src[3] } },
      DrawVertex{ { dst[2], dst[1] }, { src[2], src[1] } },
    )
}

display_size : [2]i32

uni_matrix : i32

app_defunct := false
@(export)
step :: proc(dt : f64) -> bool {
  if app_defunct {
    return false
  }

  clear(&draw_buffer)
  for r in 0..<9 {
    for q in 0..<7 {
      draw_sprite(.PathTile_Front, f32(62*q + 31*r), f32(39*r))
    }
  }
  for i in 0..<12 {
    pos := [2]f32{ f32((i % 5) * 50), f32(i * 5 + (i / 5) * 80) }
    draw_sprite(.TowerCard_Front, pos.x, pos.y)
    draw_sprite(.Cost_Red+Sprite(i % 6), pos.x + 16, pos.y + 79)
    draw_sprite(.Cost_1+Sprite(i % 9), pos.x + 32, pos.y + 79)
  }
  draw_sprite(.Rune_Red,      8, 440)
  draw_sprite(.Rune_Blue,    44, 440)
  draw_sprite(.Rune_Green,   80, 440)
  draw_sprite(.Rune_Purple, 116, 440)
  draw_sprite(.Rune_Yellow, 152, 440)
  draw_sprite(.Rune_Gray,   188, 440)

  wgl.Viewport(0, 0, display_size.x, display_size.y)
  wgl.Clear(wgl.COLOR_BUFFER_BIT)
  wgl.UniformMatrix4fv(uni_matrix, glsl.mat4Ortho3d(0, f32(display_size.x), f32(display_size.y), 0, 100, 0))

  wgl.BufferDataSlice(wgl.ARRAY_BUFFER, draw_buffer[:], wgl.DYNAMIC_DRAW)
  wgl.DrawArrays(wgl.TRIANGLES, 0, len(draw_buffer))

  return true
}

VS :: `
  attribute vec4 a_position;
  attribute vec2 a_texcoord;

  uniform mat4 u_matrix;

  varying vec2 v_texcoord;

  void main() {
    // Multiply the position by the matrix.
    gl_Position = u_matrix * a_position;

    // Pass the texcoord to the fragment shader.
    v_texcoord = a_texcoord;
  }
  `

FS :: `
  precision mediump float;

  // Passed in from the vertex shader.
  varying vec2 v_texcoord;

  // The texture.
  uniform sampler2D u_texture;

  void main() {
    vec4 col = texture2D(u_texture, v_texcoord);
    if (col.a < 0.01) {
      discard;
    }
    gl_FragColor = col;
  }
  `

crash :: proc(msg : string) -> ! {
  js.evaluate(fmt.tprintf("document.body.innerHTML = '%v';", msg))
  app_defunct = true
  os.exit(1)
}
