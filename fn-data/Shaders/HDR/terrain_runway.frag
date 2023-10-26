#version 330 core

in VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
    vec3 rawpos;
} fs_in;

uniform sampler2D color_tex;
uniform sampler3D noise_tex;

const float NORMALMAP_SCALE = 8.0;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);
// normalmap.glsl
vec3 perturb_normal(vec3 N, vec3 V, vec2 texcoord);

void main()
{
    vec4 texel = texture(color_tex, fs_in.texcoord);
    vec3 color = eotf_inverse_sRGB(texel.rgb);

    vec3 N = normalize(fs_in.vertex_normal);
    N = perturb_normal(N, fs_in.view_vector, fs_in.texcoord * NORMALMAP_SCALE);

    vec3 noise_large = texture(noise_tex, fs_in.rawpos * 0.0045).rgb;
    vec3 noise_small = texture(noise_tex, fs_in.rawpos).rgb;

    float mix_factor = noise_large.r * noise_large.g * noise_large.b * 350.0;
    mix_factor = smoothstep(0.0, 1.0, mix_factor);

    color = mix(color, noise_small, 0.15);

    float roughness = mix(0.94, 0.98, mix_factor);

    gbuffer_pack(N, color, 0.0, roughness, 1.0, vec3(0.0), 3u);
}
