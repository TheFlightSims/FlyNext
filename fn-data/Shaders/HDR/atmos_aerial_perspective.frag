/*
 * Render the aerial perspective LUT, similar to
 * "A Scalable and Production Ready Sky and Atmosphere Rendering Technique"
 *     by Sébastien Hillaire (2020).
 *
 * Unlike the paper, we are using a tiled 2D texture instead of a true 3D
 * texture. For some reason the overhead of rendering to a texture many times
 * (the depth of the 3D texture) seems to be too high, probably because OSG is
 * not sharing state between those passes.
 */

#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;

uniform sampler2D transmittance_lut;

uniform mat4 fg_ViewMatrixInverse;
uniform vec3 fg_CameraPositionCart;
uniform vec3 fg_SunDirectionWorld;

const float AP_SLICE_COUNT = 32.0;
const float AP_MAX_DEPTH = 128000.0;

const int AERIAL_PERSPECTIVE_STEPS = 10;
const float RADIUS_OFFSET = 10.0;

// pos_from_depth.glsl
vec3 get_view_space_from_depth(vec2 uv, float depth);
// atmos.glsl
float get_earth_radius();
float get_ray_end(vec3 ray_origin, vec3 ray_dir, float t_max);
vec4 compute_inscattering(in vec3 ray_origin,
                          in vec3 ray_dir,
                          in float t_max,
                          in vec3 sun_dir,
                          in int steps,
                          in sampler2D transmittance_lut,
                          out vec4 transmittance);
// atmos_spectral.glsl
vec4 get_sun_spectral_irradiance();
vec3 linear_srgb_from_spectral_samples(vec4 L);

void main()
{
    // Account for the depth slice we are currently in. Depth goes from 0 to
    // DEPTH_RANGE in a squared distribution. The first slice is not 0 since
    // that would waste a slice.
    float x = texcoord.x * AP_SLICE_COUNT;
    float slice = ceil(x);
    float w = slice / AP_SLICE_COUNT; // [0,1]
    float depth = w*w * AP_MAX_DEPTH;

    vec2 coord = vec2(fract(x), texcoord.y);

    vec3 frag_pos = get_view_space_from_depth(coord, 1.0);
    vec3 ray_dir = vec4(fg_ViewMatrixInverse * vec4(normalize(frag_pos), 0.0)).xyz;

    vec3 ray_origin = fg_CameraPositionCart;

    vec3 ray_end = ray_origin + ray_dir * depth;
    float t_max = depth;

    if (length(ray_end) <= (get_earth_radius() + RADIUS_OFFSET)) {
        ray_end = normalize(ray_end) * (get_earth_radius() + RADIUS_OFFSET + 1.0);

        ray_dir = ray_end - ray_origin;
        t_max = length(ray_dir);
        ray_dir /= t_max;
    }

    vec4 transmittance;
    vec4 L = compute_inscattering(ray_origin,
                                  ray_dir,
                                  t_max,
                                  fg_SunDirectionWorld,
                                  AERIAL_PERSPECTIVE_STEPS,
                                  transmittance_lut,
                                  transmittance);
    // In-scattering
    fragColor.rgb = linear_srgb_from_spectral_samples(
        L * get_sun_spectral_irradiance());
    // Transmittance
    fragColor.a = dot(transmittance, vec4(0.25));
}
