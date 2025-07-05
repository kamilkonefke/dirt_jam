#version 330 core

layout(location = 0) in vec3 a_pos;
layout(location = 1) in vec3 a_tex_coord;
layout(location = 2) in vec3 a_normal;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

out vec3 frag_pos;

void main() {
    frag_pos = a_pos;
    gl_Position = projection * view * model * vec4(a_pos, 1.0);
}
