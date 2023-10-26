#version 330 core

layout(location = 0) out vec3 fragColor;

in vec2 texcoord;

uniform mat4 fg_ViewMatrixInverse;
uniform mat4 fg_ProjectionMatrix;

vec3 decodeNormal(vec2 f);
vec3 positionFromDepth(vec2 pos, float depth);

// gbuffer_unpack.glsl
void gbuffer_unpack(in vec2 texcoord,
                    out vec3 normal, out vec3 base_color, out float metallic,
                    out float roughness, out float occlusion, out vec3 emissive,
                    out uint mat_id);
// shading_opaque.glsl
vec3 eval_lights(
    vec3 base_color, float metallic, float roughness, float occlusion,
    vec3 emissive, vec3 P, vec3 N, vec3 V, vec2 uv,
    mat4 view_matrix_inverse, mat4 projection_matrix);
// pos_from_depth.glsl
vec3 get_view_space_from_depth(vec2 uv);

void main()
{
    vec3 N, base_color, emissive;
    float metallic, roughness, occlusion;
    uint mat_id;
    gbuffer_unpack(texcoord, N, base_color, metallic, roughness,
                   occlusion, emissive, mat_id);

    vec3 P = get_view_space_from_depth(texcoord);
    vec3 V = normalize(-P);

    fragColor = eval_lights(
        base_color, metallic, roughness, occlusion,
        emissive, P, N, V, texcoord,
        fg_ViewMatrixInverse, fg_ProjectionMatrix);
}
