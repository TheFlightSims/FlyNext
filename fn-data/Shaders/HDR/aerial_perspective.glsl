#version 330 core

uniform sampler2D aerial_perspective_tex;

const float AP_SLICE_COUNT = 32.0;
const float AP_MAX_DEPTH = 128000.0;
const float AP_SLICE_WIDTH_PIXELS = 32.0;
const float AP_SLICE_SIZE = 1.0 / AP_SLICE_COUNT;
const float AP_TEXEL_WIDTH = 1.0 / (AP_SLICE_COUNT * AP_SLICE_WIDTH_PIXELS);

vec4 sample_aerial_perspective_slice(sampler2D lut, vec2 coord, float slice)
{
    // Sample at the pixel center
    float offset = slice * AP_SLICE_SIZE + AP_TEXEL_WIDTH * 0.5;
    float x = coord.x * (AP_SLICE_SIZE - AP_TEXEL_WIDTH) + offset;
    return texture(lut, vec2(x, coord.y));
}

vec4 sample_aerial_perspective(sampler2D lut, vec2 coord, float depth)
{
    vec4 color;
    float w = sqrt(clamp(depth / AP_MAX_DEPTH, 0.0, 1.0));
    float x = w * AP_SLICE_COUNT;
    if (x <= 1.0) {
        // Handle special case of fragments behind the first slice
        color = mix(vec4(0.0, 0.0, 0.0, 1.0),
                    sample_aerial_perspective_slice(lut, coord, 0),
                    x);
    } else {
        // Manually interpolate between slices
        x -= 1.0;
        color = mix(sample_aerial_perspective_slice(lut, coord, floor(x)),
                    sample_aerial_perspective_slice(lut, coord, ceil(x)),
                    fract(x));
    }
    return color;
}

vec4 get_aerial_perspective(vec2 coord, float depth)
{
    return sample_aerial_perspective(aerial_perspective_tex, coord, depth);
}

vec3 mix_aerial_perspective(vec3 color, vec4 ap)
{
    return color * ap.a + ap.rgb;
}

vec3 add_aerial_perspective(vec3 color, vec2 coord, float depth)
{
    return mix_aerial_perspective(color, get_aerial_perspective(coord, depth));
}
