#version 330 core

layout(location = 0) in vec3 a_pos;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

uniform float noise_frequency = 1.0;
uniform float noise_amplitude = 1.0;

out vec3 pos;

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

    vec2 bl = min;
    vec2 br = vec2(max.x, min.y);
    vec2 tl = vec2(min.x, max.y);
    vec2 tr = max;

    vec2 gbl = rand_gradient(pseudo(bl));
    vec2 gbr = rand_gradient(pseudo(br));
    vec2 gtl = rand_gradient(pseudo(tl));
    vec2 gtr = rand_gradient(pseudo(tr));

    vec2 p0 = remainder;
    vec2 p1 = p0 - vec2(1.0);

    vec2 pbl = p0;
    vec2 pbr = vec2(p1.x, p0.y);
    vec2 ptl = vec2(p0.x, p1.y);
    vec2 ptr = p1;

    float a = dot(gbl, pbl);
    float b = dot(gbr, pbr);
    float c = dot(gtl, ptl);
    float d = dot(gtr, ptr);

    vec2 u = quintic_interpolation(remainder);
    vec2 du = quintic_derivative(remainder);

    float noise = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);
    vec2 gradient = gbl + u.x * (gbr - gbl) + u.y * (gbr - gbl) + u.x * u.y * (gbl - gtl - gbr + gtr) + du * (u.yx * (a - b - c + d) + vec2(b, c) - a);

    return vec3(noise, gradient);
}

void main() {
    pos = a_pos;
    gl_Position = projection * view * model * vec4(a_pos, 1.0);
    gl_Position.y += perlin(a_pos.xz * noise_frequency).x * noise_amplitude;
}
