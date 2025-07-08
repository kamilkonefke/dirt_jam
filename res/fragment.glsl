#version 330 core

out vec4 frag_color;
in vec3 pos;

uniform vec4 albedo_color = vec4(0.106, 0.6, 0.545, 1.0);
uniform vec4 ambient_color = vec4(0.7, 0.7, 0.7, 1.0);
uniform float noise_frequency = 1.0;
uniform float noise_amplitude = 1.0;

float pseudo(vec2 s) {
    vec2 k = vec2(54.562346, 42.6525);
    return fract(sin(dot(mod(s, 256.0), k)) * 51.5266);
}

vec2 rand_gradient(float seed) {
    float angle = seed * 61.2453;
    return vec2(cos(angle), sin(angle));
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

    vec2 g00 = rand_gradient(pseudo(c00));
    vec2 g10 = rand_gradient(pseudo(c10));
    vec2 g01 = rand_gradient(pseudo(c01));
    vec2 g11 = rand_gradient(pseudo(c11));

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

void main() {
    vec3 noise = perlin(pos.xz * noise_frequency) * noise_amplitude;

    vec3 normal = normalize(vec3(-noise.y, 1.0, -noise.z));

    float diffiuse = clamp(dot(vec3(0.0, 1.0, 2.0), normal), 0.0, 1.0);

    vec4 direct = albedo_color * diffiuse;
    vec4 ambient = albedo_color * ambient_color;

    vec4 lit = clamp(direct + ambient, vec4(0.0), vec4(1.0));

    frag_color = pow(lit, vec4(2.2));
}
