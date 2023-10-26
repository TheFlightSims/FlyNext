#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;

uniform sampler2D gbuffer1_tex;

void main()
{
    fragColor = vec4(texture(gbuffer1_tex, texcoord).rgb, 1.0);
}
