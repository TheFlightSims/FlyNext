// -*- mode: C; -*-
// Licence: GPL v2
// © Emilian Huminiuc and Vivian Meazza 2011
#version 120



// the file is directly copied from model-combined.eff except the (three) WINGFLEX to END WINGLFEX parts
// and the subsequent gl_Vertex integrations
// I didnt find how to do a more beautiful way (including model-combined and only adding the wingflexer part)
// if you know how to do this, please do :)

varying	vec3	rawpos;
varying	vec3	VNormal;
varying	vec3	VTangent;
varying	vec3	VBinormal;
varying	vec3	vViewVec;
varying	vec3	reflVec;
varying vec3 	vertVec;

varying	float	alpha;

attribute	vec3	tangent;
attribute	vec3	binormal;

uniform	float		pitch;
uniform	float		roll;
uniform	float		hdg;
uniform	int  		refl_dynamic;
uniform int  		nmap_enabled;
uniform int  		shader_qual;

// WINGFLEX
uniform int			wingflex_type;
uniform float		body_width;
uniform float 		wingflex_alpha;
uniform float 		wingflex_trailing_alpha;
uniform float 		wingsweep_factor;
uniform float 		wingflex_z;
uniform float		wing_span;
uniform float		rotation_x1;
uniform float		rotation_y1;
uniform float		rotation_z1;
uniform float		rotation_x2;
uniform float		rotation_y2;
uniform float		rotation_z2;
uniform float		rotation_rad;
// END WINGFLEX

//////Fog Include///////////
// uniform	int 	fogType;
// void	fog_Func(int type);
////////////////////////////

// WINGFLEX
vec2 calc_deflection(float y){
	float distance;
	float bwh = body_width/2;
	if(y < bwh && y > -bwh){
		//this part does not move
		distance = 0;
	}else if(y > bwh){
		distance = y - bwh;
	}else if(y < -bwh){
		distance = y + bwh;
	}
	float max_dist = (wing_span-body_width)/2;
	float deflection = wingflex_z * (distance*distance)/(max_dist*max_dist);
	float delta_y;
	if(y<0){
		delta_y = deflection/wing_span;
	}else{
		delta_y = -deflection/wing_span;
	}
	vec2 returned = vec2 ( deflection, delta_y );
	return returned;
}
// END WINGFLEX

void setupShadows(vec4 eyeSpacePos);

void	rotationMatrixPR(in float sinRx, in float cosRx, in float sinRy, in float cosRy, out mat4 rotmat)
{
	rotmat = mat4(	cosRy ,	sinRx * sinRy ,	cosRx * sinRy,	0.0,
									0.0   ,	cosRx        ,	-sinRx * cosRx,	0.0,
									-sinRy,	sinRx * cosRy,	cosRx * cosRy ,	0.0,
									0.0   ,	0.0          ,	0.0           ,	1.0 );
}

void	rotationMatrixH(in float sinRz, in float cosRz, out mat4 rotmat)
{
	rotmat = mat4(	cosRz,	-sinRz,	0.0,	0.0,
									sinRz,	cosRz,	0.0,	0.0,
									0.0  ,	0.0  ,	1.0,	0.0,
									0.0  ,	0.0  ,	0.0,	1.0 );
}

