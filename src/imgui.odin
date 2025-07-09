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
        if im.button("RECOMPILE SHADERS") {
            compile_shaders()
        }

        im.separator()

        im.text("R - recompile shaders")
        im.text("W - toggle wireframe")

        im.separator()

        im.label_text("", "Noise Settings")
        im.slider_float("Frequency", &u_frequency, 0.001, 0.6)
        im.slider_float("Amplitude", &u_amplitude, 0.001, 50.0)
        im.slider_float("Lacunarity", &u_lacunarity, 0.001, 4.0)
        im.slider_int("Octaves", &u_octaves, 1, 32)

        im.drag_float2("Slope range", &u_slope_range, 0.01)
        im.slider_float("Slope damping", &u_slope_damping, 0.0, 1.0)

        im.color_edit4("High Slope Color", &u_high_slope_color, { .No_Alpha, .Display_Hex })
        im.color_edit4("Low Slope Color", &u_low_slope_color, { .No_Alpha, .Display_Hex })
        im.color_edit4("Ambient", &u_ambient, { .No_Alpha, .Display_Hex})
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
