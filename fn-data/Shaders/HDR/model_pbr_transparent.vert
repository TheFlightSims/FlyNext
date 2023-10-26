#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec4 multitexcoord0;

out VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
    vec4 ap_color;
} vs_out;

uniform bool flip_vertically;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

// aerial_perspective.glsl
vec4 get_aerial_perspective(vec2 coord, float depth);

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vs_out.texcoord = multitexcoord0.st;
    if (flip_vertically)
        vs_out.texcoord.y = 1.0 - vs_out.texcoord.y;

    vs_out.vertex_normal = osg_NormalMatrix * normal;
    vs_out.view_vector = (osg_ModelViewMatrix * pos).xyz;

    vec2 coord = (gl_Position.xy / gl_Position.w) * 0.5 + 0.5;
    vs_out.ap_color = get_aerial_perspective(coord, length(vs_out.view_vector));
}
