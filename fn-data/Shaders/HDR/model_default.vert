#version 330 core

#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec4 vertex_color;
layout(location = 3) in vec4 multitexcoord0;

out VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec4 material_color;
} vs_out;

uniform int color_mode;
uniform vec4 material_diffuse;

uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vs_out.texcoord = multitexcoord0.st;
    vs_out.vertex_normal = osg_NormalMatrix * normal;

    // Legacy material handling
    if (color_mode == MODE_DIFFUSE)
        vs_out.material_color = vertex_color;
    else if (color_mode == MODE_AMBIENT_AND_DIFFUSE)
        vs_out.material_color = vertex_color;
    else
        vs_out.material_color = material_diffuse;
}
