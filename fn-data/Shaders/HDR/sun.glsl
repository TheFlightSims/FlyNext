#version 330 core

uniform sampler2D transmittance_tex;

uniform float fg_EarthRadius;
uniform vec3 fg_SunDirectionWorld;
uniform float fg_CameraDistanceToEarthCenter;
uniform float fg_SunZenithCosTheta;

const float ATMOSPHERE_RADIUS = 6471e3;

// atmos_spectral.glsl
vec4 get_sun_spectral_irradiance();
vec3 linear_srgb_from_spectral_samples(vec4 L);

/*
 * Get the Sun radiance at a point 'p' in world space.
 * We cannot use the Sun extraterrestial irradiance directly because it will be
 * attenuated by the transmittance of the atmospheric medium.
 */
vec3 get_sun_radiance(vec3 p)
{
    float distance_to_earth_center = length(p);
    float normalized_altitude = (distance_to_earth_center - fg_EarthRadius)
        / (ATMOSPHERE_RADIUS - fg_EarthRadius);

    vec3 zenith_dir = p / distance_to_earth_center;
    float sun_cos_theta = dot(zenith_dir, fg_SunDirectionWorld);

    float u = sun_cos_theta * 0.5 + 0.5;
    float v = clamp(normalized_altitude, 0.0, 1.0);
    vec4 transmittance = texture(transmittance_tex, vec2(u, v));

    vec4 L = get_sun_spectral_irradiance() * transmittance;
    return linear_srgb_from_spectral_samples(L);
}

vec3 get_sun_radiance_sea_level()
{
    vec2 uv = vec2(fg_SunZenithCosTheta * 0.5 + 0.5, 0.0);
    vec4 transmittance = texture(transmittance_tex, uv);
    vec4 L = get_sun_spectral_irradiance() * transmittance;
    return linear_srgb_from_spectral_samples(L);
}
