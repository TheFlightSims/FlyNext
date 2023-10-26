#version 330 core

layout(location = 0) out uint fragHits;

uniform usampler2D partial_histogram_tex;

void main()
{
    ivec2 partial_histogram_size = textureSize(partial_histogram_tex, 0); // screen x 256
    uint bin = uint(gl_FragCoord.x); // [0, 255]

    uint hits = 0u;

    for (int column = 0; column < partial_histogram_size.x; ++column) {
        uint partial_hits = texelFetch(partial_histogram_tex, ivec2(column, bin), 0).r;
        hits += partial_hits;
    }

    fragHits = hits;
}
