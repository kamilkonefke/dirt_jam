#version 330 core

layout(location = 0) out vec4 frag_color;

layout(std140) uniform ubo {
    mat4 u_mvp;
    mat4 u_world_matrix;
    vec4 u_high_slope_color;
    vec4 u_low_slope_color;
    vec4 u_ambient;
    vec4 u_fog_color;
    vec3 u_camera_pos;
    vec2 u_frequency_variance;
    vec2 u_slope_range;
    float u_slope_damping;
    float u_frequency;
    float u_amplitude;
    float u_lacunarity;
    float u_seed;
    float u_fog_density;
    int u_octaves;
};

in vec3 pos;

float pseudo(vec2 v) {
    v = fract(v/128.)*128. + vec2(-64.340622, -72.465622);
    return fract(dot(v.xyx * v.xyy, vec3(20.390625, 60.703125, 2.4281209)));
}

float hash_pos(vec2 pos) {
    return pseudo(pos * vec2(u_seed, u_seed + 4));
}

#define PI 3.141592653589793238462
vec2 rand_gradient(float seed) {
    float theta = seed * 360 * 2 - 360;
    theta = theta * PI / 180.0;
    return normalize(vec2(cos(theta), sin(theta)));
}

vec2 quintic_interpolation(vec2 t) {
	return t * t * t * (t * (t * vec2(6) - vec2(15)) + vec2(10));
}

vec2 quintic_derivative(vec2 t) {
    return vec2(30) * t * t * (t * (t - vec2(2)) + vec2(1));
}

vec3 perlin(vec2 pos) {
    vec2 min = floor(pos);
    vec2 max = ceil(pos);

    vec2 remainder = fract(pos);

    vec2 c00 = min;
    vec2 c10 = vec2(max.x, min.y);
    vec2 c01 = vec2(min.x, max.y);
    vec2 c11 = max;

    vec2 g00 = rand_gradient(hash_pos(c00));
    vec2 g10 = rand_gradient(hash_pos(c10));
    vec2 g01 = rand_gradient(hash_pos(c01));
    vec2 g11 = rand_gradient(hash_pos(c11));

    vec2 p0 = remainder;
    vec2 p1 = p0 - vec2(1.0);

    vec2 p00 = p0;
    vec2 p10 = vec2(p1.x, p0.y);
    vec2 p01 = vec2(p0.x, p1.y);
    vec2 p11 = p1;

    float a = dot(g00, p00);
    float b = dot(g10, p10);
    float c = dot(g01, p01);
    float d = dot(g11, p11);

    vec2 u = quintic_interpolation(remainder);
    vec2 du = quintic_derivative(remainder);

    float noise = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);
    vec2 gradient = g00 + u.x * (g10 - g00) + u.y * (g01 - g00) + u.x * u.y * (g00 - g10 - g01 + g11) + du * (u.yx * (a - b - c + d) + vec2(b, c) - a);

    return vec3(noise, gradient);
}

vec3 fbm(in vec2 p) {
    float lacunarity = u_lacunarity;
    float amplitude = u_amplitude;

    float height = 0.0;
    vec2 gradient = vec2(0.0);

    mat2 m = mat2(1.0, 0.0, 0.0, 1.0);

    mat2 m2 = mat2(cos(0.5), -sin(0.5),
                    sin(0.5), cos(0.5));

    mat2 m2i = inverse(m2);

    for(int i = 0; i < u_octaves; i++) {
        vec3 noise = perlin(p);
        if (i == 0) {
            noise = 1.0 - abs(noise);
        }

        height += amplitude * noise.x;
        gradient += amplitude * m * noise.yz;

        amplitude *= 0.2;

        float frequency_variance = mix(u_frequency_variance.x, u_frequency_variance.y, hash_pos(vec2(i * 422, u_seed)));

        p = (lacunarity + frequency_variance) * m2 * p;
        m = (lacunarity + frequency_variance) * m2i * m;
    }

    return vec3(height, gradient);
}

void main() {
    vec3 noise = fbm(pos.xz * u_frequency);

    vec3 normal = normalize(vec3(-noise.y, 1.0, -noise.z));
    vec3 slope_normal = normalize(vec3(-noise.y, 1.0, -noise.z) * vec3(u_slope_damping, 1, u_slope_damping));

    float blend_factor = smoothstep(u_slope_range.x, u_slope_range.y, 1.0 - slope_normal.y);

    vec4 albedo = mix(u_low_slope_color, u_high_slope_color, blend_factor);

    vec3 light_dir = vec3(-1.0, 0.0, 1.0);
    float diffiuse = clamp(dot(light_dir, normal), 0.0, 1.0);

    vec3 specular_reflection = normalize(reflect(-light_dir, slope_normal));
    float specular_strength = pow(max(0.0, dot(normalize(u_camera_pos), specular_reflection)), 4.0);

    vec4 specular = specular_strength * vec4(0.12);
    vec4 direct = albedo * diffiuse;
    vec4 ambient = albedo * u_ambient;

    vec4 lit = clamp(direct + specular + ambient, vec4(0.0), vec4(1.0));

    // https://www.youtube.com/watch?v=k1zGz55EqfU
    float distance = length(pos - u_camera_pos);
    float fog_factor = 1.0 - exp(-u_fog_density * u_fog_density * distance * distance);
    lit = mix(lit, u_fog_color, fog_factor);

    frag_color = lit;
}
