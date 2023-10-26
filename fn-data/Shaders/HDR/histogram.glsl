#version 330 core

const float NUM_BINS = 254.0; // 256 - 2
const float INV_NUM_BINS = 1.0 / NUM_BINS;

const float MIN_LOG_LUM = -10.0;
const float LOG_LUM_RANGE = 16.0;
const float INV_LOG_LUM_RANGE = 1.0 / LOG_LUM_RANGE;

uint luminance_to_bin_index(float luminance)
{
    // Avoid taking the log of zero
    if (luminance < 0.005)
        return 0u;
    float log_lum = (log2(luminance) - MIN_LOG_LUM) * INV_LOG_LUM_RANGE;
    log_lum = clamp(log_lum, 0.0, 1.0);
    // From [0, 1] to [1, 255]. The 0th bin is handled by the near-zero check
    return uint(log_lum * NUM_BINS + 1.0);
}

float bin_index_to_luminance(float bin)
{
    return exp2(((bin * INV_NUM_BINS) * LOG_LUM_RANGE) + MIN_LOG_LUM);
}
