#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec4 multitexcoord0;
layout(location = 5) in vec4 multitexcoord2;

out VS_OUT {
    vec2 texcoord;
    vec2 orthophoto_texcoord;
    vec3 vertex_normal;
} vs_out;

uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vs_out.texcoord = multitexcoord0.st;
    vs_out.orthophoto_texcoord = multitexcoord2.st;
    vs_out.vertex_normal = osg_NormalMatrix * normal;
}
