#version 330 core

uniform sampler2D dfg_tex;
uniform samplerCube prefiltered_envmap_tex;

const float MAX_PREFILTERED_LOD = 4.0;

// math.glsl
float pow5(float x);

vec3 get_reflected(vec3 N, vec3 V, mat4 view_matrix_inverse)
{
    return (view_matrix_inverse * vec4(reflect(-V, N), 0.0)).xyz;
}

/*
 * Fresnel term with included roughness to get a pleasant visual result.
 * See https://seblagarde.wordpress.com/2011/08/17/hello-world/
 */
vec3 F_Schlick_roughness(float NdotV, vec3 F0, float r)
{
    return F0 + (max(vec3(1.0 - r), F0) - F0) * pow5(max(1.0 - NdotV, 0.0));
}

/*
 * Evaluate the indirect diffuse irradiance.
 *
 * To get better results we should be precomputing the irradiance into a cubemap
 * or calculating spherical harmonics coefficients on the CPU.
 * Sampling the roughness=1 mipmap level of the prefiltered specular map works
 * fine too. :)
 */
vec3 ibl_eval_diffuse(vec3 N)
{
    int max_lod = int(MAX_PREFILTERED_LOD);
    ivec2 s = textureSize(prefiltered_envmap_tex, max_lod);
    float du = 1.0 / float(s.x);
    float dv = 1.0 / float(s.y);
    vec3 m0 = normalize(cross(N, vec3(0.0, 1.0, 0.0)));
    vec3 m1 = cross(m0, N);
    vec3 m0du = m0 * du;
    vec3 m1dv = m1 * dv;
    vec3 c;
    c  = textureLod(prefiltered_envmap_tex, N - m0du - m1dv, max_lod).rgb;
    c += textureLod(prefiltered_envmap_tex, N + m0du - m1dv, max_lod).rgb;
    c += textureLod(prefiltered_envmap_tex, N + m0du + m1dv, max_lod).rgb;
    c += textureLod(prefiltered_envmap_tex, N - m0du + m1dv, max_lod).rgb;
    return 0.25 * c;
}

/*
 * Evaluate the indirect specular.
 * Sample from the prefiltered environment map.
 */
vec3 ibl_eval_specular(float NdotV, vec3 refl, float roughness, vec3 f)
{
    float lod = roughness * float(MAX_PREFILTERED_LOD);
    vec3 prefiltered = textureLod(prefiltered_envmap_tex, refl, lod).rgb;
    vec2 env_brdf = texture(dfg_tex, vec2(NdotV, roughness)).rg;
    return prefiltered * (f * env_brdf.x + env_brdf.y);
}

/*
 * Evaluate the contribution of image-based lights, or indirect lighting.
 */
vec3 eval_ibl(vec3 base_color, float metallic, float roughness, vec3 f0,
              float occlusion, vec3 ws_N, vec3 ws_refl, float NdotV)
{
    roughness = max(roughness, 0.002025);
    vec3 F = F_Schlick_roughness(NdotV, f0, roughness);
    vec3 specular = ibl_eval_specular(NdotV, ws_refl, roughness, F);
    vec3 diffuse = ibl_eval_diffuse(ws_N) * base_color
        * (vec3(1.0) - F) * (1.0 - metallic);
    return (diffuse + specular) * occlusion;
}
