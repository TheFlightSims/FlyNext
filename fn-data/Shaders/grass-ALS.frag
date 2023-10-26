// -*-C++-*-
#version 120

#define BLADE_FRACTION 0.1
#define MAX_LAYERS 20
#define MAX_DISTANCE 1000.0

uniform float visibility;
uniform float scattering;
uniform float overlay_bias;
uniform float season;
uniform float max_height;
uniform float grass_density;
uniform float grass_modulate_height_min;

uniform float wind_x;
uniform float wind_y;

uniform float wash_x;
uniform float wash_y;
uniform float wash_strength;

uniform int grass_modulate_by_overlay;
uniform int grass_groups;
uniform int wind_effects;

uniform sampler2D colorTex;
uniform sampler2D densityTex;

uniform float osg_SimulationTime;

varying vec2 g_rawpos;                  // Horizontal position in model space
varying float g_distance_to_eye;        // Distance to the camera. Layers were disregarded
varying float g_layer;				       // The layer where the fragment lives (0-1 range)

float rand2D(in vec2 co);
float Noise2D(in vec2 co, in float wavelength);
vec3 filter_combined (in vec3 color) ;

float getShadowing();


float map(float s, float a1, float a2, float b1, float b2)
{
    return b1+(s-a1)*(b2-b1)/(a2-a1);
}

float decodeBinary(float n, float layer)
{
	return float(mod(floor(n*pow(0.5, layer)), 2.0));
}


float bladeNoise2D(in float x, in float y, in float dDensity, in float layer, in float d_factor, in float h_factor)
{
	float integer_x    = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y    = y - fract(y);
    float fractional_y = y - integer_y;

	if (rand2D(vec2(integer_x+1.0, integer_y +1.0)) > dDensity)
		{return 0.0;}

	float hfact =  0.7 + 0.3 * (rand2D(vec2(integer_x, integer_y + 2.0)));
	hfact *= h_factor;
	
	if (layer > hfact) {return 0.0;}	
		
    float xoffset = (rand2D(vec2(integer_x, integer_y)) -0.5);
    float yoffset = (rand2D(vec2(integer_x+1.0, integer_y)) - 0.5);
	
	float xbend =  (rand2D(vec2(integer_x+1.0, integer_y + 1.0)) - 0.5);
	float ybend =  (rand2D(vec2(integer_x, integer_y + 1.0)) - 0.5);
	float fraction = BLADE_FRACTION * (0.5 + 0.5 * (1.0 - smoothstep(0.5, 1.0, layer)));

	float bend = 0.5 * layer * layer;
	
	vec2 truePos = vec2 (0.5 + xoffset * (1.0 - 2.0 * BLADE_FRACTION) + xbend * bend, 0.5 + yoffset * (1.0 -2.0 * BLADE_FRACTION) +  ybend * bend);

	float distance = length(truePos - vec2(fractional_x, fractional_y));
	return 1.0 - step (fraction * d_factor, distance);
}

float BladeNoise2D(in vec2 coord, in float wavelength, in float dDensity, in float layer, in float d_factor, in float h_factor)
{
return bladeNoise2D(coord.x/wavelength, coord.y/wavelength, dDensity, layer, d_factor, h_factor);
}

