#version 330 core

const float DIELECTRIC_SPECULAR = 0.04;

// math.glsl
float M_PI();
float M_1_PI();
float sqr(float x);
float pow5(float x);

/*
 * Fresnel, Schlick's approximation.
 */
vec3 F_Schlick(float VdotH, vec3 f0)
{
    return f0 + (vec3(1.0) - f0) * pow5(clamp(1.0 - VdotH, 0.0, 1.0));
}

/*
 * Fresnel, Schlick's approximation, monochromatic.
 */
float F_Schlick(float VdotH, float f0)
{
    return f0 + (1.0 - f0) * pow5(clamp(1.0 - VdotH, 0.0, 1.0));
}

/*
 * Normal distribution function, Trowbridge-Reitz/GGX microfacet distribution.
 */
float D_GGX(float NdotH, float a2)
{
    float f = (NdotH * a2 - NdotH) * NdotH + 1.0;
    return M_PI() * f * f;
}

/*
 * Geometric attenuation, Smith-GGX formulation.
 */
float G1_Smith_GGX(float NdotX, float a2)
{
    return NdotX + sqrt(NdotX * (NdotX - NdotX * a2) + a2);
}

/*
 * Get the Fresnel reflectance at 0 degrees (light hitting the surface
 * perpendicularly) from PBR parameters.
 */
vec3 f0_from_pbr(vec3 base_color, float metallic)
{
    return mix(vec3(DIELECTRIC_SPECULAR), base_color, metallic);
}

/*
 * Evaluate the color of a standard PBR surface illuminated by an analytical
 * light source. The evaluated BSDF consists of a specular lobe and a diffuse
 * lobe. The specular lobe is the Cook-Torrance microfacet model, and the
 * diffuse lobe is a simple Lambertian.
 *
 * Note that the calculations here do not match the literature. Brian Karis
 * approach of refactoring by NdotX/NdotX has been used to optimize the code.
 */
vec3 surface_eval_analytical(
    // Material
    vec3 base_color, float metallic, float roughness, vec3 f0,
    // Light
    vec3 light_intensity, float occlusion,
    // Vectors
    vec3 N, vec3 L, vec3 V)
{
    float NdotL = dot(N, L);
    // Skip fragments that are completely occluded or that are not facing the light
    if (occlusion <= 0.0 || NdotL <= 0.0)
        return vec3(0.0);
    NdotL = max(NdotL, 1e-4);

    float a = max(sqr(roughness), 0.045);
    float a2 = sqr(a);

    vec3 H = normalize(L + V);
    float NdotV = max(dot(N, V), 1e-4);
    float NdotH = max(dot(N, H), 1e-4);
    float VdotH = max(dot(V, H), 1e-4);

    vec3 c_diff = mix(base_color * (1.0 - DIELECTRIC_SPECULAR), vec3(0.0), metallic);

    vec3  F = F_Schlick(VdotH, f0);
    float G = G1_Smith_GGX(NdotV, a2) * G1_Smith_GGX(NdotL, a2);
    float D = D_GGX(NdotH, a2);

    vec3 f_specular = (F * a2) / (D * G);
    vec3 f_diffuse = (vec3(1.0) - F) * c_diff * M_1_PI();
    vec3 bsdf = f_diffuse + f_specular;

    return bsdf * light_intensity * occlusion * NdotL;
}
