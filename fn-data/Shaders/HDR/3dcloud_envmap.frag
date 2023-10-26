#version 330 core

layout(location = 0) out vec4 fragColor;

// 3dcloud_common.frag
vec4 cloud_common_frag();

void main()
{
    vec4 color = cloud_common_frag();
    fragColor = color;
}
