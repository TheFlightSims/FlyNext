// -*-C++-*-
#version 120

// written by Thorsten Renk, Oct 2011, based on default.frag
// Ambient term comes in gl_Color.rgb.
varying vec4 diffuse_term;
varying vec3 normal;
varying vec3 relPos;
varying vec2 rawPos;
varying vec3 ecViewdir;
varying vec4 ecPosition;


uniform sampler2D texture;
uniform sampler2D NormalTex;
uniform sampler2D mix_texture;
uniform sampler2D grain_texture;

varying float steepness;


uniform float visibility;
uniform float avisibility;
uniform float scattering;
uniform float terminator;
uniform float terrain_alt; 
uniform float hazeLayerAltitude;
uniform float overcast;
uniform float eye_alt;
uniform float snowlevel;
uniform float dust_cover_factor;
uniform float lichen_cover_factor;
uniform float filter_threshold;
uniform float filter_transition;
uniform float size_base;
uniform float size_overlay;
uniform float size_grain;
uniform float strength_05m;
uniform float strength_1m;
uniform float strength_2m;
uniform float strength_5m;
uniform float strength_10m;
uniform float relief_strength;
uniform float grain_strength;
uniform float bias_center_strength;
uniform float wetness;
uniform float fogstructure;
uniform float snow_thickness_factor;
uniform float cloud_self_shading;
uniform float landing_light1_offset;
uniform float landing_light2_offset;
uniform float landing_light3_offset;
uniform float air_pollution;


uniform int quality_level;
uniform int tquality_level;
uniform int cloud_shadow_flag;
uniform int bias_center;
uniform int use_searchlight;
uniform int use_landing_light;
uniform int use_alt_landing_light;

const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;

float alt;
float eShade;
float yprime_alt;
float mie_angle;


float shadow_func (in float x, in float y, in float noise, in float dist);
float Noise2D(in vec2 coord, in float wavelength);
float fog_func (in float targ, in float alt);
float alt_factor(in float eye_alt, in float vertex_alt);
float light_distance_fading(in float dist);
float fog_backscatter(in float avisibility);
float rayleigh_in_func(in float dist, in float air_pollution, in float avisibility, in float eye_alt, in float vertex_alt);

vec3 searchlight();
vec3 landing_light(in float offset, in float offsetv);
vec3 rayleigh_out_shift(in vec3 color, in float outscatter);
vec3 get_hazeColor(in float light_arg);
vec3 filter_combined (in vec3 color) ;

float getShadowing();
vec3 getClusteredLightsContribution(vec3 p, vec3 n, vec3 texel);


