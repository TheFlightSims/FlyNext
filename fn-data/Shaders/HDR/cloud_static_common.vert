#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 2) in vec4 vertex_color;
layout(location = 3) in vec4 multitexcoord0;

out vec2 texcoord;
out vec4 cloud_color;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat4 osg_ViewMatrixInverse;
uniform vec3 fg_SunDirectionWorld;

const float shade = 0.8;
const float cloud_height = 1000.0;

// sun.glsl
vec3 get_sun_radiance(vec3 p);

void cloud_static_common_vert(out vec4 vs_pos, out vec4 ws_pos)
{
    texcoord = multitexcoord0.st;

    // XXX: Should be sent as an uniform
    mat4 inverseModelViewMatrix = inverse(osg_ModelViewMatrix);

    vec4 ep = inverseModelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 l  = inverseModelViewMatrix * vec4(0.0, 0.0, 1.0, 1.0);
    vec3 u = normalize(ep.xyz - l.xyz);

    vec4 final_pos = vec4(0.0, 0.0, 0.0, 1.0);
    final_pos.x = pos.x;
    final_pos.y = pos.y;
    final_pos.z = pos.z;
    final_pos.xyz += vertex_color.xyz;

    gl_Position = osg_ModelViewProjectionMatrix * final_pos;

    // Determine a lighting normal based on the vertex position from the
    // center of the cloud, so that sprite on the opposite side of the cloud
    // to the sun are darker.
    vec3 n = normalize(vec3(osg_ViewMatrixInverse *
                            osg_ModelViewMatrix * vec4(-final_pos.xyz, 0.0)));
    float NdotL = dot(-fg_SunDirectionWorld, n);

    vs_pos = osg_ModelViewMatrix * final_pos;
    ws_pos = osg_ViewMatrixInverse * vs_pos;

    float fogCoord = abs(vs_pos.z);
    float fract = smoothstep(0.0, cloud_height, final_pos.z + cloud_height);

    vec3 sun_radiance = get_sun_radiance(ws_pos.xyz);

    // Determine the shading of the sprite based on its vertical position and
    // position relative to the sun.
    NdotL = min(smoothstep(-0.5, 0.0, NdotL), fract);
    // Determine the shading based on a mixture from the backlight to the front
    vec3 backlight = shade * sun_radiance;

    cloud_color.rgb = mix(backlight, sun_radiance, NdotL);

    // As we get within 100m of the sprite, it is faded out. Equally at large
    // distances it also fades out.
    cloud_color.a = min(smoothstep(100.0, 250.0, fogCoord),
                       1.0 - smoothstep(70000.0, 75000.0, fogCoord));
}
