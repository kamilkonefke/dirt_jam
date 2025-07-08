#+feature dynamic-literals
package main

import "core:fmt"
import "core:c"
import "base:runtime"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

import im "../lib/odin-imgui"
import im_sdl "../lib/odin-imgui/imgui_impl_sdl3"
import im_gl "../lib/odin-imgui/imgui_impl_opengl3"

window_handle: ^sdl.Window
window_ctx: sdl.GLContext
window_width: i32 = 1280
window_height: i32 = 720
event: sdl.Event

is_running: bool = true
is_wireframe: bool = false

shader: u32
ubo: u32

vao: u32
vbo: u32
ebo: u32

vertex_buffer := [dynamic]f32{}
index_buffer := [dynamic]u32{} 

terrain_length :: 200
terrain_half :: terrain_length/2
terrain_scale :: 0.2

u_mvp: glm.mat4
u_albedo: glm.vec4 = {0.329, 0.505, 0.412, 1.0};
u_ambient: glm.vec4 = {0.25, 0.25, 0.25, 1.0};
u_frequency: f32 = 0.146;
u_amplitude: f32 = 5.322;

compile_shaders :: proc() {
    shader, _ = gl.load_shaders("res/vertex.glsl", "res/fragment.glsl")
}

create_ubo :: proc() {
    gl.GenBuffers(1, &ubo)
    gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
    gl.BufferData(gl.UNIFORM_BUFFER, size_of(glm.mat4) + size_of(glm.vec4) * 2 + size_of(f32) * 2, nil, gl.STATIC_DRAW)
    gl.BindBuffer(gl.UNIFORM_BUFFER, 0)
}

update_ubo :: proc() {
    gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
    gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(glm.mat4), &u_mvp[0, 0])
    gl.BufferSubData(gl.UNIFORM_BUFFER, size_of(glm.mat4), size_of(glm.vec4), &u_albedo[0])
    gl.BufferSubData(gl.UNIFORM_BUFFER, size_of(glm.mat4) + size_of(glm.vec4), size_of(glm.vec4), &u_ambient[0])
    gl.BufferSubData(gl.UNIFORM_BUFFER, size_of(glm.mat4) + size_of(glm.vec4) * 2, size_of(f32), &u_frequency)
    gl.BufferSubData(gl.UNIFORM_BUFFER, size_of(glm.mat4) + size_of(glm.vec4) * 2 + size_of(f32), size_of(f32), &u_amplitude)
    gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, ubo)
}

update_mvp :: proc() {
    projection := glm.mat4Perspective(glm.radians_f32(60.0), f32(window_width)/f32(window_height), 0.01, 1000.0)
    camera_position := glm.vec3{30.0, 20.0, 30.0}
    view := glm.mat4LookAt(camera_position, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
    model := glm.mat4Translate({0.0, 0.0, 0.0})

    u_mvp = projection * view * model
}

gen_terrain_data :: proc() {
    for x in 0..<terrain_length {
        for z in 0..<terrain_length {
            xz: glm.vec2 = {f32(x - terrain_half), f32(z - terrain_half)} * terrain_scale
            pos: glm.vec3 = {xz.x, 0, xz.y}
            append(&vertex_buffer, pos.x, pos.y, pos.z)
        }
    }

    for row := 0; row < terrain_length * terrain_length - terrain_length; row += terrain_length  {
        for i in 0..<terrain_length - 1 {
            v0 := i + row
            v1 := v0 + terrain_length
            v2 := v0 + terrain_length + 1
            v3 := v0 + 1

            append(&index_buffer, u32(v0), u32(v1), u32(v3), u32(v1), u32(v2), u32(v3))
        }
    }
}

alloc_terrain_data :: proc() {
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertex_buffer) * size_of(f32), raw_data(vertex_buffer), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(index_buffer) * size_of(u32), raw_data(index_buffer), gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
}

main :: proc() {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.println("SDL INIT ERROR: ", sdl.GetError())
        return
    }

    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, cast(i32)sdl.GL_CONTEXT_PROFILE_CORE)
    sdl.GL_SetSwapInterval(1)

    window_handle = sdl.CreateWindow("Dirt Jam", 1280, 720, sdl.WINDOW_OPENGL)
    window_ctx = sdl.GL_CreateContext(window_handle)

    sdl.GL_MakeCurrent(window_handle, window_ctx)
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)

    gen_terrain_data()
    alloc_terrain_data()
    compile_shaders()
    create_ubo()
    setup_imgui()

    gl.Enable(gl.DEPTH_TEST)
    for is_running {
        // -_-
        for sdl.PollEvent(&event) {
            im_sdl.process_event(&event)
            
            if event.type == sdl.EventType.QUIT {
                is_running = false
            }

            if event.type == sdl.EventType.WINDOW_RESIZED {
                sdl.GetWindowSize(window_handle, &window_width, &window_height)
                gl.Viewport(0, 0, window_width, window_height)
            }

            if event.type == sdl.EventType.KEY_UP {
                if event.key.scancode == sdl.Scancode.R {
                    compile_shaders()
                }

                if event.key.scancode == sdl.Scancode.W {
                    is_wireframe = !is_wireframe
                    if is_wireframe == true {
                        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
                    }
                    else {
                        gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
                    }
                }
            }
        }

        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        gl.ClearColor(0.659, 0.647, 0.714, 1.0)

        update_mvp()
        update_ubo()

        gl.UseProgram(shader)
        gl.BindVertexArray(vao)
        gl.DrawElements(gl.TRIANGLES, i32(len(index_buffer)), gl.UNSIGNED_INT, nil)

        update_imgui()

        sdl.GL_SwapWindow(window_handle)
    }

    gl.DeleteVertexArrays(1, &vao)
    gl.DeleteBuffers(1, &vbo)
    gl.DeleteBuffers(1, &ebo)
    gl.DeleteShader(shader)

    delete(vertex_buffer)
    delete(index_buffer)

    free_imgui()

    sdl.DestroyWindow(window_handle)
    sdl.GL_DestroyContext(window_ctx)
    sdl.Quit()
}