void main()
{



yprime_alt = diffuse_term.a;
//diffuse_term.a = 1.0;
mie_angle = gl_Color.a;
float effective_scattering = min(scattering, cloud_self_shading);

// distance to fragment
float dist = length(relPos);
// angle of view vector with horizon
float ct = dot(vec3(0.0, 0.0, 1.0), relPos)/dist;


  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
// this is taken from default.frag
    vec3 n;
    float NdotL, NdotHV, fogFactor;
    vec4 color = gl_Color;
    color.a = 1.0;
    vec3 lightDir = gl_LightSource[0].position.xyz;
    vec3 halfVector;
    if (quality_level<6)
	{halfVector = gl_LightSource[0].halfVector.xyz;}
    else
	{halfVector = normalize(normalize(lightDir) + normalize(ecViewdir));}

    vec4 texel;
    vec4 snow_texel;
    vec4 mix_texel;
    vec4 grain_texel;
    vec4 fragColor;
    vec4 specular = vec4(0.0);
    float intensity;
    

// get noise at different wavelengths

// used:	5m, 5m gradient, 10m, 10m gradient: heightmap of the closeup terrain, 10m also snow
//		50m: detail texel
//		250m: detail texel
//		500m: distortion and overlay
// 		1500m: overlay, detail, dust, fog
//		2000m: overlay, detail, snow, fog

float noise_01m;
float noise_05m = Noise2D(rawPos.xy, 0.5);
float noise_1m = Noise2D(rawPos.xy, 1.0); 
float noise_2m = Noise2D(rawPos.xy, 2.0); 
float noise_10m = Noise2D(rawPos.xy, 10.0);
float noise_5m  = Noise2D(rawPos.xy ,5.0); 


float noisegrad_10m;
float noisegrad_5m;

float noise_50m = Noise2D(rawPos.xy, 50.0);; 
float noise_250m;
float noise_500m = Noise2D(rawPos.xy, 500.0);
float noise_1500m = Noise2D(rawPos.xy, 1500.0);
float noise_2000m = Noise2D(rawPos.xy, 2000.0);





//


// get the texels

    //texel = texture2D(texture, gl_TexCoord[0].st);
    //mix_texel = texture2D(mix_texture, gl_TexCoord[0].st * 5.0);
    texel = texture2D(texture, rawPos * 1.0/size_base);
    mix_texel = texture2D(mix_texture, rawPos * 1.0/size_overlay);
    grain_texel = texture2D(grain_texture, rawPos * 1.0/size_grain);
	vec4 nmap  = texture2D(NormalTex, gl_TexCoord[0].st * 8.0);
    //vec4 nmap  = texture2D(NormalTex, rawPos * 0.01);
	vec3 N = nmap.rgb * 2.0 - 1.0;

    float distortion_factor = 1.0;
    vec2 stprime;
    int flag = 1;
    int mix_flag = 1;
    float noise_term;
    float snow_alpha;

	
	//noise_term = smoothstep(overlay_limit ,1.0,noise_1m);
	//noise_term = smoothstep(overlay_limit, 1.0, 0.5 * noise_1m + 0.5 * noise_10m);
	noise_term = strength_05m * noise_05m;
	noise_term += strength_1m * noise_1m;
	noise_term += strength_2m * noise_2m;
	noise_term += strength_5m * noise_5m;
	noise_term += strength_10m * noise_10m;



	if (bias_center == 1)
		{
		float centerness = smoothstep(0.02, 0.1, (0.14 - abs(gl_TexCoord[0].s - 0.14)));
		centerness *= smoothstep(0.05, 0.15, gl_TexCoord[0].t);
		centerness = 1.0 - centerness;
		
		noise_term *= (1.0 - bias_center_strength) + bias_center_strength *  centerness;
		noise_term = clamp(noise_term, 0.0, 1.0);
		}	

	float filtered_noise_term = smoothstep(filter_threshold, filter_threshold + filter_transition, noise_term);	

	texel = mix(texel, mix_texel, filtered_noise_term);

   	texel.rgb = mix(texel.rgb, grain_texel.rgb, grain_strength * grain_texel.a * (1.0 - noise_term));// * (1.0-smoothstep(2000.0,5000.0, dist)));



    //float view_angle = abs(dot(normal, normalize(ecViewdir)));

    //if ((quality_level > 3)&&(relPos.z + eye_alt +500.0 > snowlevel))
	if (quality_level > 3)
	{
	float sfactor;
	noise_01m = Noise2D(rawPos.xy,0.1);
	snow_texel = vec4 (0.95, 0.95, 0.95, 1.0) * (0.9 + 0.1* noise_50m + 0.1* (1.0 - noise_10m) );
	snow_texel.a = 1.0;
	noise_term = 0.1 * (noise_50m-0.5);
	sfactor = 1.0;//sqrt(2.0 * (1.0-steepness)/0.03) + abs(ct)/0.15;
	noise_term = noise_term + 0.2 * (noise_10m -0.5) * (1.0 - smoothstep(10000.0*sfactor, 16000.0*sfactor, dist)  ) ;
	noise_term = noise_term + 0.3 * (noise_5m -0.5) * (1.0 - smoothstep(1200.0 * sfactor, 2000.0 * sfactor, dist)  ) ;
	noise_term = noise_term + 0.3 * (noise_1m -0.5) * (1.0 - smoothstep(500.0 * sfactor, 1000.0 *sfactor, dist)  );
	noise_term = noise_term + 0.3 * (noise_01m -0.5) * (1.0 - smoothstep(20.0 * sfactor, 100.0 *sfactor, dist)  );
	snow_texel.a = snow_texel.a * 0.2+0.8* smoothstep(0.2,0.8, 0.3 +noise_term + 0.2*snow_thickness_factor +0.0001*(relPos.z +eye_alt -snowlevel) );
   	
	}


const vec4 dust_color  = vec4 (0.76, 0.71, 0.56, 1.0);
const vec4 lichen_color = vec4 (0.17, 0.20, 0.06, 1.0);;
//float snow_alpha;

if (quality_level > 3)
	{

	// mix vegetation
	texel = mix(texel, lichen_color, 0.4 * lichen_cover_factor + 0.8 * lichen_cover_factor * 0.5 * (noise_10m + (1.0 - noise_5m))  );
	// mix dust
	texel = mix(texel, dust_color, clamp(0.5 * dust_cover_factor + 3.0 * dust_cover_factor * (((noise_1500m - 0.5) * 0.125)+0.125 ),0.0, 1.0) );
	
    	// mix snow
	if (relPos.z + eye_alt +500.0 > snowlevel)
		{
   		snow_alpha = smoothstep(0.75, 0.85, abs(steepness));
		texel = mix(texel, snow_texel, snow_texel.a* smoothstep(snowlevel, snowlevel+200.0,  snow_alpha * (relPos.z + eye_alt)+ (noise_2000m + 0.1 * noise_10m -0.55) *400.0));
		}
	}
else if (relPos.z + eye_alt +500.0 > snowlevel)
        {
            float snow_alpha = 0.5+0.5* smoothstep(0.2,0.8, 0.3 + snow_thickness_factor +0.0001*(relPos.z +eye_alt -snowlevel) );
//          texel = vec4(dot(vec3(0.2989, 0.5870, 0.1140), texel.rgb));
            texel = mix(texel, vec4(1.0), snow_alpha* smoothstep(snowlevel, snowlevel+200.0,  (relPos.z + eye_alt)));
        }



// get distribution of water when terrain is wet

float water_threshold1;
float water_threshold2;
float water_factor =0.0;


if ((dist < 5000.0)&& (quality_level > 3) && (wetness>0.0))
		{
		water_threshold1 = 1.0-0.5* wetness;
		water_threshold2 = 1.0 - 0.3 * wetness;
		//water_factor = smoothstep(water_threshold1, water_threshold2 ,   (0.3 * (2.0 * (1.0-noise_10m) + (1.0 -noise_5m)) *   (1.0 - smoothstep(2000.0, 5000.0, dist))) - 5.0 * (1.0 -steepness));
		water_factor = smoothstep(water_threshold1, water_threshold2 , 0.5 * (noise_5m + (1.0 -noise_1m))) *   (1.0 - smoothstep(1000.0, 3000.0, dist));
	}

// darken wet terrain

    texel.rgb = texel.rgb * (1.0 - 0.6 * wetness - 0.1 * water_factor);


// light computations


    vec4 light_specular = gl_LightSource[0].specular;

    // If gl_Color.a == 0, this is a back-facing polygon and the
    // normal should be reversed.
    //n = (2.0 * gl_Color.a - 1.0) * normal;
    n = normal;//vec3 (nvec.x, nvec.y, sqrt(1.0 -pow(nvec.x,2.0) - pow(nvec.y,2.0) ));
    n = normalize(n);

    NdotL = dot(n, lightDir);
    
	if (quality_level > 4)
		{
		NdotL = NdotL + (3.0 * N.r + 0.1 * (noise_01m-0.5))* (1.0 - water_factor) * relief_strength;
		//NdotL = NdotL + 3.0 * N.r + 0.1 * (noise_01m-0.5) ;
		}
    if (NdotL > 0.0) {
        float shadowmap = getShadowing();
	if (cloud_shadow_flag == 1) 
		{NdotL = NdotL * shadow_func(relPos.x, relPos.y, 1.0, dist);}
        color += diffuse_term * NdotL * shadowmap;
        NdotHV = max(dot(n, halfVector), 0.0);
        //if (gl_FrontMaterial.shininess > 0.0)
            specular.rgb = ((gl_FrontMaterial.specular.rgb + (water_factor * vec3 (1.0, 1.0, 1.0)))
                            * light_specular.rgb
                            * pow(NdotHV, gl_FrontMaterial.shininess + (20.0 * water_factor))
                            * shadowmap);
    }
    color.a = 1.0;//diffuse_term.a;
    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    color = clamp(color, 0.0, 1.0);

    vec3 secondary_light = vec3 (0.0,0.0,0.0);

    if (use_searchlight == 1)
	{
	secondary_light.rgb += searchlight();
	}
    if (use_landing_light == 1)
	{
	secondary_light += landing_light(landing_light1_offset, landing_light3_offset);
	}
    if (use_alt_landing_light == 1)
	{
	secondary_light += landing_light(landing_light2_offset, landing_light3_offset);
	}
    color.rgb +=secondary_light * light_distance_fading(dist);

    fragColor = color * texel + specular;
    fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, texel.rgb);