void	main(void)
{
		// WINGFLEX
		vec4 vertex = gl_Vertex;

		if ( wingflex_type == 0 ) {
			vec2 deflection = calc_deflection(vertex.y);

			vertex.z += deflection[0];
			vertex.y += deflection[1];

			if(rotation_rad != 0){
				vec2 defl1=calc_deflection(rotation_y1);
				vec2 defl2=calc_deflection(rotation_y2);
				float rot_y1 = rotation_y1;
				float rot_z1 = rotation_z1;
				float rot_y2 = rotation_y2;
				float rot_z2 = rotation_z2;
				rot_y1 -= defl1[1];
				rot_z1 += defl1[0];
				rot_y2 -= defl2[1];
				rot_z2 += defl2[0];
				//Calculate rotation
				vec3 normal;
				normal[0]=rotation_x2-rotation_x1;
				normal[1]=rot_y2-rot_y1;
				normal[2]=rot_z2-rot_z1;
				normal = normalize(normal);
				float tmp = (1-cos(rotation_rad));
				mat4 rotation_matrix = mat4(
					pow(normal[0],2)*tmp+cos(rotation_rad),			normal[1]*normal[0]*tmp-normal[2]*sin(rotation_rad),	normal[2]*normal[0]*tmp+normal[1]*sin(rotation_rad),	0.0,
					normal[0]*normal[1]*tmp+normal[2]*sin(rotation_rad),	pow(normal[1],2)*tmp+cos(rotation_rad),			normal[2]*normal[1]*tmp-normal[0]*sin(rotation_rad),	0.0,
					normal[0]*normal[2]*tmp-normal[1]*sin(rotation_rad),	normal[1]*normal[2]*tmp+normal[0]*sin(rotation_rad),	pow(normal[2],2)*tmp+cos(rotation_rad),			0.0,
					0.0,							0.0,							0.0,							1.0
					);
				vec4 old_point;
				old_point[0]=vertex.x;
				old_point[1]=vertex.y;
				old_point[2]=vertex.z;
				old_point[3]=1.0;
				rotation_matrix[3][0] = rotation_x1 	- rotation_x1*rotation_matrix[0][0] - rot_y1*rotation_matrix[1][0] - rot_z1*rotation_matrix[2][0];
				rotation_matrix[3][1] = rot_y1 	- rotation_x1*rotation_matrix[0][1] - rot_y1*rotation_matrix[1][1] - rot_z1*rotation_matrix[2][1];
				rotation_matrix[3][2] = rot_z1 	- rotation_x1*rotation_matrix[0][2] - rot_y1*rotation_matrix[1][2] - rot_z1*rotation_matrix[2][2];
				vec4 new_point=rotation_matrix*old_point;
				vertex.x=new_point[0];
				vertex.y=new_point[1];
				vertex.z=new_point[2];
			}

		} else if (wingflex_type == 1 ) {
			float arm_reach = 4.8;

			float x_factor = max((abs(vertex.x) - body_width),0);
			float y_factor = max(vertex.y,0.0);
			float flex_factor1 = wingflex_alpha * (1.0 - wingsweep_factor);
			float flex_factor2 = wingflex_trailing_alpha * (1.0 -wingsweep_factor);


			if (flex_factor1<0.0) {flex_factor1 *=0.7;}
			if (flex_factor2<0.0) {flex_factor1 *=0.7;}

			// basic flapping motion is linear to arm_reach, then parabolic

			float intercept_point = 0.1 * arm_reach * arm_reach * flex_factor1;

			if (x_factor < arm_reach)
				{
				vertex.z += x_factor/arm_reach * intercept_point;
				}

			else
				{
				vertex.z += 0.1 * x_factor * x_factor * flex_factor1;
				}

			// upward stroke is slightly forward-swept, downward stroke a bit backward
			vertex.y += -0.25 * abs(x_factor) * flex_factor1;

			//trailing edge lags the motion
			vertex.z += 0.2 * y_factor * x_factor * flex_factor2;


			// if the wings are folded, we sweep them back
			vertex.y += 0.5 * x_factor * wingsweep_factor;
			float sweep_x = 0.5;
			if (vertex.x > 0.0) {sweep_x = - 0.5;}

			vertex.x+= sweep_x * (1.0 + 0.5 *x_factor) *   wingsweep_factor;


		}
		// END WINGFLEX

		rawpos = vertex.xyz;
		vec4 ecPosition = gl_ModelViewMatrix * vertex;
		//rawpos = gl_Vertex.xyz;
		//vec4 ecPosition = gl_ModelViewMatrix * gl_Vertex;
		//fog_Func(fogType);

		VNormal = normalize(gl_NormalMatrix * gl_Normal);

		vec3 n = normalize(gl_Normal);
		vec3 tempTangent = cross(n, vec3(1.0,0.0,0.0));
		vec3 tempBinormal = cross(n, tempTangent);

		if (nmap_enabled > 0){
			tempTangent = tangent;
			tempBinormal  = binormal;
		}

		VTangent = normalize(gl_NormalMatrix * tempTangent);
		VBinormal = normalize(gl_NormalMatrix * tempBinormal);
		vec3 t = tempTangent;
		vec3 b = tempBinormal;

    // Super hack: if diffuse material alpha is less than 1, assume a
	// transparency animation is at work
		if (gl_FrontMaterial.diffuse.a < 1.0)
			alpha = gl_FrontMaterial.diffuse.a;
		else
			alpha = gl_Color.a;

    // Vertex in eye coordinates
		vertVec = ecPosition.xyz;
		vViewVec.x = dot(t, vertVec);
		vViewVec.y = dot(b, vertVec);
		vViewVec.z = dot(n, vertVec);

    // calculate the reflection vector
		vec4 reflect_eye = vec4(reflect(vertVec, VNormal), 0.0);
		vec3 reflVec_stat = normalize(gl_ModelViewMatrixInverse * reflect_eye).xyz;
		if (refl_dynamic > 0){
			//prepare rotation matrix
			mat4 RotMatPR;
			mat4 RotMatH;
			float _roll = roll;
			if (_roll>90.0 || _roll < -90.0)
			{
				_roll = -_roll;
			}
			float cosRx = cos(radians(_roll));
			float sinRx = sin(radians(_roll));
			float cosRy = cos(radians(-pitch));
			float sinRy = sin(radians(-pitch));
			float cosRz = cos(radians(hdg));
			float sinRz = sin(radians(hdg));
			rotationMatrixPR(sinRx, cosRx, sinRy, cosRy, RotMatPR);
			rotationMatrixH(sinRz, cosRz, RotMatH);
			vec3 reflVec_dyn = (RotMatH * (RotMatPR * normalize(gl_ModelViewMatrixInverse * reflect_eye))).xyz;

			reflVec = reflVec_dyn;
		} else {
			reflVec = reflVec_stat;
		}


		gl_FrontColor = gl_FrontMaterial.emission + gl_Color
					  * (gl_LightModel.ambient + gl_LightSource[0].ambient);

		gl_Position = gl_ModelViewProjectionMatrix * vertex;
		//gl_Position = ftransform();
		gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;


        setupShadows(ecPosition);
}
