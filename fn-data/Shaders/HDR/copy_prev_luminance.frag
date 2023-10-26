#version 330 core

layout(location = 0) out float fragColor;

uniform sampler2D lum_tex;

void main()
{
    fragColor = texelFetch(lum_tex, ivec2(0), 0).r;
}
