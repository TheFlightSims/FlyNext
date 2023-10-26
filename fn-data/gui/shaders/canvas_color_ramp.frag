// -*-C++-*-
#version 330 core

out vec4 fragColor;

in vec4 interpolateColor;

void main()
{
    fragColor = interpolateColor;
}