float lightArg = (terminator-yprime_alt)/100000.0;

vec3 hazeColor = get_hazeColor(lightArg);


// Rayleigh color shifts 

    if ((quality_level > 5) && (tquality_level > 5))
    	{
	float rayleigh_length = 0.5 * avisibility * (2.5 - 1.9 * air_pollution)/alt_factor(eye_alt, eye_alt+relPos.z);
	float outscatter = 1.0-exp(-dist/rayleigh_length);
        fragColor.rgb = rayleigh_out_shift(fragColor.rgb,outscatter);
// Rayleigh color shift due to in-scattering
	float rShade = 1.0 - 0.9 * smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt + 420000.0);
	float lightIntensity = length(hazeColor * effective_scattering) * rShade;
	vec3 rayleighColor = vec3 (0.17, 0.52, 0.87) * lightIntensity;
   	float rayleighStrength = rayleigh_in_func(dist, air_pollution, avisibility/max(lightIntensity,0.05), eye_alt, eye_alt + relPos.z);
  	fragColor.rgb = mix(fragColor.rgb, rayleighColor,rayleighStrength);
	}


// here comes the terrain haze model

float delta_z = hazeLayerAltitude - eye_alt;
float mvisibility = min(visibility, avisibility);

if (dist > 0.04 * mvisibility) 
{

alt = eye_alt;


float transmission;
float vAltitude;
float delta_zv;
float H;
float distance_in_layer;
float transmission_arg;




// we solve the geometry what part of the light path is attenuated normally and what is through the haze layer

if (delta_z > 0.0) // we're inside the layer
	{
	if (ct < 0.0) // we look down 
		{
		distance_in_layer = dist;
		vAltitude = min(distance_in_layer,mvisibility) * ct;
  		delta_zv = delta_z - vAltitude;
		}
	else 	// we may look through upper layer edge
		{
		H = dist * ct;
		if (H > delta_z) {distance_in_layer = dist/H * delta_z;}
		else {distance_in_layer = dist;}
		vAltitude = min(distance_in_layer,visibility) * ct;
  		delta_zv = delta_z - vAltitude;	
		}
	}
  else // we see the layer from above, delta_z < 0.0
	{	
	H = dist * -ct;
	if (H  < (-delta_z)) // we don't see into the layer at all, aloft visibility is the only fading
		{
		distance_in_layer = 0.0;
		delta_zv = 0.0;
		}		
	else
		{
		vAltitude = H + delta_z;
		distance_in_layer = vAltitude/H * dist; 
		vAltitude = min(distance_in_layer,visibility) * (-ct);
		delta_zv = vAltitude;
		} 
	}
	

// ground haze cannot be thinner than aloft visibility in the model,
// so we need to use aloft visibility otherwise


transmission_arg = (dist-distance_in_layer)/avisibility;


float eqColorFactor;



if (visibility < avisibility)
	{
	if (quality_level > 3)
		{
		transmission_arg = transmission_arg + (distance_in_layer/(1.0 * visibility + 1.0 * visibility * fogstructure * 0.06 * (noise_1500m + noise_2000m -1.0) ));

		}
	else
		{
		transmission_arg = transmission_arg + (distance_in_layer/visibility);
		}
	// this combines the Weber-Fechner intensity
	eqColorFactor = 1.0 - 0.1 * delta_zv/visibility - (1.0 - effective_scattering);

	}
else 
	{
	if (quality_level > 3)
		{
		transmission_arg = transmission_arg + (distance_in_layer/(1.0 * avisibility + 1.0 * avisibility * fogstructure * 0.06 * (noise_1500m + noise_2000m  - 1.0) ));
		}
	else
		{
		transmission_arg = transmission_arg + (distance_in_layer/avisibility);
		}
	// this combines the Weber-Fechner intensity
	eqColorFactor = 1.0 - 0.1 * delta_zv/avisibility - (1.0 - effective_scattering);
	}

transmission =  fog_func(transmission_arg, alt);

// there's always residual intensity, we should never be driven to zero
if (eqColorFactor < 0.2) eqColorFactor = 0.2;

// now dim the light for haze
eShade = 1.0 - 0.9 * smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt);

