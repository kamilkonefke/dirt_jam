package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

WIDTH :: 1280
HEIGHT :: 720

quad_vertices := []f32{
    -0.5, -0.5, 0.0,  0.0, 0.0,  0.0, 0.0, 1.0,
     0.5, -0.5, 0.0,  1.0, 0.0,  0.0, 0.0, 1.0,
    -0.5,  0.5, 0.0,  0.0, 1.0,  0.0, 0.0, 1.0,
     0.5,  0.5, 0.0,  1.0, 1.0,  0.0, 0.0, 1.0
}

quad_indices := []u16{
    0, 1, 2,
    1, 3, 2,
} 

window_handle: ^sdl.Window
window_ctx: sdl.GLContext
is_running: bool = true
event: sdl.Event

shader: u32
uniforms: map[string]gl.Uniform_Info
vao: u32
vbo: u32
ebo: u32

rot_test: f32 = 0.0

gen_terrain_data :: proc() {
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(quad_vertices) * size_of(quad_vertices), raw_data(quad_vertices), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(quad_indices) * size_of(quad_indices), raw_data(quad_indices), gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, 8 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, 8 * size_of(f32), 5 * size_of(f32))
    gl.EnableVertexAttribArray(2)

    shader, _ = gl.load_shaders("res/vertex.glsl", "res/fragment.glsl")
    uniforms = gl.get_uniforms_from_program(shader)

    gl.UseProgram(shader)
}

main :: proc() {
    _ = sdl.Init(sdl.INIT_VIDEO) 

    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, cast(i32)sdl.GL_CONTEXT_PROFILE_CORE)

    window_handle = sdl.CreateWindow("Dirt Jam", 1280, 720, sdl.WINDOW_OPENGL)
    window_ctx = sdl.GL_CreateContext(window_handle)

    sdl.GL_MakeCurrent(window_handle, window_ctx)
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)

    gen_terrain_data()

    gl.Enable(gl.DEPTH_TEST)
    for is_running {
        for sdl.PollEvent(&event) {
            if event.type == sdl.EventType.QUIT {
                is_running = false
            }
        }


        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        gl.ClearColor(0.0, 0.0, 0.0, 1.0)

        width, height: i32
        sdl.GetWindowSize(window_handle, &width, &height)

        projection := glm.mat4Perspective(glm.radians_f32(60.0), f32(width)/f32(height), 0.01, 100.0)
        camera_position := glm.vec3{2.0, 3.0, 2.0}
        view := glm.mat4LookAt(camera_position, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
        model_pos := glm.mat4Translate({0.0, 0.0, 0.0})
        rot_test += 1.0
        model_rotstale := glm.mat4Rotate({1.0, 0.0, 0.0}, glm.radians_f32(90.0))
        model_rot := glm.mat4Rotate({0.0, 1.0, 0.0}, glm.radians_f32(rot_test))
        model := model_pos * model_rot * model_rotstale

        gl.UniformMatrix4fv(uniforms["projection"].location, 1, false, &projection[0, 0])
        gl.UniformMatrix4fv(uniforms["view"].location, 1, false, &view[0, 0])
        gl.UniformMatrix4fv(uniforms["model"].location, 1, false, &model[0, 0])

        gl.UseProgram(shader)
        gl.BindVertexArray(vao)
        gl.DrawElements(gl.TRIANGLES, i32(len(quad_indices)), gl.UNSIGNED_SHORT, nil)

        sdl.GL_SwapWindow(window_handle)
    }

    gl.DeleteVertexArrays(1, &vao)
    gl.DeleteBuffers(1, &vbo)
    gl.DeleteBuffers(1, &ebo)
    gl.DeleteShader(shader)

    sdl.DestroyWindow(window_handle)
    sdl.GL_DestroyContext(window_ctx)
    sdl.Quit()
}
