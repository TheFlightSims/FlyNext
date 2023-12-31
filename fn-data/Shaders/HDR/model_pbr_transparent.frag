#version 330 core

layout(location = 0) out vec4 fragColor;

in VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
    vec4 ap_color;
} fs_in;

uniform sampler2D base_color_tex;
uniform sampler2D orm_tex;
uniform sampler2D emissive_tex;

uniform vec4 base_color_factor;
uniform float metallic_factor;
uniform float roughness_factor;
uniform vec3 emissive_factor;
uniform float alpha_cutoff;

uniform mat4 osg_ViewMatrixInverse;
uniform mat4 osg_ProjectionMatrix;
uniform vec4 fg_Viewport;

// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);
// shading_transparent.glsl
vec3 eval_lights_transparent(
    vec3 base_color, float metallic, float roughness, float occlusion,
    vec3 emissive, vec3 P, vec3 N, vec3 V, vec2 uv, vec4 ap,
    mat4 view_matrix_inverse);
// normalmap.glsl
vec3 perturb_normal(vec3 N, vec3 V, vec2 texcoord);

void main()
{
    vec4 base_color_texel = texture(base_color_tex, fs_in.texcoord);
    vec4 base_color = vec4(eotf_inverse_sRGB(base_color_texel.rgb), base_color_texel.a)
        * base_color_factor;
    if (base_color.a < alpha_cutoff)
        discard;

    vec3 orm = texture(orm_tex, fs_in.texcoord).rgb;
    float occlusion = orm.r;
    float roughness = orm.g * roughness_factor;
    float metallic = orm.b * metallic_factor;
    vec3 emissive = texture(emissive_tex, fs_in.texcoord).rgb * emissive_factor;

    vec3 V = normalize(-fs_in.view_vector);
    vec2 uv = (gl_FragCoord.xy - fg_Viewport.xy) / fg_Viewport.zw;

    vec3 N = normalize(fs_in.vertex_normal);
    N = perturb_normal(N, fs_in.view_vector, fs_in.texcoord);

    vec3 color = eval_lights_transparent(
        base_color.rgb, metallic, roughness, occlusion, emissive,
        fs_in.view_vector, N, V, uv, fs_in.ap_color, osg_ViewMatrixInverse);

    fragColor = vec4(color, base_color.a);
}
