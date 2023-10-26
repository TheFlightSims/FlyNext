/*
 * Bloom - downsampling step
 * "Next Generation Post Processing in Call of Duty Advanced Warfare"
 *      ACM Siggraph (2014)
 * Based on the implementation by Alexander Christensen
 * https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom
 */

#version 330 core

layout(location = 0) out vec3 fragColor;

in vec2 texcoord;

uniform sampler2D tex;
uniform bool is_first_downsample;

// color.glsl
float linear_srgb_to_luminance(vec3 color);
vec3 eotf_sRGB(vec3 linear_srgb);

float karis_average(vec3 color)
{
    return 1.0 / (1.0 + linear_srgb_to_luminance(color));
}

void main()
{
    vec2 texel_size = 1.0 / vec2(textureSize(tex, 0));
    float x = texel_size.x;
    float y = texel_size.y;

    // Take 13 samples around current texel
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(tex, vec2(texcoord.x - 2*x, texcoord.y + 2*y)).rgb;
    vec3 b = texture(tex, vec2(texcoord.x,       texcoord.y + 2*y)).rgb;
    vec3 c = texture(tex, vec2(texcoord.x + 2*x, texcoord.y + 2*y)).rgb;

    vec3 d = texture(tex, vec2(texcoord.x - 2*x, texcoord.y)).rgb;
    vec3 e = texture(tex, vec2(texcoord.x,       texcoord.y)).rgb;
    vec3 f = texture(tex, vec2(texcoord.x + 2*x, texcoord.y)).rgb;

    vec3 g = texture(tex, vec2(texcoord.x - 2*x, texcoord.y - 2*y)).rgb;
    vec3 h = texture(tex, vec2(texcoord.x,       texcoord.y - 2*y)).rgb;
    vec3 i = texture(tex, vec2(texcoord.x + 2*x, texcoord.y - 2*y)).rgb;

    vec3 j = texture(tex, vec2(texcoord.x - x, texcoord.y + y)).rgb;
    vec3 k = texture(tex, vec2(texcoord.x + x, texcoord.y + y)).rgb;
    vec3 l = texture(tex, vec2(texcoord.x - x, texcoord.y - y)).rgb;
    vec3 m = texture(tex, vec2(texcoord.x + x, texcoord.y - y)).rgb;

    vec3 downsample;
    if (is_first_downsample) {
        // Apply Karis average to each block of 4 samples to prevent fireflies.
        // Only done on the first downsampling step.
        vec3 group0 = (a+b+d+e) * 0.25;
        vec3 group1 = (b+c+e+f) * 0.25;
        vec3 group2 = (d+e+g+h) * 0.25;
        vec3 group3 = (e+f+h+i) * 0.25;
        vec3 group4 = (j+k+l+m) * 0.25;
        float kw0 = karis_average(group0);
        float kw1 = karis_average(group1);
        float kw2 = karis_average(group2);
        float kw3 = karis_average(group3);
        float kw4 = karis_average(group4);
        float kw_sum = kw0 + kw1 + kw2 + kw3 + kw4;
        downsample =
            kw0 * group0 +
            kw1 * group1 +
            kw2 * group2 +
            kw3 * group3 +
            kw4 * group4;
        downsample /= kw_sum;
    } else {
        // Apply weighted distribution:
        // 0.5 + 0.125 + 0.125 + 0.125 + 0.125 = 1
        downsample = e*0.125;
        downsample += (a+c+g+i)*0.03125;
        downsample += (b+d+f+h)*0.0625;
        downsample += (j+k+l+m)*0.125;
    }

    fragColor = downsample;
}
