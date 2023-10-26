#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;

uniform sampler2D depth_tex;

// pos_from_depth.glsl
float linearize_depth(float depth);

void main()
{
    float depth = texture(depth_tex, texcoord).r;
    fragColor = vec4(vec3(linearize_depth(depth)), 1.0);
}
