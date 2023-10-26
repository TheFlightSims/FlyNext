#version 330 core

layout(location = 0) out float fragColor;

uniform sampler2D ao_tex;

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.xy) - ivec2(2);
    float ao = 0.0;

    ao += texelFetch(ao_tex, coord,               0).r;
    ao += texelFetch(ao_tex, coord + ivec2(1, 0), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(0, 1), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(1, 1), 0).r;

    ao += texelFetch(ao_tex, coord + ivec2(2, 0), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(3, 0), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(2, 1), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(3, 1), 0).r;

    ao += texelFetch(ao_tex, coord + ivec2(0, 2), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(1, 2), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(0, 3), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(1, 3), 0).r;

    ao += texelFetch(ao_tex, coord + ivec2(2, 2), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(3, 2), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(2, 3), 0).r;
    ao += texelFetch(ao_tex, coord + ivec2(3, 3), 0).r;

    ao /= 16.0;

    fragColor = ao;
}
