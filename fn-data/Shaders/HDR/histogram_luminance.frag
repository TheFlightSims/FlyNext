#version 330 core

layout(location = 0) out float fragLuminance;

uniform usampler2D histogram_tex;
uniform sampler2D prev_lum_tex;

uniform float osg_DeltaFrameTime;

// Higher values give faster eye adaptation times
const float TAU = 1.1;

// histogram.glsl
float bin_index_to_luminance(float bin);

void main()
{
    int num_bins = textureSize(histogram_tex, 0).x; // [0, 255]

    uint sum = 0u;
    uint total_pixels = 0u;

    // Calculate the mean of the luminance histogram.
    // We start indexing at 1 to ignore the first bin, which contains the
    // luminance values that are lower than our threshold.
    for (int i = 1; i < num_bins; ++i) {
        uint hits = texelFetch(histogram_tex, ivec2(i, 0), 0).r;
        sum += uint(i) * hits;
        total_pixels += hits;
    }

    float mean = float(sum) / max(float(total_pixels), 1.0) - 1.0;

    // Transform the bin index [1, 255] to an actual luminance value
    float average_lum = bin_index_to_luminance(mean);

    // Simulate smooth eye adaptation over time
    float prev_lum = texelFetch(prev_lum_tex, ivec2(0), 0).r;
    float adapted_lum = prev_lum + (average_lum - prev_lum) *
        (1.0 - exp(-osg_DeltaFrameTime * TAU));

    fragLuminance = adapted_lum;
}
