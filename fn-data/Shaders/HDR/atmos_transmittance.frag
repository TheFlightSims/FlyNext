#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;

const int TRANSMITTANCE_STEPS = 40;

// atmos.glsl
float get_earth_radius();
float get_atmosphere_radius();
float ray_sphere_intersection(vec3 ro, vec3 rd, float radius);
void get_atmosphere_collision_coefficients(in float h,
                                           out vec4 aerosol_absorption,
                                           out vec4 aerosol_scattering,
                                           out vec4 molecular_absorption,
                                           out vec4 molecular_scattering,
                                           out vec4 extinction);

void main()
{
    float sun_cos_theta = texcoord.x * 2.0 - 1.0;
    vec3 sun_dir = vec3(-sqrt(1.0 - sun_cos_theta*sun_cos_theta), 0.0, sun_cos_theta);

    float distance_to_earth_center = mix(get_earth_radius(),
                                         get_atmosphere_radius(),
                                         texcoord.y);
    vec3 ray_origin = vec3(0.0, 0.0, distance_to_earth_center);

    float t_d = ray_sphere_intersection(ray_origin, sun_dir, get_atmosphere_radius());
    float dt = t_d / float(TRANSMITTANCE_STEPS);

    vec4 result = vec4(0.0);

    for (int i = 0; i < TRANSMITTANCE_STEPS; ++i) {
        float t = (float(i) + 0.5) * dt;
        vec3 x_t = ray_origin + sun_dir * t;

        float altitude = length(x_t) - get_earth_radius();

        vec4 aerosol_absorption, aerosol_scattering;
        vec4 molecular_absorption, molecular_scattering;
        vec4 extinction;
        get_atmosphere_collision_coefficients(
            altitude,
            aerosol_absorption, aerosol_scattering,
            molecular_absorption, molecular_scattering,
            extinction);

        result += extinction * dt;
    }

    vec4 transmittance = exp(-result);
    fragColor = transmittance;
}
