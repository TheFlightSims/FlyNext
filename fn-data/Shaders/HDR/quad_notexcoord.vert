#version 330 core

void main()
{
    vec2 pos = vec2(gl_VertexID % 2, gl_VertexID / 2) * 4.0 - 1.0;
    gl_Position = vec4(pos, 0.0, 1.0);
}
