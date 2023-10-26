#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec4 multitexcoord0;

out VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
} vs_out;

uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

void main()
{
    vec4 raised_pos = pos;
    raised_pos.z += 0.05;

    gl_Position = osg_ModelViewProjectionMatrix * raised_pos;
    vs_out.texcoord = multitexcoord0.st;
    vs_out.vertex_normal = osg_NormalMatrix * normal;
}
