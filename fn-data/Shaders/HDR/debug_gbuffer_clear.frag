#version 330 core

layout(location = 0) out vec4 out_gbuffer0;
layout(location = 1) out vec4 out_gbuffer1;
layout(location = 2) out vec4 out_gbuffer2;
layout(location = 3) out vec4 out_gbuffer3;

void main()
{
    out_gbuffer0 = vec4(0.0);
    out_gbuffer1 = vec4(0.0);
    out_gbuffer2 = vec4(0.0);
    out_gbuffer3 = vec4(0.0);
}
