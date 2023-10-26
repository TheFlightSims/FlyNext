#version 330 core

uniform sampler2D lum_tex;
uniform float exposure_compensation;

const float one_over_log10 = 1.0 / log(10.0);

float log10(float x)
{
    return one_over_log10 * log(x);
}

/*
 * Exposure curve from 'Perceptual Effects in Real-time Tone Mapping'.
 * http://resources.mpi-inf.mpg.de/hdr/peffects/krawczyk05sccg.pdf
 */
float key_value(float L)
{
    return 1.0 - 2.0 / (log10(L + 1.0) + 2.0);
}

float get_exposure()
{
    float avg_lum = max(texelFetch(lum_tex, ivec2(0), 0).r, 0.001);
    float linear_exposure = key_value(avg_lum) / avg_lum;
    float exposure = log2(max(linear_exposure, 0.0001));
    exposure += exposure_compensation;
    return exposure;
}

vec3 apply_exposure(vec3 color)
{
    return color * exp2(get_exposure());
}

vec3 undo_exposure(vec3 color)
{
    return color / exp2(get_exposure());
}
