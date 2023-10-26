#version 330 core

layout(location = 0) out vec4 fragColor;

in vec3 vN;
in vec3 vP;
in vec2 texcoord;
in vec4 material_color;
in vec4 ap_color;

uniform sampler2D color_tex;

uniform mat4 osg_ViewMatrixInverse;
uniform vec4 fg_Viewport;

const float TRANSPARENT_METALLIC  = 0.0;
const float TRANSPARENT_ROUGHNESS = 0.1;

// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);
// shading_transparent.glsl
vec3 eval_lights_transparent(
    vec3 base_color, float metallic, float roughness, float occlusion,
    vec3 emissive, vec3 P, vec3 N, vec3 V, vec2 uv, vec4 ap,
    mat4 view_matrix_inverse);

void main()
{
    vec4 texel = texture(color_tex, texcoord);
    vec3 base_color = eotf_inverse_sRGB(texel.rgb) * material_color.rgb;
    float alpha = material_color.a * texel.a;

    vec3 N = normalize(vN);
    vec3 V = normalize(-vP);
    vec2 uv = (gl_FragCoord.xy - fg_Viewport.xy) / fg_Viewport.zw;

    vec3 color = eval_lights_transparent(
        base_color, TRANSPARENT_METALLIC, TRANSPARENT_ROUGHNESS, 1.0, vec3(0.0),
        vP, N, V, uv, ap_color, osg_ViewMatrixInverse);

    fragColor = vec4(color, alpha);
}
