#version 330 core

out vec2 texcoord;
out vec4 pos_pos;

uniform sampler2D color_tex;

const float FXAA_SUBPIX_SHIFT = 1.0/4.0;

void main()
{
    vec2 pos = vec2(gl_VertexID % 2, gl_VertexID / 2) * 4.0 - 1.0;
    texcoord = pos * 0.5 + 0.5;

    vec2 rcpFrame = 1.0 / textureSize(color_tex, 0);
    pos_pos.xy = texcoord;
    pos_pos.zw = texcoord - (rcpFrame * (0.5 + FXAA_SUBPIX_SHIFT));

    gl_Position = vec4(pos, 0.0, 1.0);
}
