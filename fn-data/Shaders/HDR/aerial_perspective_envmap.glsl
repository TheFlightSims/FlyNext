#version 330 core

uniform sampler2D transmittance_tex;

uniform vec3 fg_CameraPositionCart;
uniform vec3 fg_SunDirectionWorld;

const int AERIAL_PERSPECTIVE_ENVMAP_STEPS = 4;

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

vec4 get_aerial_perspective(vec3 pos)
{
    vec3 ray_origin = fg_CameraPositionCart;
    vec3 ray_end = pos;

    // Make sure both ray ends are above the ground.
    // We also apply a small bias to the ray end to prevent both points from
    // being at the exact same place due to floating point precision.
    float radius = get_earth_radius();
    ray_origin += max(0.0, radius - length(ray_origin));
    ray_end    += max(0.0, radius - length(ray_end)) + 1.0;

    vec3 ray_dir = ray_end - ray_origin;
    float t_d = length(ray_dir);
    ray_dir /= t_d;

    float t_max = get_ray_end(ray_origin, ray_dir, t_d);

    vec4 transmittance;
    vec4 L = compute_inscattering(ray_origin,
                                  ray_dir,
                                  t_max,
                                  fg_SunDirectionWorld,
                                  AERIAL_PERSPECTIVE_ENVMAP_STEPS,
                                  transmittance_tex,
                                  transmittance);

    vec4 ap;
    ap.rgb = linear_srgb_from_spectral_samples(L * get_sun_spectral_irradiance());
    ap.a = dot(transmittance, vec4(0.25));
    return ap;
}

vec3 mix_aerial_perspective(vec3 color, vec4 ap)
{
    return color * ap.a + ap.rgb;
}
