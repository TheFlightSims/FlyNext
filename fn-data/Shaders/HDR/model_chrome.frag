#version 330 core

in vec3 vertex_normal;

const float CHROME_METALLIC  = 1.0;
const float CHROME_ROUGHNESS = 0.1;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);

void main()
{
    vec3 N = normalize(vertex_normal);
    gbuffer_pack(N, vec3(1.0), CHROME_METALLIC, CHROME_ROUGHNESS, 1.0, vec3(0.0), 3u);
}
