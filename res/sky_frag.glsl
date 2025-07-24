#version 330 core

layout(location = 0) out vec4 frag_color;

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
    float u_sun_size;
    int u_octaves;
    bool u_shadows;
};

in vec3 pos;

void main() {
    vec3 n_pos = normalize(pos);
    vec3 ns_dir = normalize(u_sun_direction);

    // Replace this with smoothstep()
    vec4 sun_mask = smoothstep(u_sun_size, u_sun_size + 0.6, mix(vec4(0.0), vec4(1.0), length(n_pos - ns_dir)));

    vec4 lit = mix(u_sun_color, u_sky_color, sun_mask);
    frag_color = lit;
}