void main()
{

	if (season > 1.6) {discard;}
	if (g_distance_to_eye > MAX_DISTANCE) {discard;}

	vec2 texCoord = gl_TexCoord[0].st;
		
	if (wind_effects > 1)
	{
	
		vec2 eyePos = (gl_ModelViewMatrixInverse * vec4 (0.0, 0.0, 0.0, 1.0)).xy;
		
		vec2 washDir = vec2 (wash_x, wash_y) - (g_rawpos - eyePos);
		float washStrength = 20.0 * min(14.0 * wash_strength/(length(washDir) + 1.0), 1.0);
		washStrength *= (1.0 - 0.8 * sin(20.0 * osg_SimulationTime + length(washDir) + dot(normalize(washDir), vec2(1.0, 0.0))));
				
		vec2 windDir = normalize(vec2 (max(wind_x, 0.1), wind_y) + washStrength * vec2 (-washDir.y, washDir.x));
		
		float windStrength = 0.5 * length(vec2 (wind_x, wind_y)) + washStrength;
		float windAmplitude = 1.0 + 0.3 * windStrength;
		float sineTerm = sin(0.7 * windStrength * osg_SimulationTime + 0.05 * (g_rawpos.x + g_rawpos.y));
		sineTerm = sineTerm + sin(0.6 * windStrength * osg_SimulationTime + 0.04 * (g_rawpos.x + g_rawpos.y));
		sineTerm = sineTerm + sin(0.44 * windStrength * osg_SimulationTime + 0.05 * (g_rawpos.x + g_rawpos.y));
		sineTerm = sineTerm/3.0;
		sineTerm = 5.0 * sineTerm * sineTerm;

		float windDisplacement = pow(g_layer/32.0, 2.0) * clamp((windStrength + windAmplitude * sineTerm), -35.0, 35.0);

		texCoord += (windDisplacement * windDir);
	}

	

	
	float noise_1m = Noise2D(g_rawpos.xy, 1.0); 
	float noise_2m = Noise2D(g_rawpos.xy, 2.0); ;
	float noise_10m = Noise2D(g_rawpos.xy, 10.0);
	
	float h_factor;
	float overlay_mix = smoothstep(0.45, 0.65, overlay_bias + (0.5 * noise_1m + 0.1 * noise_2m + 0.4 * noise_10m));
	
	if (grass_modulate_by_overlay == 1)
			{h_factor = grass_modulate_height_min + (1.0 - grass_modulate_height_min) * (1.0 - overlay_mix) ;}
	else	
			{h_factor = 1.0;}
	
	float value = 0.0;
	
	float d_fade =smoothstep(100.0, MAX_DISTANCE, g_distance_to_eye);
	float d_factor = 1.0 + 1.0 * d_fade;
	d_factor *= clamp(max_height/0.3,0.5, 1.0);
	
	float bladeFlag = BladeNoise2D(texCoord, 0.015, grass_density, g_layer, d_factor, h_factor);
	if (grass_groups >1) {bladeFlag += BladeNoise2D(texCoord, 0.01, grass_density, g_layer, d_factor, h_factor);}
	if (grass_groups >2) {bladeFlag += BladeNoise2D(texCoord, 0.007, grass_density, g_layer, d_factor, h_factor);}

		
	if (bladeFlag > 0.0) {value = 1.0;}
	else {discard;}
	
	vec3 texel = texture2D(colorTex, texCoord).rgb;

	// autumn coloring
	
	texel.r = min(1.0, (1.0 + 2.5  * 0.1 * season) * texel.r);
	texel.g = texel.g;
	texel.b = max(0.0, (1.0 - 4.0  * 0.1 * season) *  texel.b);
	float intensity = length(texel.rgb) * (1.0 - 0.5 * smoothstep(1.1,2.0,season)) * mix(0.3, 1.0, getShadowing());
	texel.rgb = intensity * normalize(mix(texel.rgb, vec3(0.23,0.17,0.08), smoothstep(1.1,2.0, season)));
		
	float base_alpha = clamp(0.4 * max_height/0.3, 0.4, 1.0);
	value*= base_alpha * (1.0 - d_fade);
	
	value *= 1.0 - smoothstep(visibility* 0.5, visibility, g_distance_to_eye);
	value= clamp(value, 0.0, 1.0);
	
	texel *= length(gl_LightSource[0].diffuse.rgb)/1.73 * scattering;
	texel = clamp(texel, 0.0, 1.0);
	
	
	vec4 fragColor = vec4 (texel, value);
	fragColor.rgb = filter_combined(fragColor.rgb);

    gl_FragColor = fragColor;
}
