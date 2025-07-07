package main

import im "../lib/odin-imgui"
import im_gl "../lib/odin-imgui/imgui_impl_opengl3"
import im_sdl "../lib/odin-imgui/imgui_impl_sdl3"

setup_imgui :: proc() {
    im.CHECKVERSION()
    im.create_context()

    io := im.get_io()
    io.config_flags += {.Nav_Enable_Keyboard, .Nav_Enable_Gamepad}
    im.style_colors_dark()

    im_sdl.init_for_open_gl(window_handle, window_ctx)
    im_gl.init(nil)
}

update_imgui :: proc() {
    im_gl.new_frame()
    im_sdl.new_frame()
    im.new_frame()

    if im.begin("Tools") {
        if im.button("EXIT") {
            is_running = false
        }
    }

    im.end()
    im.render()

    im_gl.render_draw_data(im.get_draw_data())
}

free_imgui :: proc() {
    im_sdl.shutdown()
    im_gl.shutdown()

    im.destroy_context()
}
