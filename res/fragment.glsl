#version 330 core

layout(location = 0) out vec4 frag_color;

layout(std140) uniform ubo {
    mat4 u_mvp;
    vec4 u_albedo;
    vec4 u_ambient;
    float u_frequency;
    float u_amplitude;
    float u_lacunarity;
    int u_octaves;
};

in vec3 pos;

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
    vec3 noise = fbm(pos.xz * u_frequency);

    vec3 normal = normalize(vec3(-noise.y, 1.0, -noise.z));

    float diffiuse = clamp(dot(vec3(0.5, 0.0, 1.0), normal), 0.0, 1.0);

    vec4 direct = u_albedo * diffiuse;
    vec4 ambient = u_albedo * u_ambient;

    vec4 lit = clamp(direct + ambient, vec4(0.0), vec4(1.0));

    frag_color = pow(lit, vec4(2.2));
}
