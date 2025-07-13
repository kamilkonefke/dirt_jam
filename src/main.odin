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

key_down: #sparse[sdl.Scancode]bool
mouse_down: [2]bool
mouse_motion: glm.vec2

is_running: bool = true
is_wireframe: bool = false

shader: u32
ubo: u32

vao: u32
vbo: u32
ebo: u32

vertex_buffer := [dynamic]f32{}
index_buffer := [dynamic]u32{} 

terrain_length :: 600
terrain_half :: terrain_length/2
terrain_scale :: 1.6

// If something is fucked up then look here.
ubo_layout :: struct {
    mvp: glm.mat4,
    world_matrix: glm.mat4,
    high_slope_color: glm.vec4,
    low_slope_color: glm.vec4,
    ambient: glm.vec4,
    fog_color: glm.vec4,
    camera_pos: glm.vec3,
    _pad0: f32,
    frequency_variance: glm.vec2,
    slope_range: glm.vec2,
    slope_damping: f32,
    frequency: f32,
    amplitude: f32,
    lacunarity: f32,
    seed: f32,
    fog_density: f32,
    octaves: i32,
}

ubo_data: ubo_layout  = {
    mvp = 0,
    world_matrix = 0,
    camera_pos = 0,
    high_slope_color = {0.142, 0.121, 0.108, 1.0},
    low_slope_color = {0.229, 0.353, 0.221, 1.0},
    ambient = {0.259, 0.306, 0.328, 1.0},
    fog_color = {0.599, 0.615, 0.74, 1.0},
    frequency_variance = {-0.29, 0.22},
    slope_range = {0.83, 0.88},
    slope_damping = 0.06,
    frequency = 0.004,
    amplitude = 136.0,
    lacunarity = 3.79,
    seed = 4325.00,
    fog_density = 0.003,
    octaves = 8,
}

compile_shaders :: proc() {
    shader, _ = gl.load_shaders("res/vertex.glsl", "res/fragment.glsl")
}

create_ubo :: proc() {
    gl.GenBuffers(1, &ubo)
    gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
    gl.BufferData(gl.UNIFORM_BUFFER, size_of(ubo_layout), nil, gl.STATIC_DRAW)
    gl.BindBuffer(gl.UNIFORM_BUFFER, 0)
}

update_ubo :: proc() {
    gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
    gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(ubo_layout), &ubo_data)
    gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, ubo)
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

    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 6)
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, cast(i32)sdl.GL_CONTEXT_PROFILE_CORE)

    window_handle = sdl.CreateWindow("Dirt Jam", 1280, 720, sdl.WINDOW_OPENGL)
    window_ctx = sdl.GL_CreateContext(window_handle)
    sdl.GL_SetSwapInterval(1)

    sdl.GL_MakeCurrent(window_handle, window_ctx)
    gl.load_up_to(4, 6, sdl.gl_set_proc_address)

    gen_terrain_data()
    alloc_terrain_data()
    compile_shaders()
    create_ubo()
    setup_imgui()

    gl.Enable(gl.DEPTH_TEST)
    for is_running {
        mouse_motion = {}
        // -_-
        for sdl.PollEvent(&event) {
            im_sdl.process_event(&event)

            if event.type == sdl.EventType.QUIT do is_running = false

            if event.type == sdl.EventType.WINDOW_RESIZED {
                sdl.GetWindowSize(window_handle, &window_width, &window_height)
                gl.Viewport(0, 0, window_width, window_height)
            }

            if event.type == sdl.EventType.KEY_UP {
                key_down[event.key.scancode] = false
                if event.key.scancode == .R {
                    compile_shaders()
                }
                if event.key.scancode == .E {
                    is_wireframe = !is_wireframe
                    if is_wireframe == true {
                        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
                    }
                    else {
                        gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
                    }
                }
            }

            if event.type == sdl.EventType.KEY_DOWN {
                key_down[event.key.scancode] = true
            }

            if event.type == sdl.EventType.MOUSE_BUTTON_DOWN {
                if event.button.button == sdl.BUTTON_RIGHT {
                    mouse_down[1] = true
                }
            }

            if event.type == sdl.EventType.MOUSE_BUTTON_UP {
                if event.button.button == sdl.BUTTON_RIGHT {
                    mouse_down[1] = false
                }
            }

            if event.type == sdl.EventType.MOUSE_MOTION {
                mouse_motion += {event.motion.xrel, event.motion.yrel}
            }
        }

        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        gl.ClearColor(0.659, 0.647, 0.714, 1.0)

        update_camera()
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
    gl.DeleteBuffers(1, &ubo)
    gl.DeleteShader(shader)

    delete(vertex_buffer)
    delete(index_buffer)

    free_imgui()

    sdl.DestroyWindow(window_handle)
    sdl.GL_DestroyContext(window_ctx)
    sdl.Quit()
}
