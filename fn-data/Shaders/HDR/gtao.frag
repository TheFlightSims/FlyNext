/*
 * An implementation of GTAO (Ground Truth Ambient Occlusion)
 * Based on 'Practical Real-Time Strategies for Accurate Indirect Occlusion' by
 * Jorge Jimenez et al.
 * https://www.activision.com/cdn/research/Practical_Real_Time_Strategies_for_Accurate_Indirect_Occlusion_NEW%20VERSION_COLOR.pdf
 * https://blog.selfshadow.com/publications/s2016-shading-course/activision/s2016_pbs_activision_occlusion.pdf
 * Most of the shader is based on Algorithm 1 of the paper.
 */

#version 330 core

layout(location = 0) out float fragColor;

in vec2 texcoord;

uniform sampler2D gbuffer0_tex;
uniform sampler2D depth_tex;

uniform float world_radius;

uniform vec4 fg_Viewport;
uniform vec2 fg_PixelSize;
uniform mat4 fg_ProjectionMatrix;

const float SLICE_COUNT = 3.0;
const float DIRECTION_SAMPLE_COUNT = 4.0;

// math.glsl
float M_PI();
float M_PI_2();
// normal_encoding.glsl
vec3 decode_normal(vec2 f);
// pos_from_depth.glsl
vec3 get_view_space_from_depth(vec2 uv, float depth);

void main()
{
    float depth = textureLod(depth_tex, texcoord, 0.0).r;
    // Ignore the background
    if (depth == 0.0) {
        fragColor = 0.0;
        discard;
    }
    // Slightly push the depth towards the camera to avoid imprecision artifacts
    depth = clamp(depth * 1.00001, 0.0, 1.0);

    // View space normal
    vec3 N = decode_normal(texture(gbuffer0_tex, texcoord).rg);
    // Fragment position in view space
    vec3 P = get_view_space_from_depth(texcoord, depth);
    // View vector in view space
    vec3 V = normalize(-P);

    float noise_dir = 0.0625 * float(
        ((int(gl_FragCoord.x) + int(gl_FragCoord.y) & 3) << 2) +
        (int(gl_FragCoord.x) & 3));

    float noise_offset = 0.25 * float(int(gl_FragCoord.x) + int(gl_FragCoord.y) & 3);

    // Transform the world space hemisphere radius to screen space pixels with
    // the following formula:
    //      radius * 1 / [ tan(fovy / 2) * z_distance ] * (screen_size.y / 2)
    // In our case, the (1,1) element of the projection matrix contains
    // 1 / tan(fovy / 2), so we can use that directly.
    // z_distance is the distance from the camera to the fragment, which is
    // just the positive z component of the view space fragment position.
	float radius_pixels = world_radius * (fg_ProjectionMatrix[1][1] / abs(P.z))
        * fg_Viewport.w * 0.5;

    float visibility = 0.0;

    for (float i = 0.0; i < SLICE_COUNT; ++i) {
        float phi = ((i + noise_dir) / SLICE_COUNT) * M_PI();
        float cos_phi = cos(phi);
        float sin_phi = sin(phi);
        vec2 omega = vec2(cos_phi, sin_phi);

        vec3 dir = vec3(omega, 0.0);
        vec3 ortho_dir = dir - dot(dir, V) * V;
        vec3 axis = normalize(cross(dir, V));
        vec3 proj_N = N - axis * dot(N, axis);
        float proj_N_len = max(1e-5, length(proj_N));

        float sgnN = sign(dot(ortho_dir, proj_N));
        float cosN = clamp(dot(proj_N, V) / proj_N_len, 0.0, 1.0);
        float n = sgnN * acos(cosN);

        float hcos1 = -1.0, hcos2 = -1.0;

        for (float j = 0.0; j < DIRECTION_SAMPLE_COUNT; ++j) {
            float s = (j + noise_offset) / DIRECTION_SAMPLE_COUNT;
            s += 1.2 / radius_pixels;
            vec2 s_offset = s * radius_pixels * omega;
            s_offset = round(s_offset) * fg_PixelSize;

            vec2 s_texcoord1 = texcoord - s_offset;
            float s_depth1 = textureLod(depth_tex, s_texcoord1, 0.0).r;
            if (s_depth1 == 0.0) {
                // Skip background
                continue;
            }
            vec3 s_pos1 = get_view_space_from_depth(s_texcoord1, s_depth1);

            vec2 s_texcoord2 = texcoord + s_offset;
            float s_depth2 = textureLod(depth_tex, s_texcoord2, 0.0).r;
            if (s_depth2 == 0.0) {
                // Skip background
                continue;
            }
            vec3 s_pos2 = get_view_space_from_depth(s_texcoord2, s_depth2);

            vec3 s_horizon1 = s_pos1 - P;
            vec3 s_horizon2 = s_pos2 - P;
            float s_horizon1_len = length(s_horizon1);
            float s_horizon2_len = length(s_horizon2);

            float shcos1 = dot(s_horizon1 / s_horizon1_len, V);
            float shcos2 = dot(s_horizon2 / s_horizon2_len, V);

            // Section 4.3: Bounding the sampling area
            // Attenuate samples that are further away
            float weight1 = clamp((1.0 - s_horizon1_len / world_radius) * 2.0, 0.0, 1.0);
            float weight2 = clamp((1.0 - s_horizon2_len / world_radius) * 2.0, 0.0, 1.0);
            shcos1 = mix(-1.0, shcos1, weight1);
            shcos2 = mix(-1.0, shcos2, weight2);

            hcos1 = max(hcos1, shcos1);
            hcos2 = max(hcos2, shcos2);
        }

        float h1 = n + max(-acos(hcos1) - n, -M_PI_2());
        float h2 = n + min( acos(hcos2) - n,  M_PI_2());

        float sinN = sin(n);
        float h1_2 = 2.0 * h1;
        float h2_2 = 2.0 * h2;
        float vd = 0.25 * ((cosN + h1_2 * sinN - cos(h1_2 - n)) +
                           (cosN + h2_2 * sinN - cos(h2_2 - n)));
        visibility += proj_N_len * vd;
    }
    visibility /= float(SLICE_COUNT);

    fragColor = clamp(visibility, 0.0, 1.0);
}
