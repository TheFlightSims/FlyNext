#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 2) in vec4 vertex_color;
layout(location = 3) in vec4 multitexcoord0;
layout(location = 10) in vec4 usrAttr1;
layout(location = 11) in vec4 usrAttr2;

out vec2 texcoord;
out vec4 cloud_color;

uniform float range;
uniform float detail_range;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat4 osg_ViewMatrixInverse;
uniform vec3 fg_SunDirectionWorld;

// sun.glsl
vec3 get_sun_radiance(vec3 p);

void cloud_common_vert(out vec4 vs_pos, out vec4 ws_pos)
{
    float alpha_factor  = usrAttr1.r;
    float shade_factor  = usrAttr1.g;
    float cloud_height  = usrAttr1.b;
    float bottom_factor = usrAttr2.r;
    float middle_factor = usrAttr2.g;
    float top_factor    = usrAttr2.b;

    texcoord = multitexcoord0.st;

    // XXX: Should be sent as an uniform
    mat4 inverseModelViewMatrix = inverse(osg_ModelViewMatrix);

    vec4 ep = inverseModelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 l  = inverseModelViewMatrix * vec4(0.0, 0.0, 1.0, 1.0);
    vec3 u = normalize(ep.xyz - l.xyz);

    // Find a rotation matrix that rotates 1,0,0 into u. u, r and w are
    // the columns of that matrix.
    vec3 absu = abs(u);
    vec3 r = normalize(vec3(-u.y, u.x, 0.0));
    vec3 w = cross(u, r);

    // Do the matrix multiplication by [ u r w pos]. Assume no
    // scaling in the homogeneous component of pos.
    vec4 final_pos = vec4(0.0, 0.0, 0.0, 1.0);
    final_pos.xyz  = pos.x * u;
    final_pos.xyz += pos.y * r;
    final_pos.xyz += pos.z * w;
    // Apply Z scaling to allow sprites to be squashed in the z-axis
    final_pos.z = final_pos.z * vertex_color.w;

    // Now shift the sprite to the correct position in the cloud.
    final_pos.xyz += vertex_color.xyz;

    // Determine the position - used for fog and shading calculations
    float fogCoord = length(vec3(osg_ModelViewMatrix * vec4(vertex_color.xyz, 1.0)));
    float center_dist = length(vec3(osg_ModelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0)));

    if ((fogCoord > detail_range) && (fogCoord > center_dist) && (shade_factor < 0.7)) {
        // More than detail_range away, so discard all sprites on opposite side of
        // cloud center by shifting them beyond the view fustrum
        gl_Position = vec4(0.0, 0.0, 10.0, 1.0);
        cloud_color = vec4(0.0);
    } else {
        gl_Position = osg_ModelViewProjectionMatrix * final_pos;

        vs_pos = osg_ModelViewMatrix * final_pos;
        ws_pos = osg_ViewMatrixInverse * vs_pos;

        // Determine a lighting normal based on the vertex position from the
        // center of the cloud, so that sprite on the opposite side of the cloud
        // to the sun are darker.
        vec3 n = normalize(vec3(osg_ViewMatrixInverse *
                                osg_ModelViewMatrix * vec4(-final_pos.xyz, 0.0)));
        float NdotL = dot(-fg_SunDirectionWorld, n);

        // Determine the shading of the vertex. We shade it based on it's position
        // in the cloud relative to the sun, and it's vertical position in the cloud.
        float shade = mix(shade_factor, top_factor, smoothstep(-0.3, 0.3, NdotL));

        if (final_pos.z < 0.5 * cloud_height) {
            shade = min(shade, mix(bottom_factor, middle_factor,
                                   final_pos.z * 2.0 / cloud_height));
        } else {
            shade = min(shade, mix(middle_factor, top_factor,
                                   final_pos.z * 2.0 / cloud_height - 1.0));
        }

        cloud_color.rgb = shade * get_sun_radiance(ws_pos.xyz);

        if ((fogCoord > (0.9 * detail_range))
            && (fogCoord > center_dist)
            && (shade_factor < 0.7)) {
            // cloudlet is almost at the detail range, so fade it out.
            cloud_color.a = 1.0 - smoothstep(0.9 * detail_range, detail_range, fogCoord);
        } else {
            // As we get within 100m of the sprite, it is faded out.
            // Equally at large distances it also fades out.
            cloud_color.a = min(smoothstep(10.0, 100.0, fogCoord),
                               1.0 - smoothstep(0.9 * range, range, fogCoord));
        }

        cloud_color.a *= alpha_factor;
    }
}
