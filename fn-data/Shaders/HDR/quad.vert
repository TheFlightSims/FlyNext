#version 330 core

out vec2 texcoord;

void main()
{
    vec2 pos = vec2(gl_VertexID % 2, gl_VertexID / 2) * 4.0 - 1.0;
    texcoord = pos * 0.5 + 0.5;
    gl_Position = vec4(pos, 0.0, 1.0);
}
