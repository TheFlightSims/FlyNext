/*
 * Common atmosphere rendering functions
 *
 * See https://www.shadertoy.com/view/msXXDS for a more complete description
 * of what the shader does and more references.
 *
 * All 4-component vectors in this file represent values sampled for the
 * following wavelengths: 630, 560, 490, 430 nm
 */

#version 330 core

uniform vec4 aerosol_absorption_cross_section;
uniform vec4 aerosol_scattering_cross_section;
uniform float aerosol_base_density;
uniform float aerosol_relative_background_density;
uniform float aerosol_scale_height;
uniform float fog_density;
uniform float fog_scale_height;
uniform float ozone_mean_dobson;
uniform vec4 ground_albedo;

uniform float fg_EarthRadius;

const float RAYLEIGH_PHASE_SCALE = 0.05968310365946075091; // 3/(16*pi)
const float HENYEY_ASYMMETRY = 0.8;
const float HENYEY_ASYMMETRY2 = HENYEY_ASYMMETRY*HENYEY_ASYMMETRY;

/*
 * Rayleigh scattering coefficient at sea level, units m^-1
 * "Rayleigh-scattering calculations for the terrestrial atmosphere"
 *     by Anthony Bucholtz (1995).
 */
const vec4 molecular_scattering_coefficient_base =
    vec4(6.605e-6, 1.067e-5, 1.842e-5, 3.156e-5);

/*
 * Fog scattering/extinction cross section, units m^2 / molecules
 * Mie theory results for IOR of 1.333. Particle size is a log normal
 * distribution of mean diameter=15 and std deviation=0.4
 */
const vec4 fog_scattering_cross_section =
    vec4(5.015e-10, 4.987e-10, 4.966e-10, 4.949e-10);

/*
 * Ozone absorption cross section, units m^2 / molecules
 * "High spectral resolution ozone absorption cross-sections"
 * by V. Gorshelev et al. (2014).
 */
const vec4 ozone_absorption_cross_section =
    vec4(3.472e-25, 3.914e-25, 1.349e-25, 11.03e-27);

// math.glsl
float M_PI();
float M_2PI();
float M_1_PI();
float M_1_4PI();
float sqr(float x);

//------------------------------------------------------------------------------

float get_earth_radius()
{
    return fg_EarthRadius;
}

float get_atmosphere_radius()
{
    return 6471e3; // m
}

/*
 * Helper function to obtain the transmittance to the top of the atmosphere
 * from the precomputed transmittance LUT.
 */
vec4 transmittance_from_lut(sampler2D lut, float cos_theta, float normalized_altitude)
{
    float u = clamp(cos_theta * 0.5 + 0.5, 0.0, 1.0);
    float v = clamp(normalized_altitude, 0.0, 1.0);
    return texture(lut, vec2(u, v));
}

/*
 * Returns the distance between ro and the first intersection with the sphere
 * or -1.0 if there is no intersection. The sphere's origin is (0,0,0).
 * -1.0 is also returned if the ray is pointing away from the sphere.
 */
float ray_sphere_intersection(vec3 ro, vec3 rd, float radius)
{
    float b = dot(ro, rd);
    float c = dot(ro, ro) - radius*radius;
    if (c > 0.0 && b > 0.0) return -1.0;
    float d = b*b - c;
    if (d < 0.0) return -1.0;
    if (d > b*b) return (-b+sqrt(d));
    return (-b-sqrt(d));
}

/*
 * Rayleigh phase function.
 */
float molecular_phase_function(float cos_theta)
{
    return RAYLEIGH_PHASE_SCALE * (1.0 + cos_theta*cos_theta);
}

/*
 * Henyey-Greenstrein phase function.
 */
float aerosol_phase_function(float cos_theta)
{
    float den = 1.0 + HENYEY_ASYMMETRY2 + 2.0 * HENYEY_ASYMMETRY * cos_theta;
    return M_1_4PI() * (1.0 - HENYEY_ASYMMETRY2) / (den * sqrt(den));
}

