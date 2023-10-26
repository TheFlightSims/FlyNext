#version 330 core

#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec4 vertex_color;
layout(location = 3) in vec4 multitexcoord0;

out vec3 vN;
out vec3 vP;
out vec2 texcoord;
out vec4 material_color;
out vec4 ap_color;

uniform int color_mode;
uniform vec4 material_diffuse;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

// aerial_perspective.glsl
vec4 get_aerial_perspective(vec2 coord, float depth);

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vN = osg_NormalMatrix * normal;
    vP = (osg_ModelViewMatrix * pos).xyz;
    texcoord = multitexcoord0.st;

    // Legacy material handling
    if (color_mode == MODE_DIFFUSE)
        material_color = vertex_color;
    else if (color_mode == MODE_AMBIENT_AND_DIFFUSE)
        material_color = vertex_color;
    else
        material_color = material_diffuse;
    // Super hack: if diffuse material alpha is less than 1, assume a
    // transparency animation is at work
    if (material_diffuse.a < 1.0)
        material_color.a = material_diffuse.a;
    else
        material_color.a = vertex_color.a;

    vec2 coord = (gl_Position.xy / gl_Position.w) * 0.5 + 0.5;
    ap_color = get_aerial_perspective(coord, length(vP));
}
