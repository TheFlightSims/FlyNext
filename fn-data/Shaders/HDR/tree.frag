#version 330 core

in VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    float autumn_flag;
} fs_in;

uniform sampler2D color_tex;

uniform float cseason;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);

void main()
{
    vec4 texel = texture(color_tex, fs_in.texcoord);
    if (texel.a < 0.33)
        discard;

    // Seasonal color changes
    if (cseason < 1.5 && fs_in.autumn_flag > 0.0) {
        texel.r = min(1.0, (1.0 + 5.0 * cseason * fs_in.autumn_flag) * texel.r);
        texel.b = max(0.0, (1.0 - 8.0 * cseason) * texel.b);
    }

    vec3 color = eotf_inverse_sRGB(texel.rgb);

    vec3 N = normalize(fs_in.vertex_normal);

    gbuffer_pack(N, color, 0.0, 1.0, 1.0, vec3(0.0), 3u);
}
