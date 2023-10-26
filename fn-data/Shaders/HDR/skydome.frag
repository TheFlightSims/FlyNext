#version 330 core

layout(location = 0) out vec4 fragColor;

in vec3 ray_dir;
in vec3 ray_dir_view;

uniform bool is_envmap;
uniform sampler2D sky_view_tex;
uniform sampler2D transmittance_tex;

uniform vec3 fg_SunDirection;
uniform float fg_CameraDistanceToEarthCenter;
uniform float fg_EarthRadius;
uniform vec3 fg_CameraViewUp;

const float ATMOSPHERE_RADIUS = 6471e3;

const float SUN_HALF_ANGULAR_DIAMETER     = 0.0047560222116845481; // radians(0.545 deg / 2)
const float SUN_COS_HALF_ANGULAR_DIAMETER = 0.9999886901476798392; // cos(radians(0.545 deg / 2))
const float SUN_SIN_HALF_ANGULAR_DIAMETER = 0.0047560042817014138; // sin(radians(0.545 deg / 2))

// math.glsl
float M_PI();
float sqr(float x);
float saturate(float x);
// atmos_spectral.glsl
vec4 get_sun_spectral_irradiance();
vec3 linear_srgb_from_spectral_samples(vec4 L);
// exposure.glsl
vec3 apply_exposure(vec3 color);

/*
 * Limb darkening
 * http://www.physics.hmc.edu/faculty/esin/a101/limbdarkening.pdf
 */
vec4 get_sun_darkening_factor(float cos_theta)
{
    // Coefficients sampled for wavelengths 630, 560, 490, 430 nm
    const vec4 u = vec4(1.0);
    const vec4 alpha = vec4(0.429, 0.502, 0.575, 0.643);
    float sin_theta = sqrt(1.0 - sqr(cos_theta));
    float center_to_edge = saturate(sin_theta / SUN_SIN_HALF_ANGULAR_DIAMETER);
    float mu = sqrt(1.0 - sqr(center_to_edge));
    vec4 factor = vec4(1.0) - u * (vec4(1.0) - pow(vec4(mu), alpha));
    return factor;
}

void main()
{
    vec3 frag_ray_dir = normalize(ray_dir);
    float azimuth = atan(frag_ray_dir.y, frag_ray_dir.x) / M_PI() * 0.5 + 0.5;
    // Undo the non-linear transformation from the sky-view LUT
    float l = asin(frag_ray_dir.z);
    float elev = sqrt(abs(l) / (M_PI() * 0.5)) * sign(l) * 0.5 + 0.5;

    vec4 sky_radiance = texture(sky_view_tex, vec2(azimuth, elev));
    // When computing the sky texture we assumed an unitary light source.
    // Now multiply by the sun irradiance.
    sky_radiance *= get_sun_spectral_irradiance();

    if (is_envmap == false) {
        // Render the Sun disk
        vec3 vs_ray_dir = normalize(ray_dir_view);
        float cos_theta = dot(vs_ray_dir, fg_SunDirection);

        if (cos_theta >= SUN_COS_HALF_ANGULAR_DIAMETER) {
            float normalized_altitude =
                (fg_CameraDistanceToEarthCenter - fg_EarthRadius)
                / (ATMOSPHERE_RADIUS - fg_EarthRadius);

            float sun_zenith_cos_theta = dot(-vs_ray_dir, fg_CameraViewUp);

            vec2 uv = vec2(sun_zenith_cos_theta * 0.5 + 0.5,
                           clamp(normalized_altitude, 0.0, 1.0));
            vec4 transmittance = texture(transmittance_tex, uv);

            vec4 darkening_factor = get_sun_darkening_factor(cos_theta);

            // To get the actual sun radiance we should divide the irradiance
            // by the solid angle subtended by the Sun, but the resulting
            // radiance is too big to store in an rgb16f buffer. Also the bloom
            // gets blown out too much.
            // Instead, just multiply by a fixed value that looks good enough.
            vec4 sun_radiance = get_sun_spectral_irradiance() * 500.0;

            sun_radiance *= transmittance * darkening_factor;

            sky_radiance += sun_radiance;
        }
    }

    vec3 sky_color = linear_srgb_from_spectral_samples(sky_radiance);

    if (is_envmap == false) {
        // Only pre-expose when not rendering to the environment map.
        // We want the non-exposed radiance values for IBL.
        sky_color = apply_exposure(sky_color);
    }

    fragColor = vec4(sky_color, 1.0);
}
