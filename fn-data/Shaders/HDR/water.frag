#version 330 core

layout(location = 0) out vec4 out_gbuffer0;
layout(location = 1) out vec4 out_gbuffer1;

in VS_OUT {
    vec2 water_texcoord;
    vec2 topo_texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
} fs_in;

uniform sampler2D perlin_normalmap;
uniform sampler2D water_dudvmap;
uniform sampler2D water_normalmap;
uniform sampler2D water_colormap;

uniform float osg_SimulationTime;

const vec2 sca = vec2(0.005);
const vec2 sca2 = vec2(0.02);
const vec2 tscale = vec2(0.25);
const float scale = 5.0;
const float mix_factor = 0.5;

// normal_encoding.glsl
vec2 encode_normal(vec3 n);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);
// normalmap.glsl
mat3 cotangent_frame(vec3 N, vec3 p, vec2 uv);

void get_rotation_matrix(float angle, out mat2 rotmat)
{
    rotmat = mat2(cos(angle), -sin(angle),
                  sin(angle),  cos(angle));
}

void main()
{
    vec2 disdis = texture(water_dudvmap, vec2(fs_in.water_texcoord * tscale) * scale).rg * 2.0 - 1.0;

    vec3 N0 = vec3(texture(water_normalmap, vec2(fs_in.water_texcoord + disdis * sca2) * scale) * 2.0 - 1.0);
    vec3 N1 = vec3(texture(perlin_normalmap, vec2(fs_in.water_texcoord + disdis * sca) * scale) * 2.0 - 1.0);

    N0 += vec3(texture(water_normalmap, vec2(fs_in.water_texcoord * tscale) * scale) * 2.0 - 1.0);
    N1 += vec3(texture(perlin_normalmap, vec2(fs_in.water_texcoord * tscale) * scale) * 2.0 - 1.0);

    mat2 rotmatrix;
    get_rotation_matrix(radians(2.0 * sin(osg_SimulationTime * 0.005)), rotmatrix);
    N0 += vec3(texture(water_normalmap, vec2(fs_in.water_texcoord * rotmatrix * (tscale + sca2)) * scale) * 2.0 - 1.0);
    N1 += vec3(texture(perlin_normalmap, vec2(fs_in.water_texcoord * rotmatrix * (tscale + sca2)) * scale) * 2.0 - 1.0);

    get_rotation_matrix(radians(-4.0 * sin(osg_SimulationTime * 0.003)), rotmatrix);
    N0 += vec3(texture(water_normalmap, vec2(fs_in.water_texcoord * rotmatrix + disdis * sca2) * scale) * 2.0 - 1.0);
    N1 += vec3(texture(perlin_normalmap, vec2(fs_in.water_texcoord * rotmatrix + disdis * sca) * scale) * 2.0 - 1.0);

    vec3 N = normalize(mix(N0, N1, mix_factor));
    mat3 TBN = cotangent_frame(fs_in.vertex_normal, fs_in.view_vector, fs_in.water_texcoord);
    N = normalize(TBN * N);

    vec3 floor_color = eotf_inverse_sRGB(texture(water_colormap, fs_in.topo_texcoord).rgb);

    out_gbuffer0.rg  = encode_normal(N);
    out_gbuffer1.rgb = floor_color;
}
