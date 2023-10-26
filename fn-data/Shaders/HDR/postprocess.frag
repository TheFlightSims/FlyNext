#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;

uniform sampler2D hdr_tex;
uniform sampler2D bloom_tex;

uniform vec2 fg_BufferSize;

uniform float bloom_strength;
uniform bool debug_ev100;

// aces.glsl
vec3 aces_fitted(vec3 color);
// color.glsl
vec3 eotf_sRGB(vec3 linear_srgb);

vec3 get_debug_color(float value)
{
    float level = value * 3.14159265 * 0.5;
    vec3 col;
    col.r = sin(level);
    col.g = sin(level * 2.0);
    col.b = cos(level);
    return col;
}

vec3 get_ev100_color(vec3 hdr)
{
    float level;
    if (texcoord.y < 0.05) {
        const float w = 0.001;
        if (texcoord.x >= (0.5 - w) && texcoord.x <= (0.5 + w))
            return vec3(1.0);
        return get_debug_color(texcoord.x);
    }
    float lum = max(dot(hdr, vec3(0.299, 0.587, 0.114)), 0.0001);
    float ev100 = log2(lum * 8.0);
    float norm = ev100 / 12.0 + 0.5;
    return get_debug_color(norm);
}

float rand2D(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
    vec3 hdr_color = texture(hdr_tex, texcoord).rgb;
    if (debug_ev100) {
        fragColor = vec4(get_ev100_color(hdr_color), 1.0);
        return;
    }

    // Apply bloom
    vec3 bloom = texture(bloom_tex, texcoord).rgb;
    hdr_color = mix(hdr_color, bloom, bloom_strength);

    // Tonemap
    vec3 color = aces_fitted(hdr_color);
    // Gamma correction
    color = eotf_sRGB(color);

    // Dithering
    color += mix(-0.5/255.0, 0.5/255.0, rand2D(texcoord));

    fragColor = vec4(color, 1.0);
}
