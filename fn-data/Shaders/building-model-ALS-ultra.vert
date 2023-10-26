// -*- mode: C; -*-
// Licence: GPL v2
// © Emilian Huminiuc and Vivian Meazza 2011
#version 120

attribute vec3 instancePosition; // (x,y,z)
attribute vec3 instanceScale ; // (width, depth, height)
attribute vec3 attrib1;          // Generic packed attributes
attribute vec3 attrib2;

varying	vec3	rawpos;
varying	vec3	VNormal;
varying	vec3	VTangent;
varying	vec3	VBinormal;
varying	vec3	vViewVec;
varying vec3	vertVec;
varying	vec3	reflVec;

varying	float	alpha;

attribute	vec3	tangent;
attribute	vec3	binormal;

uniform	float		pitch;
uniform	float		roll;
uniform	float		hdg;
uniform	int  		refl_dynamic;
uniform int  		nmap_enabled;
uniform int  		shader_qual;
uniform int     color_is_position;

//////Fog Include///////////
// uniform	int 	fogType;
// void	fog_Func(int type);
////////////////////////////

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

const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;

vec3 float2vec(float value) {
	vec3 val;
	val.x = mod(value, c_precisionp1) / c_precision;
	val.y = mod(floor(value / c_precisionp1), c_precisionp1) / c_precision;
	val.z = floor(value / (c_precisionp1 * c_precisionp1)) / c_precision;
	return val;
}

void	main(void)
{
	// Unpack generic attributes
	vec3 attr1 = float2vec(attrib1.x);
	vec3 attr2 = float2vec(attrib1.z);
	vec3 attr3 = float2vec(attrib2.x);

	// Determine the rotation for the building.
	float sr = sin(6.28 * attr1.x);
	float cr = cos(6.28 * attr1.x);

	rawpos = gl_Vertex.xyz;
	// Adjust the very top of the roof to match the rooftop scaling.  This shapes
	// the rooftop - gambled, gabled etc.  These vertices are identified by gl_Color.z
	rawpos.x = (1.0 - gl_Color.z) * rawpos.x + gl_Color.z * ((rawpos.x + 0.5) * attr3.z - 0.5);
	rawpos.y = (1.0 - gl_Color.z) * rawpos.y + gl_Color.z * (rawpos.y * attrib2.y );

	// Adjust pitch of roof to the correct height. These vertices are identified by gl_Color.z
	// Scale down by the building height (instanceScale.z) because
	// immediately afterwards we will scale UP the vertex to the correct scale.
	rawpos.z = rawpos.z + gl_Color.z * attrib1.y / instanceScale.z;
	rawpos = rawpos * instanceScale.xyz;

	// Rotation of the building and movement into rawpos
	rawpos.xy = vec2(dot(rawpos.xy, vec2(cr, sr)), dot(rawpos.xy, vec2(-sr, cr)));
	rawpos = rawpos + instancePosition.xyz;
	vec4 ecPosition = gl_ModelViewMatrix * vec4(rawpos, 1.0);

	// Texture coordinates are stored as:
  // - a separate offset (x0, y0) for the wall (wtex0x, wtex0y), and roof (rtex0x, rtex0y)
  // - a semi-shared (x1, y1) so that the front and side of the building can have
  //   different texture mappings
  //
  // The vertex color value selects between them:
  // gl_Color.x=1 indicates front/back walls
  // gl_Color.y=1 indicates roof
  // gl_Color.z=1 indicates top roof vertexs (used above)
  // gl_Color.a=1 indicates sides
  // Finally, the roof texture is on the right of the texture sheet
	float wtex0x = attr1.y; // Front/Side texture X0
  float wtex0y = attr1.z; // Front/Side texture Y0
  float rtex0x = attr2.z; // Roof texture X0
  float rtex0y = attr3.x; // Roof texture Y0
  float wtex1x = attr2.x; // Front/Roof texture X1
  float stex1x = attr3.y; // Side texture X1
  float wtex1y = attr2.y; // Front/Roof/Side texture Y1
  vec2 tex0 = vec2(sign(gl_MultiTexCoord0.x) * (gl_Color.x*wtex0x + gl_Color.y*rtex0x + gl_Color.a*wtex0x),
                   gl_Color.x*wtex0y + gl_Color.y*rtex0y + gl_Color.a*wtex0y);

  vec2 tex1 = vec2(gl_Color.x*wtex1x + gl_Color.y*wtex1x + gl_Color.a*stex1x,
                   wtex1y);

  gl_TexCoord[0].x = tex0.x + gl_MultiTexCoord0.x * tex1.x;
  gl_TexCoord[0].y = tex0.y + gl_MultiTexCoord0.y * tex1.y;

	// Rotate the normal.
	vec3 normal = gl_Normal;
	// Rotate the normal as per the building.
	normal.xy = vec2(dot(normal.xy, vec2(cr, sr)), dot(normal.xy, vec2(-sr, cr)));

	VNormal = normalize(gl_NormalMatrix * normal);
  vec3 n = normalize(normal);
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
		alpha = 1.0;

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

	gl_FrontColor = gl_FrontMaterial.emission + vec4(1.0,1.0,1.0,1.0)
				  * (gl_LightModel.ambient + gl_LightSource[0].ambient);

	gl_Position  = gl_ModelViewProjectionMatrix * vec4(rawpos,1.0);

	setupShadows(ecPosition);
}
