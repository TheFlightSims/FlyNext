// -*-C++-*-
#version 330 core

out vec2 texImageCoord;
out vec2 paintCoord;

in vec2 pos;
in vec2 textureUV;

uniform mat4 sh_Model;
uniform mat4 sh_Ortho;
uniform mat3 paintInverted;

void main()
{
    gl_Position = vec4(pos, 0, 1);
    texImageCoord = textureUV;
    paintCoord = (paintInverted * vec3(pos, 1)).xy;
}
