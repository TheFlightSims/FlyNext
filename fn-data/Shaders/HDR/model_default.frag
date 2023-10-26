#version 330 core

in VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec4 material_color;
} fs_in;

uniform sampler2D color_tex;

const float DEFAULT_METALLIC  = 0.0;
const float DEFAULT_ROUGHNESS = 0.5;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);

void main()
{
    vec3 texel = texture(color_tex, fs_in.texcoord).rgb;
    vec3 color = eotf_inverse_sRGB(texel) * fs_in.material_color.rgb;

    vec3 N = normalize(fs_in.vertex_normal);

    gbuffer_pack(N, color, DEFAULT_METALLIC, DEFAULT_ROUGHNESS, 1.0, vec3(0.0), 3u);
}
