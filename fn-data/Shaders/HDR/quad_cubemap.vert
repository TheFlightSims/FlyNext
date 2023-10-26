#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 3) in vec4 multitexcoord0;

out vec3 cubemap_coord;

uniform mat4 osg_ModelViewProjectionMatrix;
uniform int fg_CubemapFace;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vec2 texcoord = multitexcoord0.xy * 2.0 - 1.0;

    // Map the quad texture coordinates to a direction vector to sample
    // the cubemap. This assumes that we are using the weird left-handed
    // orientations given by the OpenGL spec.
    // See https://www.khronos.org/opengl/wiki/Cubemap_Texture#Upload_and_orientation
    switch(fg_CubemapFace) {
    case 0: // +X
        cubemap_coord = vec3(1.0, -texcoord.y, -texcoord.x);
        break;
    case 1: // -X
        cubemap_coord = vec3(-1.0, -texcoord.y, texcoord.x);
        break;
    case 2: // +Y
        cubemap_coord = vec3(texcoord.x, 1.0, texcoord.y);
        break;
    case 3: // -Y
        cubemap_coord = vec3(texcoord.x, -1.0, -texcoord.y);
        break;
    case 4: // +Z
        cubemap_coord = vec3(texcoord.x, -texcoord.y, 1.0);
        break;
    case 5: // -Z
        cubemap_coord = vec3(-texcoord.x, -texcoord.y, -1.0);
        break;
    }
}
