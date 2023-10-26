#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;

uniform sampler2D gbuffer0_tex;

void main()
{
    fragColor = vec4(texture(gbuffer0_tex, texcoord).rg, 0.0, 1.0);
}
