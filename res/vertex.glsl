#version 330 core

layout(location = 0) in vec3 a_pos;

layout(std140) uniform ubo {
    mat4 u_mvp;
    vec4 u_albedo;
    vec4 u_ambient;
    float u_frequency;
    float u_amplitude;
    float u_lacunarity;
    int u_octaves;
};

out vec3 pos;

float pseudo(vec2 s) {
    vec2 k = vec2(54.562346, 42.6525);
    return fract(sin(dot(mod(s, 256.0), k)) * 51.5266);
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

vec3 fbm(in vec2 p) {
    float lacunarity = u_lacunarity;
    float amplitude = u_amplitude;

    float height = 0.0;
    vec2 gradient = vec2(0.0);

    mat2 m = mat2(1.0, 0.0, 0.0, 1.0);

    mat2 m2 = mat2(cos(0.5), -sin(0.5),
                    sin(0.5), cos(0.50));

    mat2 m2i = inverse(m2);

    for(int i = 0; i < u_octaves; i++) {
        vec3 noise = perlin(p);

        height += amplitude * noise.x;
        gradient += amplitude * m * noise.yz;

        amplitude *= 0.2;

        p = lacunarity * m2 * p;
        m = lacunarity * m2i * m;
    }

    return vec3(height, gradient);
}

void main() {
    pos = a_pos;
    gl_Position = u_mvp * vec4(a_pos, 1.0);
    gl_Position.y += fbm(a_pos.xz * u_frequency).x;
}
