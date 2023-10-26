/*
 * Normal vector encoding and decoding using octahedron normal encoding.
 * https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
 */

#version 330 core

vec2 msign(vec2 v)
{
    return vec2((v.x >= 0.0) ? 1.0 : -1.0,
                (v.y >= 0.0) ? 1.0 : -1.0);
}

vec2 encode_normal(vec3 n)
{
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    n.xy = (n.z >= 0) ? n.xy : (1.0 - abs(n.yx)) * msign(n.xy);
    n.xy = n.xy * 0.5 + 0.5;
    return n.xy;
}

vec3 decode_normal(vec2 f)
{
    f = f * 2.0 - 1.0;
    vec3 n = vec3(f, 1.0 - abs(f.x) - abs(f.y));
    float t = max(-n.z, 0.0);
    n.x += (n.x > 0.0) ? -t : t;
    n.y += (n.y > 0.0) ? -t : t;
    return normalize(n);
}
