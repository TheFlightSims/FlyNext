// WS30 FRAGMENT SHADER

// -*-C++-*-
#version 130
#extension GL_EXT_texture_array : enable

varying vec3 normal;
varying vec4 ecPosition;

uniform sampler2D landclass;
uniform sampler2DArray atlas;

// Passed from VPBTechnique, not the Effect
uniform float fg_tileWidth;
uniform float fg_tileHeight;
uniform bool fg_photoScenery;
uniform vec4 fg_dimensionsArray[128];
uniform vec4 fg_ambientArray[128];
uniform vec4 fg_diffuseArray[128];
uniform vec4 fg_specularArray[128];
uniform vec4 fg_textureLookup1[128];
uniform vec4 fg_textureLookup2[128];
#define MAX_TEXTURES 8
uniform mat4 fg_zUpTransform;
uniform vec3 fg_modelOffset;

// See include_fog.frag
uniform int fogType;
vec3 fog_Func(vec3 color, int type);

// See Shaders/shadows-include.frag
float getShadowing();

// See Shaders/clustered-include.frag
vec3 getClusteredLightsContribution(vec3 p, vec3 n, vec3 texel);

void main()
{
	float NdotL, NdotHV, fogFactor;
	vec3 lightDir = gl_LightSource[0].position.xyz;
	vec3 halfVector = gl_LightSource[0].halfVector.xyz;
	vec4 texel;
	vec4 fragColor;
	vec4 specular = vec4(0.0);

	// Material properties.
	vec4 mat_diffuse, mat_ambient, mat_specular;
	float mat_shininess;

	if (fg_photoScenery) {
		mat_ambient = vec4(1.0,1.0,1.0,1.0);
		mat_diffuse = vec4(1.0,1.0,1.0,1.0);
		mat_specular = vec4(0.1, 0.1, 0.1, 1.0);
		mat_shininess = 1.2;

		texel = texture(landclass, vec2(gl_TexCoord[0].s, 1.0 - gl_TexCoord[0].t));
	} else {
		// The Landclass for this particular fragment.  This can be used to
		// index into the atlas textures.
		int lc = int(texture2D(landclass, gl_TexCoord[0].st).g * 255.0 + 0.5);

		// Color Mode is always AMBIENT_AND_DIFFUSE, which means
		// using a base colour of white for ambient/diffuse,
		// rather than the material color from ambientArray/diffuseArray.
		mat_ambient = vec4(1.0,1.0,1.0,1.0);
		mat_diffuse = vec4(1.0,1.0,1.0,1.0);
		mat_specular = fg_specularArray[lc];
		mat_shininess = fg_dimensionsArray[lc].z;

		// Different textures have different have different dimensions.
		vec2 atlas_dimensions = fg_dimensionsArray[lc].st;
		vec2 atlas_scale =  vec2(fg_tileWidth / atlas_dimensions.s, fg_tileHeight / atlas_dimensions.t );

		texel = texture(atlas, vec3(atlas_scale * gl_TexCoord[0].st, int(texture2D(landclass, gl_TexCoord[0].st).g * 255.0 + 0.5)));
	}

	vec4 color = mat_ambient * (gl_LightModel.ambient + gl_LightSource[0].ambient);

	// If gl_Color.a == 0, this is a back-facing polygon and the
	// normal should be reversed.
	vec3 n = (2.0 * gl_Color.a - 1.0) * normal;
	n = normalize(n);
	NdotL = dot(n, lightDir);

	if (NdotL > 0.0) {
		float shadowmap = getShadowing();
		color += mat_diffuse * NdotL * shadowmap;
		NdotHV = max(dot(n, halfVector), 0.0);
		if (mat_shininess > 0.0)
			specular.rgb = (mat_specular.rgb
							* gl_LightSource[0].specular.rgb
							* pow(NdotHV, mat_shininess)
							* shadowmap);
	}
	color.a = mat_diffuse.a;

	// This shouldn't be necessary, but our lighting becomes very
	// saturated. Clamping the color before modulating by the texture
	// is closer to what the OpenGL fixed function pipeline does.
	color = clamp(color, 0.0, 1.0);

	fragColor = color * texel + specular;
	fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, texel.rgb);

	fragColor.rgb = fog_Func(fragColor.rgb, fogType);
	gl_FragColor = fragColor;
}
