#version 330 core

layout(location = 0) in vec3 a_pos;

layout(std140) uniform ubo {
    mat4 u_projection;
    mat4 u_view;
    mat4 u_world;
    vec4 u_high_slope_color;
    vec4 u_low_slope_color;
    vec4 u_ambient;
    vec4 u_fog_color;
    vec4 u_sky_color;
    vec4 u_sun_color;
    vec3 u_camera_pos;
    vec3 u_sun_direction;
    vec2 u_frequency_variance;
    vec2 u_slope_range;
    float u_slope_damping;
    float u_frequency;
    float u_amplitude;
    float u_lacunarity;
    float u_seed;
    float u_fog_density;
    int u_octaves;
    bool u_shadows;
};

void main() {
    vec4 pos = u_projection * u_view * vec4(a_pos, 1.0);
    gl_Position = vec4(pos.x, pos.y, pos.w, pos.w);
}
