#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec4 multitexcoord0;
layout(location = 5) in vec4 multitexcoord2;

out VS_OUT {
    vec2 texcoord;
    vec2 orthophoto_texcoord;
    vec3 vertex_normal;
    vec3 world_vector;
} vs_out;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;
uniform mat4 osg_ViewMatrixInverse;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vs_out.texcoord = multitexcoord0.st;
    vs_out.orthophoto_texcoord = multitexcoord2.st;
    vs_out.vertex_normal = (osg_ViewMatrixInverse
        * vec4(osg_NormalMatrix * normal, 0.0)).xyz;
    vs_out.world_vector = (osg_ViewMatrixInverse * osg_ModelViewMatrix * pos).xyz;
}
