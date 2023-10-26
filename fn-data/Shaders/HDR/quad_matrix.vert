#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 3) in vec4 multitexcoord0;

out vec2 texcoord;

uniform mat4 osg_ModelViewProjectionMatrix;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    texcoord = multitexcoord0.st;
}
