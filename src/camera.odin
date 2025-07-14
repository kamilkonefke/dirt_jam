package main

import "core:fmt"
import "core:c"
import "base:runtime"
import math "core:math"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

Camera :: struct {
    position: glm.vec3,
    forward: glm.vec3,
    right: glm.vec3,
    up: glm.vec3,
    pitch: f32,
    yaw: f32,
}

camera: Camera = {
    position = {30.0, 20.0, 30.0},
    forward = {0.0, 0.0, 1.0},
    right = {1.0, 0.0, 0.0},
    up = {0.0, 1.0, 0.0},
    pitch = 0.0,
    yaw = 0.0,
}

update_camera :: proc() {
    if key_down[.W] { 
        camera.position += camera.forward
    }
    if key_down[.S] { 
        camera.position -= camera.forward 
    }
    if key_down[.A] { 
        camera.position -= camera.right
    }
    if key_down[.D] { 
        camera.position += camera.right 
    }
    
    _ = sdl.SetWindowRelativeMouseMode(window_handle, mouse_down[1])
    sdl.SetWindowMouseGrab(window_handle, mouse_down[1])
    if mouse_down[1] {
        camera.pitch -= mouse_motion.y * 0.05
        camera.yaw += mouse_motion.x * 0.05
        camera.pitch = math.clamp(camera.pitch, -89.0, 89.0)
    }

    direction: glm.vec3
    direction.x = glm.cos(glm.radians_f32(camera.yaw)) * glm.cos(glm.radians_f32(camera.pitch))
    direction.y = glm.sin(glm.radians_f32(camera.pitch))
    direction.z = glm.sin(glm.radians_f32(camera.yaw)) * glm.cos(glm.radians_f32(camera.pitch))
    camera.forward = glm.normalize(direction)
    camera.right = glm.normalize(glm.cross(camera.forward, camera.up))

    projection := glm.mat4Perspective(glm.radians_f32(60.0), f32(window_width)/f32(window_height), 0.01, 1000.0)
    view := glm.mat4LookAt(camera.position, camera.position + camera.forward, {0.0, 1.0, 0.0})
    world := glm.mat4Translate({0.0, 0.0, 0.0})

    ubo_data.camera_pos = camera.position
    ubo_data.world_matrix = world
    ubo_data.mvp = projection * view * world
}

