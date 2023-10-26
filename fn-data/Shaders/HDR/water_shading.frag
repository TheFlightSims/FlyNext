#version 330 core

layout(location = 0) out vec3 fragColor;

in vec2 texcoord;

uniform sampler2D gbuffer0_tex;
uniform sampler2D gbuffer1_tex;
uniform samplerCube prefiltered_envmap_tex;

uniform mat4 fg_ViewMatrixInverse;
uniform vec3 fg_SunDirection;

// math.glsl
float M_PI();
float M_1_PI();
float pow5(float x);
// normal_encoding.glsl
vec3 decode_normal(vec2 f);
// pos_from_depth.glsl
vec3 get_view_space_from_depth(vec2 uv);
// aerial_perspective.glsl
vec3 add_aerial_perspective(vec3 color, vec2 coord, float depth);
vec3 get_sun_radiance_sea_level();
// exposure.glsl
vec3 apply_exposure(vec3 color);

float F_Schlick(float VdotH, float f0)
{
    return f0 + (1.0 - f0) * pow5(clamp(1.0 - VdotH, 0.0, 1.0));
}

float D_GGX(float NdotH, float a2)
{
    float f = (NdotH * a2 - NdotH) * NdotH + 1.0;
    return a2 / (M_PI() * f * f);
}

void main()
{
    // Unpack G-Buffer
    vec4 gbuffer0 = texture(gbuffer0_tex, texcoord);
    vec4 gbuffer1 = texture(gbuffer1_tex, texcoord);
    vec3 N = decode_normal(gbuffer0.rg);
    vec3 sea_color = gbuffer1.rgb;

    vec3 P = get_view_space_from_depth(texcoord);
    vec3 V = normalize(-P);
    vec3 L = fg_SunDirection;

    vec3 refl = reflect(-V, N);
    vec3 ws_N = (fg_ViewMatrixInverse * vec4(N, 0.0)).xyz;
    vec3 ws_refl = (fg_ViewMatrixInverse * vec4(refl, 0.0)).xyz;

    vec3 H = normalize(L + V);
    float VdotH = max(dot(V, H), 1e-4);
    float NdotL = max(dot(N, L), 1e-4);
    float NdotV = max(dot(N, V), 1e-4);
    float NdotH = max(dot(N, H), 1e-4);

    const float f0 = 0.02; // For IOR = 1.33
    float fresnel = F_Schlick(NdotV, f0);

    // Refracted light, diffuse light coming from the sea floor
    vec3 sky_color = textureLod(prefiltered_envmap_tex, ws_N, 4.0).rgb;
    vec3 refracted = (1.0 - f0) * sea_color * sky_color * M_1_PI();
    // Reflected light, specular light coming from the sky
    vec3 reflected = textureLod(prefiltered_envmap_tex, ws_refl, 0.0).rgb * M_1_PI();

    vec3 color = mix(refracted, reflected, fresnel);

    // Add reflected Sun light
    vec3 sun_intensity = get_sun_radiance_sea_level();
    color += M_1_PI() * fresnel * D_GGX(NdotH, 0.001) * sun_intensity * NdotL;

    color = add_aerial_perspective(color, texcoord, length(P));

    // Pre-expose
    color = apply_exposure(color);

    fragColor = color;
}
