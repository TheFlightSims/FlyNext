#version 330 core

uniform sampler2D normal_tex;
uniform int normalmap_dds = 0;

/*
 * Create a cotangent frame without a pre-computed tangent basis.
 * "Normal Mapping Without Precomputed Tangents" by Christian Schüler (2013).
 * http://www.thetenthplanet.de/archives/1180
 */
mat3 cotangent_frame(vec3 N, vec3 p, vec2 uv)
{
    // get edge vectors of the pixel triangle
    vec3 dp1 = dFdx(p);
    vec3 dp2 = dFdy(p);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);
    // solve the linear system
    vec3 dp2perp = cross(dp2, N);
    vec3 dp1perp = cross(N, dp1);
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
    // construct a scale-invariant frame
    float invmax = inversesqrt(max(dot(T,T), dot(B,B)));
    return mat3(T * invmax, B * invmax, N);
}

/*
 * Perturb the interpolated vertex normal N according to a normal map.
 * V is the view vector (eye to vertex, not normalized). Both N and V must be
 * in the same space.
 */
vec3 perturb_normal(vec3 N, vec3 V, vec2 texcoord)
{
    vec3 normal = texture(normal_tex, texcoord).rgb * 2.0 - 1.0;
    if (normalmap_dds > 0) {
        // DDS has flipped normals
        normal = -normal;
    }
    mat3 TBN = cotangent_frame(N, V, texcoord);
    return normalize(TBN * normal);
}
