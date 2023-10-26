// -*-C++-*-
#version 120

#define MAX_LAYERS 8
#define MAX_DISTANCE 3000.0

uniform float visibility;
uniform float avisibility;
uniform float scattering;
uniform float overlay_bias;
uniform float season;
uniform float dust_cover_factor;
uniform float overlay_max_height;
uniform float overlay_hardness;
uniform float overlay_density;
uniform float overlay_scale;
uniform float overlay_steepness_factor;
uniform float overlay_brightness_bottom;
uniform float overlay_brightness_top;
uniform float overlay_secondary_hardness;
uniform float overlay_secondary_density;
uniform float snowlevel;
uniform float wetness;
uniform float snow_thickness_factor;

uniform int overlay_autumn_flag;
uniform int overlay_secondary_flag;
uniform int cloud_shadow_flag;

uniform sampler2D overlayPrimaryTex;
uniform sampler2D overlaySecondaryTex;


uniform float osg_SimulationTime;

varying vec2 g_rawpos;                  // Horizontal position in model space
varying float g_distance_to_eye;        // Distance to the camera. Layers were disregarded
varying vec3 g_normal;
varying float g_altitude;
varying float g_layer;				       // The layer where the fragment lives (0-1 range)


float rand2D(in vec2 co);
float Noise2D(in vec2 co, in float wavelength);
vec3 filter_combined (in vec3 color) ;

float shadow_func_nearest (in float x, in float y, in float noise, in float dist);

float getShadowing();


void main()
{

	if (g_distance_to_eye > MAX_DISTANCE) {discard;}

	vec2 texCoord = gl_TexCoord[0].st;
			
	vec2 pos_rotated = vec2 (0.707 * g_rawpos.x + 0.707 * g_rawpos.y, 0.707 * g_rawpos.x - 0.707 * g_rawpos.y);

	
	//float noise_1m = 0.5 * Noise2D(pos_rotated.xy, 1.0 * overlay_scale); 
    //noise_1m += 0.5 * Noise2D(g_rawpos.xy, 1.1 * overlay_scale); 
	
	float noise_1m = Noise2D(pos_rotated.xy, 1.0 * overlay_scale); 

	float noise_2m = Noise2D(g_rawpos.xy, 2.0 * overlay_scale); ;
	float noise_10m = Noise2D(g_rawpos.xy, 10.0 * overlay_scale);
	
	
	
	float value = 0.0;
	
	float d_fade =smoothstep(100.0, MAX_DISTANCE, g_distance_to_eye);
	
	float steepness = dot (normalize(g_normal), vec3 (0.0, 0.0, 1.0));
	float steepness_bias = smoothstep(overlay_steepness_factor, overlay_steepness_factor + 0.1, steepness);
	
	float overlayPattern = 0.2 * noise_10m + 0.3 * noise_2m + 0.5 * noise_1m - 0.2 * g_layer - 0.1 + 0.2 * overlay_density ;
	overlayPattern *= steepness_bias;
	
	float secondaryPattern = 0.2 * (1.0-noise_10m) + 0.3 * (1.0-noise_2m) + 0.5 * (1.0-noise_1m) - 0.4 * g_layer - 0.2 + 0.2 * overlay_secondary_density ;	
	secondaryPattern *= overlay_secondary_flag;
	float secondaryMix = 0.0;
	
	if (overlayPattern > 0.5) 
		{
		value = smoothstep(0.5, (0.8 - 0.25 * overlay_hardness), overlayPattern);
		}
	else if (secondaryPattern > 0.5)
		{
		value = smoothstep(0.5, (0.8 - 0.25 * overlay_secondary_hardness), secondaryPattern); 
		secondaryMix = 1.0;	
		}
	else {discard;}
	
	vec3 texel = texture2D(overlayPrimaryTex, texCoord * 20.0).rgb;
	vec3 secondary_texel = texture2D(overlaySecondaryTex, texCoord * 20.0).rgb;
	
	// autumn coloring
	
	if (overlay_autumn_flag == 1)
		{
		texel.r = min(1.0, (1.0 + 2.5  * 0.1 * season) * texel.r);
		texel.g = texel.g;
		texel.b = max(0.0, (1.0 - 4.0  * 0.1 * season) *  texel.b);
		float intensity = length(texel.rgb) * (1.0 - 0.5 * smoothstep(1.1,2.0,season));
		texel.rgb = intensity * normalize(mix(texel.rgb, vec3(0.23,0.17,0.08), smoothstep(1.1,2.0, season)));
		}
	
	texel = mix (texel, secondary_texel,  secondaryMix);
	
	
	float layer_arg = mix(g_layer, 1.0, smoothstep(250.0, 5000.0, g_distance_to_eye));
	texel.rgb *= (overlay_brightness_bottom + (overlay_brightness_top - overlay_brightness_bottom) * g_layer);
	texel.rgb *= (1.0 - 0.5 * wetness);

	// dust overlay
		
	const vec3 dust_color  = vec3 (0.76, 0.65, 0.45);
	texel = mix (texel, dust_color, 0.7 * dust_cover_factor);
	
	// snow overlay
	
	//vec3 snow_texel = vec3 (0.95, 0.95, 0.95);

	float snow_factor = 0.2+0.8* smoothstep(0.2,0.8, 0.3 + 0.5 * snow_thickness_factor +0.0001*(g_altitude -snowlevel) );
	snow_factor *=  smoothstep(0.5, 0.7, steepness);

	snow_factor *= smoothstep(g_layer - 0.1, g_layer , snow_factor + 0.2);
	
	//texel.rgb = mix(texel.rgb, snow_texel.rgb, snow_factor * smoothstep(snowlevel, snowlevel+200.0, g_altitude - 100.0));
	value *=  (1.0 - snow_factor * smoothstep(snowlevel, snowlevel+200.0, g_altitude - 100.0));
		
	// do a conservative simple fog model, fading to alpha
	
	float min_visibility = min(visibility, avisibility);
		
	float base_alpha = clamp(0.4 * overlay_max_height/0.3, 0.4, 1.0);
	value*= base_alpha * (1.0 - d_fade);
	
	float targ = 8.0 * g_distance_to_eye/min_visibility;
	value *= exp(-targ - targ * targ * targ * targ);
	value= clamp(value, 0.0, 1.0);
	
	// cloud shadows
	
	float cloud_shade = 1.0;
	
	if (cloud_shadow_flag == 1)
		{
		vec2 eyePos = (gl_ModelViewMatrixInverse * vec4 (0.0, 0.0, 0.0, 1.0)).xy;
		vec2 relPos = g_rawpos - eyePos;
		
		
		cloud_shade = shadow_func_nearest(relPos.x, relPos.y, 1.0, g_distance_to_eye);
		}
	
	// lighting is very simple, the ground underneath should do most of it
	
	vec3 N = normalize (gl_NormalMatrix * g_normal);
	float NdotL = 0.5 + 1.0 * clamp(dot (N, gl_LightSource[0].position.xyz), 0.0, 1.0) * cloud_shade * getShadowing();
	
	texel *= length(gl_LightSource[0].diffuse.rgb)/1.73 * scattering * NdotL;
	texel = clamp(texel, 0.0, 1.0);
	
	
	vec4 fragColor = vec4 (texel, value);
	fragColor.rgb = filter_combined(fragColor.rgb);
	fragColor = clamp(fragColor, 0.0, 1.0);
	
    gl_FragColor = fragColor;
}
