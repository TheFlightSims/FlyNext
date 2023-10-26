#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;

uniform sampler2D gbuffer0_tex;
uniform sampler2D gbuffer1_tex;
uniform sampler2D gbuffer2_tex;

void main()
{
    fragColor = vec4(texture(gbuffer2_tex, texcoord).a,
                     texture(gbuffer0_tex, texcoord).b,
                     texture(gbuffer1_tex, texcoord).a,
                     1.0);
}
