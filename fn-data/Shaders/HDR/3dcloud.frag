#version 330 core

layout(location = 0) out vec4 fragColor;

// 3dcloud_common.frag
vec4 cloud_common_frag();
// exposure.glsl
vec3 apply_exposure(vec3 color);

void main()
{
    vec4 color = cloud_common_frag();

    // Only pre-expose when not rendering to the environment map.
    // We want the non-exposed radiance values for IBL.
    color.rgb = apply_exposure(color.rgb);

    fragColor = color;
}