// Mie-like factor

	if (lightArg < 10.0)
		{
		intensity = length(hazeColor);
		float mie_magnitude = 0.5 * smoothstep(350000.0, 150000.0, terminator-sqrt(2.0 * EarthRadius * terrain_alt));
		hazeColor = intensity * ((1.0 - mie_magnitude) + mie_magnitude * mie_angle) * normalize(mix(hazeColor,  vec3 (0.5, 0.58, 0.65), mie_magnitude * (0.5 - 0.5 * mie_angle)) ); 
		}

intensity = length(hazeColor);

if (intensity > 0.0) // this needs to be a condition, because otherwise hazeColor doesn't come out correctly
{
	

	// high altitude desaturation of the haze color
	hazeColor = intensity * normalize (mix(hazeColor, intensity * vec3 (1.0,1.0,1.0), 0.7* smoothstep(5000.0, 50000.0, alt)));

	// blue hue of haze
	hazeColor.x = hazeColor.x * 0.83;
	hazeColor.y = hazeColor.y * 0.9; 


	// additional blue in indirect light
	float fade_out = max(0.65 - 0.3 *overcast, 0.45);
	intensity = length(hazeColor);
	hazeColor = intensity * normalize(mix(hazeColor,  1.5* shadedFogColor, 1.0 -smoothstep(0.25, fade_out,eShade) )); 

	// change haze color to blue hue for strong fogging
	hazeColor = intensity * normalize(mix(hazeColor,  shadedFogColor, (1.0-smoothstep(0.5,0.9,eqColorFactor)))); 

	

	// reduce haze intensity when looking at shaded surfaces, only in terminator region
	float shadow = mix( min(1.0 + dot(n,lightDir),1.0), 1.0, 1.0-smoothstep(0.1, 0.4, transmission));
	hazeColor = mix(shadow * hazeColor, hazeColor, 0.3 + 0.7* smoothstep(250000.0, 400000.0, terminator));
	}


// don't let the light fade out too rapidly
lightArg = (terminator + 200000.0)/100000.0;
float minLightIntensity = min(0.2,0.16 * lightArg + 0.5);
vec3 minLight = minLightIntensity * vec3 (0.2, 0.3, 0.4);

hazeColor.rgb *= eqColorFactor * eShade;
hazeColor.rgb = max(hazeColor.rgb, minLight.rgb);

fragColor.rgb = mix(hazeColor +secondary_light * fog_backscatter(mvisibility) , fragColor.rgb,transmission);

}

fragColor.rgb = filter_combined(fragColor.rgb);

gl_FragColor = fragColor;

}

