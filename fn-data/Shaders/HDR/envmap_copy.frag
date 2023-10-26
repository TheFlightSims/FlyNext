#version 330 core

layout(location = 0) out vec3 fragColor0;
layout(location = 1) out vec3 fragColor1;
layout(location = 2) out vec3 fragColor2;
layout(location = 3) out vec3 fragColor3;
layout(location = 4) out vec3 fragColor4;
layout(location = 5) out vec3 fragColor5;

in vec3 cubemap_coord0;
in vec3 cubemap_coord1;
in vec3 cubemap_coord2;
in vec3 cubemap_coord3;
in vec3 cubemap_coord4;
in vec3 cubemap_coord5;

uniform samplerCube envmap_tex;

void main()
{
    fragColor0 = textureLod(envmap_tex, cubemap_coord0, 0.0).rgb;
    fragColor1 = textureLod(envmap_tex, cubemap_coord1, 0.0).rgb;
    fragColor2 = textureLod(envmap_tex, cubemap_coord2, 0.0).rgb;
    fragColor3 = textureLod(envmap_tex, cubemap_coord3, 0.0).rgb;
    fragColor4 = textureLod(envmap_tex, cubemap_coord4, 0.0).rgb;
    fragColor5 = textureLod(envmap_tex, cubemap_coord5, 0.0).rgb;
}
