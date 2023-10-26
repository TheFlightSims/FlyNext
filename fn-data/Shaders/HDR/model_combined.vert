#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec4 multitexcoord0;

out VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
} vs_out;

uniform int normalmap_enabled;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vs_out.texcoord = multitexcoord0.st;
    vs_out.vertex_normal = osg_NormalMatrix * normal;
    vs_out.view_vector = (osg_ModelViewMatrix * pos).xyz;
}
