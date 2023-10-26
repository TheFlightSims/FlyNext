// -*-C++-*-
#version 330 core

out vec4 interpolateColor;

in vec2 step;
in vec4 stepColor;

void main()
{
    gl_Position = vec4(step.xy, 0, 1);
    interpolateColor = stepColor;
}
