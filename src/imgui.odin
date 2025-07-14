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
        im.text("E - toggle wireframe")

        im.separator()

        im.text("Noise")
        im.drag_float("Seed", &ubo_data.seed)
        im.slider_float("Frequency", &ubo_data.frequency, 0.001, 0.6)
        im.drag_float2("Frequency variance", &ubo_data.frequency_variance, 0.01)
        im.slider_float("Amplitude", &ubo_data.amplitude, 0.001, 500.0)
        im.slider_float("Lacunarity", &ubo_data.lacunarity, 0.001, 4.0)
        im.slider_int("Octaves", &ubo_data.octaves, 1, 8)

        im.separator()

        im.text_colored({1.0, 0.0, 0.0, 1.0}, "Shadows [Not optimized]")
        im.checkbox("Enable", &ubo_data.shadows)

        im.separator()

        im.text("Colors")
        im.color_edit4("High Slope", &ubo_data.high_slope_color, { .No_Alpha, .Display_Hex })
        im.color_edit4("Low Slope", &ubo_data.low_slope_color, { .No_Alpha, .Display_Hex })
        im.color_edit4("Ambient", &ubo_data.ambient, { .No_Alpha, .Display_Hex})

        im.drag_float3("Sun direction", &ubo_data.sun_direction, 0.01, -1.0, 1.0)

        im.drag_float2("Slope range", &ubo_data.slope_range, 0.01)
        im.slider_float("Slope damping", &ubo_data.slope_damping, 0.0, 1.0)

        im.separator()
        im.text("Fog")
        im.color_edit4("Color", &ubo_data.fog_color, { .No_Alpha, .Display_Hex })
        im.drag_float("Density", &ubo_data.fog_density, 0.0001, 0.0, 0.1)
    }

    im.show_metrics_window()

    im.end()
    im.render()

    im_gl.render_draw_data(im.get_draw_data())
}

free_imgui :: proc() {
    im_sdl.shutdown()
    im_gl.shutdown()

    im.destroy_context()
}