/*
 * Get the approximated multiple scattering contribution for a given point
 * within the atmosphere.
 */
vec4 get_multiple_scattering(sampler2D transmittance_lut,
                             float cos_theta,
                             float normalized_height,
                             float d)
{
    // Solid angle subtended by the planet from a point at d distance
    // from the planet center.
    float omega = M_2PI() * (1.0 - sqrt(sqr(d) - sqr(get_earth_radius())) / d);
    omega = max(0.0, omega);

    vec4 T_to_ground = transmittance_from_lut(transmittance_lut, cos_theta, 0.0);

    vec4 T_ground_to_sample =
        transmittance_from_lut(transmittance_lut, 1.0, 0.0) /
        transmittance_from_lut(transmittance_lut, 1.0, normalized_height);

    // 2nd order scattering from the ground
    vec4 L_ground = M_1_4PI() * omega * (ground_albedo * M_1_PI())
        * T_to_ground * T_ground_to_sample * max(0.0, cos_theta);

    // Fit of Earth's multiple scattering coming from other points in the atmosphere
    vec4 L_ms = 0.02 * vec4(0.217, 0.347, 0.594, 1.0)
        * (1.0 / (1.0 + 5.0 * exp(-17.92 * cos_theta)));

    return L_ms + L_ground;
}

/*
 * Return the molecular volume scattering coefficient (m^-1) for a given altitude
 * in kilometers.
 */
vec4 get_molecular_scattering_coefficient(float h)
{
    return molecular_scattering_coefficient_base
        * exp(-0.07771971 * pow(h, 1.16364243));
}

/*
 * Return the molecular volume absorption coefficient (m^-1) for a given altitude
 * in kilometers.
 */
vec4 get_molecular_absorption_coefficient(float h)
{
    h += 1e-4; // Avoid division by 0
    float t = log(h) - 3.22261;
    float density = 3.78547397e17 * (1.0 / h) * exp(-t * t * 5.55555555);
    return ozone_absorption_cross_section * ozone_mean_dobson * density;
}

/*
 * Return the aerosol density for a given altitude in kilometers.
 */
float get_aerosol_density(float h)
{
    return aerosol_base_density * (exp(-h / aerosol_scale_height)
                                   + aerosol_relative_background_density);
}

/*
 * Return the fog volume scattering coefficient (m^-1) for a given altitude in
 * kilometers.
 *
 * Fog (or mist, depending on density) is a special kind of aerosol consisting
 * of water droplets or ice crystals. Visibility is mostly dependent on fog.
 */
vec4 get_fog_scattering_coefficient(float h)
{
    if (fog_density > 0.0) {
        return fog_scattering_cross_section * fog_density
            * exp(-h / fog_scale_height);
    } else {
        return vec4(0.0);
    }
}

/*
 * Get the collision coefficients (scattering and absorption) of the
 * atmospheric medium for a given point at an altitude h in meters.
 */
void get_atmosphere_collision_coefficients(in float h,
                                           out vec4 aerosol_absorption,
                                           out vec4 aerosol_scattering,
                                           out vec4 molecular_absorption,
                                           out vec4 molecular_scattering,
                                           out vec4 extinction)
{
    h = max(h, 1e-3); // In case height is negative
    h *= 1e-3; // To km

    // Molecules
    molecular_absorption = get_molecular_absorption_coefficient(h);
    molecular_scattering = get_molecular_scattering_coefficient(h);

    // Aerosols
    float aerosol_density = get_aerosol_density(h);
    aerosol_absorption = aerosol_absorption_cross_section * aerosol_density;
    aerosol_scattering = aerosol_scattering_cross_section * aerosol_density;

    // Add contribution from fog
    aerosol_scattering += get_fog_scattering_coefficient(h);

    extinction =
        aerosol_absorption + aerosol_scattering +
        molecular_absorption + molecular_scattering;
}

