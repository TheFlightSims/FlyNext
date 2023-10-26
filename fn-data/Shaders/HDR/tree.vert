#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec4 vertex_color;
layout(location = 3) in vec4 multitexcoord0;
layout(location = 12) in float fogcoord;

out VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    float autumn_flag;
} vs_out;

uniform int num_deciduous_trees;
uniform float season;
uniform float forest_effect_size;
uniform float forest_effect_shape;
uniform float WindN;
uniform float WindE;

uniform float osg_SimulationTime;
uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;

// noise.glsl
float voronoi_noise_2d(vec2 coord, float wavelength, float xrand, float yrand);

void main()
{
    float num_varieties = normal.z;
    float tex_fract = floor(fract(multitexcoord0.x) * num_varieties) / num_varieties;

    if (tex_fract < float(num_deciduous_trees) / float(num_varieties)) {
        vs_out.autumn_flag = 0.5 + fract(vertex_color.x);
    } else {
        vs_out.autumn_flag = 0.0;
    }

    tex_fract += floor(multitexcoord0.x) / num_varieties;

    // Determine the rotation for the tree. The Fog Coordinate provides rotation
    // information to rotate one of the quands by 90 degrees. We then apply an
    // additional position seed so that trees aren't all oriented N/S
    float sr = sin(fogcoord + vertex_color.x);
    float cr = cos(fogcoord + vertex_color.x);
    vs_out.texcoord = vec2(tex_fract, multitexcoord0.y);
    vs_out.texcoord.y = vs_out.texcoord.y + 0.5 * season;

    // scaling
    vec3 position = pos.xyz * normal.xxy;

    // Rotation of the generic quad to specific one for the tree.
    position.xy = vec2(dot(position.xy, vec2(cr, sr)), dot(position.xy, vec2(-sr, cr)));

    // Shear by wind. Note that this only applies to the top vertices
    float vertex_color_sum = vertex_color.x + vertex_color.y + vertex_color.z;
    float wind_offset = position.z * (
        sin(osg_SimulationTime * 1.8 + vertex_color_sum * 0.01) + 1.0) * 0.0025;
    position.x = position.x + wind_offset * WindN;
    position.y = position.y + wind_offset * WindE;

    // Scale by random domains
    float voronoi = 0.5 + 1.0 * voronoi_noise_2d(
        vertex_color.xy, forest_effect_size, forest_effect_shape, forest_effect_shape);
    position.xyz *= voronoi;

    position = position + vertex_color.xyz;
    gl_Position = osg_ModelViewProjectionMatrix * vec4(position, 1.0);

    vec3 view_vector = (osg_ModelViewMatrix * vec4(position, 1.0)).xyz;
    vs_out.vertex_normal = normalize(-view_vector);
}
