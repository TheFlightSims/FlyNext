#version 330 core

uniform sampler2D ao_tex;

uniform bool ambient_occlusion_enabled;

float GTAO_multibounce(float x, vec3 albedo)
{
    // Use luminance instead of albedo because colored multibounce looks bad
    // Idea borrowed from Blender Eevee
    float lum = dot(albedo, vec3(0.333));
    float a =  2.0404 * lum - 0.3324;
    float b = -4.7951 * lum + 0.6417;
    float c =  2.7552 * lum + 0.6903;
    return max(x, ((x * a + b) * x + c) * x);
}

float get_ambient_occlusion(vec2 uv, vec3 albedo)
{
    if (ambient_occlusion_enabled)
        return GTAO_multibounce(texture(ao_tex, uv).r, albedo);
    return 1.0;
}
