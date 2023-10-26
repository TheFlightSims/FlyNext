#version 330 core

in VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
} fs_in;

uniform sampler2D base_color_tex;
uniform sampler2D orm_tex;
uniform sampler2D emissive_tex;

uniform vec4 base_color_factor;
uniform float metallic_factor;
uniform float roughness_factor;
uniform vec3 emissive_factor;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);
// normalmap.glsl
vec3 perturb_normal(vec3 N, vec3 V, vec2 texcoord);

void main()
{
    vec4 base_color_texel = texture(base_color_tex, fs_in.texcoord);
    vec3 base_color = eotf_inverse_sRGB(base_color_texel.rgb) * base_color_factor.rgb;

    vec3 orm = texture(orm_tex, fs_in.texcoord).rgb;
    float occlusion = orm.r;
    float roughness = orm.g * roughness_factor;
    float metallic = orm.b * metallic_factor;
    vec3 emissive = texture(emissive_tex, fs_in.texcoord).rgb * emissive_factor;

    vec3 N = normalize(fs_in.vertex_normal);
    N = perturb_normal(N, fs_in.view_vector, fs_in.texcoord);

    gbuffer_pack(N, base_color, metallic, roughness, occlusion, emissive, 3u);
}
