#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;

out vec3 vertex_normal;

uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vertex_normal = osg_NormalMatrix * normal;
}
