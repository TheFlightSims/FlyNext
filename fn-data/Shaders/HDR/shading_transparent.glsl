#version 330 core

uniform vec3 fg_SunDirection;

// shadowing.glsl
float get_shadowing(vec3 P, vec3 N, vec3 L);
vec3 debug_shadow_color(vec3 color, vec3 P, vec3 N, vec3 L);
// surface.glsl
vec3 f0_from_pbr(vec3 base_color, float metallic);
vec3 surface_eval_analytical(
    vec3 base_color, float metallic, float roughness, vec3 f0,
    vec3 light_intensity, float occlusion,
    vec3 N, vec3 L, vec3 V);
// ibl.glsl
vec3 get_reflected(vec3 N, vec3 V, mat4 view_matrix_inverse);
vec3 eval_ibl(vec3 base_color, float metallic, float roughness, vec3 f0,
              float occlusion, vec3 ws_N, vec3 ws_refl, float NdotV);
// aerial_perspective.glsl
vec3 mix_aerial_perspective(vec3 color, vec4 ap);
vec3 get_sun_radiance(vec3 p);
// clustered.glsl
vec3 eval_scene_lights(vec3 base_color, float metallic, float roughness, vec3 f0,
                       vec3 P, vec3 N, vec3 V);
// exposure.glsl
vec3 apply_exposure(vec3 color);

vec3 eval_lights_transparent(
    vec3 base_color, float metallic, float roughness, float occlusion,
    vec3 emissive, vec3 P, vec3 N, vec3 V, vec2 uv, vec4 ap,
    mat4 view_matrix_inverse)
{
    vec3 f0 = f0_from_pbr(base_color, metallic);
    vec3 ws_P = (view_matrix_inverse * vec4(P, 1.0)).xyz;

    // Evaluate sunlight
    vec3 sun_radiance = get_sun_radiance(ws_P);
    float shadow_factor = get_shadowing(P, N, fg_SunDirection);
    vec3 color = surface_eval_analytical(
        base_color, metallic, roughness, f0,
        sun_radiance, shadow_factor,
        N, fg_SunDirection, V);

    // Evaluate all scene lights
    color += eval_scene_lights(
        base_color, metallic, roughness, f0,
        P, N, V);

    // Evaluate image-based lights
    vec3 ws_N = (view_matrix_inverse * vec4(N, 0.0)).xyz;
    vec3 ws_refl = get_reflected(N, V, view_matrix_inverse);
    float NdotV = max(dot(N, V), 1e-4);
    color += eval_ibl(
        base_color, metallic, roughness, f0,
        occlusion, ws_N, ws_refl, NdotV);

    // Add emissive contribution
    color += emissive;

    // Add aerial perspective
    color = mix_aerial_perspective(color, ap);

    // Pre-expose
    color = apply_exposure(color);

    color = debug_shadow_color(color, P, N, fg_SunDirection);

    return color;
}