/*
 * Any given ray inside the atmospheric medium can end in one of 3 places:
 * 1. The Earth's surface.
 * 2. Outer space. We define the boundary between space and the atmosphere
 *    at the Kármán line (100 km above sea level).
 * 3. Any object within the atmosphere.
 */
float get_ray_end(vec3 ray_origin, vec3 ray_dir, float t_max)
{
    float ray_altitude = length(ray_origin);
    // Handle the camera being underground
    float earth_radius = min(ray_altitude, get_earth_radius());
    float atmos_dist  = ray_sphere_intersection(ray_origin, ray_dir, get_atmosphere_radius());
    float ground_dist = ray_sphere_intersection(ray_origin, ray_dir, earth_radius);
    float t_d;
    if (ray_altitude < get_atmosphere_radius()) {
        // We are inside the atmosphere
        if (ground_dist < 0.0) {
            // No ground collision, use the distance to the outer atmosphere
            t_d = atmos_dist;
        } else {
            // We have a collision with the ground, use the distance to it
            t_d = ground_dist;
        }
    } else {
        // We are in outer space
        // XXX: For now this is a flight simulator, not a space simulator
        t_d = -1.0;
    }
    return min(t_d, t_max);
}

/*
 * Compute the in-scattering integral of the volume rendering equation (VRE)
 *
 * The integral is solved numerically by ray marching. The final in-scattering
 * returned by this function is a 4D vector of the spectral radiance sampled for
 * the 4 wavelengths at the top of this file. To obtain an RGB triplet, the
 * spectral radiance must be multiplied by the spectral irradiance of the Sun
 * and converted to sRGB.
 */
vec4 compute_inscattering(in vec3 ray_origin,
                          in vec3 ray_dir,
                          in float t_max,
                          in vec3 sun_dir,
                          in int steps,
                          in sampler2D transmittance_lut,
                          out vec4 transmittance)
{
    float cos_theta = dot(-ray_dir, sun_dir);

    float molecular_phase = molecular_phase_function(cos_theta);
    float aerosol_phase = aerosol_phase_function(cos_theta);

    float dt = t_max / float(steps);

    vec4 L_inscattering = vec4(0.0);
    transmittance = vec4(1.0);

    for (int i = 0; i < steps; ++i) {
        float t = (float(i) + 0.5) * dt;
        vec3 x_t = ray_origin + ray_dir * t;

        float distance_to_earth_center = length(x_t);
        vec3 zenith_dir = x_t / distance_to_earth_center;
        float altitude = distance_to_earth_center - get_earth_radius();
        float normalized_altitude = altitude / (get_atmosphere_radius() - get_earth_radius());

        float sample_cos_theta = dot(zenith_dir, sun_dir);

        vec4 aerosol_absorption, aerosol_scattering;
        vec4 molecular_absorption, molecular_scattering;
        vec4 extinction;
        get_atmosphere_collision_coefficients(
            altitude,
            aerosol_absorption, aerosol_scattering,
            molecular_absorption, molecular_scattering,
            extinction);

        vec4 transmittance_to_sun = transmittance_from_lut(
            transmittance_lut, sample_cos_theta, normalized_altitude);

        vec4 ms = get_multiple_scattering(
            transmittance_lut, sample_cos_theta, normalized_altitude,
            distance_to_earth_center);

        vec4 S =
            molecular_scattering * (molecular_phase * transmittance_to_sun + ms) +
            aerosol_scattering   * (aerosol_phase   * transmittance_to_sun + ms);

        vec4 step_transmittance = exp(-dt * extinction);

        // Energy-conserving analytical integration
        // "Physically Based Sky, Atmosphere and Cloud Rendering in Frostbite"
        // by Sébastien Hillaire
        vec4 S_int = (S - S * step_transmittance) / max(extinction, 1e-7);
        L_inscattering += transmittance * S_int;
        transmittance *= step_transmittance;
    }

    return L_inscattering;
}
