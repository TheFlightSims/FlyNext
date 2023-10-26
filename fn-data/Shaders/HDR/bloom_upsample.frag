/*
 * Bloom - upsampling step
 * "Next Generation Post Processing in Call of Duty Advanced Warfare"
 *      ACM Siggraph (2014)
 * Based on the implementation by Alexander Christensen
 * https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom
 */

#version 330 core

layout(location = 0) out vec3 fragColor;

in vec2 texcoord;

uniform sampler2D tex;
uniform float filter_radius;

void main()
{
    // The filter kernel is applied with a radius, specified in texture
    // coordinates, so that the radius will vary across mip resolutions.
    float x = filter_radius;
    float y = filter_radius;

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(tex, vec2(texcoord.x - x, texcoord.y + y)).rgb;
    vec3 b = texture(tex, vec2(texcoord.x,     texcoord.y + y)).rgb;
    vec3 c = texture(tex, vec2(texcoord.x + x, texcoord.y + y)).rgb;

    vec3 d = texture(tex, vec2(texcoord.x - x, texcoord.y)).rgb;
    vec3 e = texture(tex, vec2(texcoord.x,     texcoord.y)).rgb;
    vec3 f = texture(tex, vec2(texcoord.x + x, texcoord.y)).rgb;

    vec3 g = texture(tex, vec2(texcoord.x - x, texcoord.y - y)).rgb;
    vec3 h = texture(tex, vec2(texcoord.x,     texcoord.y - y)).rgb;
    vec3 i = texture(tex, vec2(texcoord.x + x, texcoord.y - y)).rgb;

    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |
    vec3 upsample = e * 4.0;
    upsample += (b+d+f+h) * 2.0;
    upsample += (a+c+g+i);
    upsample /= 16.0;

    fragColor = upsample;
}
