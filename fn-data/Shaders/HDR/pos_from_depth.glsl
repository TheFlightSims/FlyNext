#version 330 core

uniform sampler2D depth_tex;

uniform vec2 fg_NearFar;
uniform mat4 fg_ViewMatrixInverse;
uniform mat4 fg_ProjectionMatrixInverse;

/*
 * Reconstruct the view space position from the depth buffer. Mostly used by
 * fullscreen post-processing shaders.
 *
 * Given a 2D screen UV in the range [0,1] and a depth value from the depth
 * buffer, also in the [0,1] range, return the view space position.
 */
vec3 get_view_space_from_depth(vec2 uv, float depth, mat4 proj_matrix_inverse)
{
    /*
     * We are using a reversed depth buffer. 1.0 corresponds to the near plane
     * and 0.0 to the far plane. We convert this back to NDC space by doing
     * 1.0 - depth          to undo the depth reversal
     * 2.0 * depth - 1.0    to transform it to NDC space [-1,1]
     */
    vec4 ndc_p = vec4(uv * 2.0 - 1.0, 1.0 - depth * 2.0, 1.0);
    vec4 vs_p = proj_matrix_inverse * ndc_p;
    return vs_p.xyz / vs_p.w;
}

vec3 get_view_space_from_depth(vec2 uv, float depth)
{
    return get_view_space_from_depth(uv, depth, fg_ProjectionMatrixInverse);
}

vec3 get_view_space_from_depth(vec2 uv)
{
    return get_view_space_from_depth(uv, texture(depth_tex, uv).r);
}

vec3 get_world_space_from_depth(vec2 uv, float depth)
{
    vec4 vs_p = vec4(get_view_space_from_depth(uv, depth), 1.0);
    return (fg_ViewMatrixInverse * vs_p).xyz;
}

vec3 get_world_space_from_depth(vec2 uv)
{
    return get_world_space_from_depth(uv, texture(depth_tex, uv).r);
}

float linearize_depth(float depth)
{
    // Undo the depth reversal
    float z = 1.0 - depth;
    return 2.0 * fg_NearFar.x
        / (fg_NearFar.y + fg_NearFar.x - z * (fg_NearFar.y - fg_NearFar.x));
}
