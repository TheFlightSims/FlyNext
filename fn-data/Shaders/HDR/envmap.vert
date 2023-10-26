#version 330 core

out vec3 cubemap_coord0;
out vec3 cubemap_coord1;
out vec3 cubemap_coord2;
out vec3 cubemap_coord3;
out vec3 cubemap_coord4;
out vec3 cubemap_coord5;

void main()
{
    vec2 pos = vec2(gl_VertexID % 2, gl_VertexID / 2) * 4.0 - 1.0;
    gl_Position = vec4(pos, 0.0, 1.0);

    // Map the quad texture coordinates to a direction vector to sample
    // the cubemap. This assumes that we are using the weird left-handed
    // orientations given by the OpenGL spec.
    // See https://www.khronos.org/opengl/wiki/Cubemap_Texture#Upload_and_orientation
    cubemap_coord0 = vec3(   1.0, -pos.y, -pos.x);
    cubemap_coord1 = vec3(-  1.0, -pos.y,  pos.x);
    cubemap_coord2 = vec3( pos.x,    1.0,  pos.y);
    cubemap_coord3 = vec3( pos.x, -  1.0, -pos.y);
    cubemap_coord4 = vec3( pos.x, -pos.y,    1.0);
    cubemap_coord5 = vec3(-pos.x, -pos.y, -  1.0);
}
