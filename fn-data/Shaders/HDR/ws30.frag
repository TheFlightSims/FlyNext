#version 330 core

in VS_OUT {
    vec2 texcoord;
    vec2 orthophoto_texcoord;
    vec3 vertex_normal;
} fs_in;

uniform sampler2D landclass;
uniform sampler2DArray atlas;
uniform sampler2D perlin;

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
uniform mat4 fg_zUpTransform;
uniform vec3 fg_modelOffset;

const float TERRAIN_METALLIC  = 0.0;
const float TERRAIN_ROUGHNESS = 0.95;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);

void main()
{
	vec3 texel;
	vec4 specular = vec4(0.1, 0.1, 0.1, 1.0);

	if (fg_photoScenery) {
		texel = texture(landclass, vec2(fs_in.texcoord.s, 1.0 - fs_in.texcoord.t)).rgb;
	} else {

		// The Landclass for this particular fragment.  This can be used to
		// index into the atlas textures.
		int lc = int(texture2D(landclass, fs_in.texcoord).g * 255.0 + 0.5);
		uint tex1 = uint(fg_textureLookup1[lc].r * 255.0 + 0.5);

		//color = ambientArray[lc] + diffuseArray[lc] * NdotL * gl_LightSource[0].diffuse;
		specular = fg_specularArray[lc];
		
		// Different textures have different have different dimensions.
		vec2 atlas_dimensions = fg_dimensionsArray[lc].st;
		vec2 atlas_scale =  vec2(fg_tileWidth / atlas_dimensions.s, fg_tileHeight / atlas_dimensions.t );
		vec2 st = atlas_scale * fs_in.texcoord;

		// Rotate texture using the perlin texture as a mask to reduce tiling
		if (step(0.5, texture(perlin, atlas_scale * fs_in.texcoord / 8.0).r) == 1.0) {
			st = vec2(atlas_scale.s * fs_in.texcoord.t, atlas_scale.t * fs_in.texcoord);
		}

		if (step(0.5, texture(perlin, - atlas_scale * fs_in.texcoord / 16.0).r) == 1.0) {
			st = -st;
		}

		texel = texture(atlas, vec3(st, tex1)).rgb;
	}


    vec3 color = eotf_inverse_sRGB(texel);
	vec3 N = normalize(fs_in.vertex_normal);

    gbuffer_pack(N, color, TERRAIN_METALLIC, TERRAIN_ROUGHNESS, 1.0, vec3(0.0), 3u);
}
