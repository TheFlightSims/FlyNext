// -*-C++-*-
#version 120

uniform float eyerel_x1;
uniform float eyerel_y1;
uniform float eyerel_z1;
uniform float lightspot_r1;
uniform float lightspot_g1;
uniform float lightspot_b1;
uniform float eyerel_x2;
uniform float eyerel_y2;
uniform float eyerel_z2;
uniform float lightspot_r2;
uniform float lightspot_g2;
uniform float lightspot_b2;
uniform float eyerel_x3;
uniform float eyerel_y3;
uniform float eyerel_z3;
uniform float lightspot_r3;
uniform float lightspot_g3;
uniform float lightspot_b3;
uniform float eyerel_x4;
uniform float eyerel_y4;
uniform float eyerel_z4;
uniform float lightspot_r4;
uniform float lightspot_g4;
uniform float lightspot_b4;
uniform float eyerel_x5;
uniform float eyerel_y5;
uniform float eyerel_z5;
uniform float lightspot_r5;
uniform float lightspot_g5;
uniform float lightspot_b5;
uniform float lightspot_project1;
uniform float lightspot_project2;
uniform float lightspot_dir1;
uniform float lightspot_dir2;
uniform float lightspot_size1;
uniform float lightspot_size2;
uniform float lightspot_size3;
uniform float lightspot_size4;
uniform float lightspot_size5;

uniform int num_lightspots;

vec3 lightspot(vec3 relPos)
{


if (num_lightspots == 0)
	{
	return vec3 (0.0, 0.0, 0.0);
	}

// first projectable spot

vec3 eye_rel = vec3 (eyerel_x1, eyerel_y1, eyerel_z1);
vec3 difference_vec = relPos - eye_rel;

mat2 rotMat = mat2 (cos(lightspot_dir1), sin(lightspot_dir1), -sin(lightspot_dir1), cos(lightspot_dir1));

difference_vec.xy = rotMat * difference_vec.xy;
difference_vec.x/= (1.0 +  lightspot_project1);  

float lightspot_arg = (1.0 - smoothstep(lightspot_size1/3.0, lightspot_size1, length(difference_vec))) * (1.0 - 0.5* smoothstep(lightspot_size1/3.0, lightspot_size1/(1.0+lightspot_project1), -difference_vec.x));

vec3 lightspot_color = vec3 (lightspot_r1,lightspot_g1, lightspot_b1 ) * lightspot_arg;

// second projectable spot

eye_rel = vec3 (eyerel_x2, eyerel_y2, eyerel_z2);
difference_vec = relPos - eye_rel;

rotMat = mat2 (cos(lightspot_dir2), sin(lightspot_dir2), -sin(lightspot_dir2), cos(lightspot_dir2));

difference_vec.xy = rotMat * difference_vec.xy;
difference_vec.x/= (1.0 +  lightspot_project2); 

lightspot_arg = (1.0 - smoothstep(lightspot_size2/3.0, lightspot_size2, length(difference_vec))) * (1.0 - 0.5* smoothstep(lightspot_size2/3.0, lightspot_size2/(1.0+lightspot_project2), -difference_vec.x));

lightspot_color += vec3 (lightspot_r2,lightspot_g2, lightspot_b2 ) * lightspot_arg;

if (num_lightspots < 3)
	{
	return lightspot_color ;
	}

// spherical spot

eye_rel = vec3 (eyerel_x3, eyerel_y3, eyerel_z3);
lightspot_arg = (1.0 - smoothstep(lightspot_size3/3.0, lightspot_size3, length(relPos - eye_rel)));
lightspot_color += vec3 (lightspot_r3,lightspot_g3, lightspot_b3 ) * lightspot_arg;

// spherical spot

eye_rel = vec3 (eyerel_x4, eyerel_y4, eyerel_z4);
lightspot_arg = (1.0 - smoothstep(lightspot_size4/3.0, lightspot_size4, length(relPos - eye_rel)));
lightspot_color += vec3 (lightspot_r4,lightspot_g4, lightspot_b4 ) * lightspot_arg;

// spherical spot

eye_rel = vec3 (eyerel_x5, eyerel_y5, eyerel_z5);
lightspot_arg = (1.0 - smoothstep(lightspot_size5/3.0, lightspot_size5, length(relPos - eye_rel)));
lightspot_color += vec3 (lightspot_r5,lightspot_g5, lightspot_b5 ) * lightspot_arg;

return lightspot_color;

}
