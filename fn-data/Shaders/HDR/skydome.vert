#version 330 core

layout(location = 0) in vec4 pos;

out vec3 ray_dir;
out vec3 ray_dir_view;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    // Get the camera height (0 being the ground)
    vec4 ground_point = osg_ModelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0);
    float altitude = length(ground_point);
    // Compensate for the skydome being fixed on the ground
    ray_dir = normalize(pos.xyz - vec3(0.0, 0.0, altitude));
    ray_dir_view = (osg_ModelViewMatrix * vec4(ray_dir, 0.0)).xyz;
}
