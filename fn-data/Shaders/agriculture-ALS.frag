// -*-C++-*-
#version 120

// written by Thorsten Renk, May 2014
// based on ALS terrain shader
// Ambient term comes in gl_Color.rgb.
varying vec4 diffuse_term;
varying vec3 normal;
varying vec3 relPos;
varying vec2 rawPos;
varying vec3 worldPos;
varying vec3 ecViewdir;
varying vec4 ecPosition;


uniform sampler2D texture;
uniform sampler2D mix_texture;
uniform sampler2D grain_texture;
uniform sampler2D gradient_texture;


varying float steepness;
varying vec2 grad_dir;


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
uniform float wetness;
uniform float fogstructure;
uniform float snow_thickness_factor;
uniform float cloud_self_shading;
uniform float season;
uniform float air_pollution;
uniform float grain_strength;
uniform float intrinsic_wetness;
uniform float overlay_fraction;
uniform float overlay_scale;
uniform float rotation_scale;
uniform float distortion_factor;
uniform float uv_xoffset;
uniform float uv_yoffset;
uniform float landing_light1_offset;
uniform float landing_light2_offset;
uniform float landing_light3_offset;

uniform float dust_resistance;
uniform float WindE;
uniform float WindN;
uniform float osg_SimulationTime;

uniform int quality_level;
uniform int tquality_level;
uniform int wind_effects;
uniform int cloud_shadow_flag;
uniform int rotation_flag;
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
float Noise3D(in vec3 coord, in float wavelength);
float VoronoiNoise2D(in vec2 coord, in float wavelength, in float xrand, in float yrand);	
float SlopeLines2D(in vec2 coord, in vec2 gradDir, in float wavelength, in float steepness);
float fog_func (in float targ, in float alt);
float rayleigh_in_func(in float dist, in float air_pollution, in float avisibility, in float eye_alt, in float vertex_alt);
float alt_factor(in float eye_alt, in float vertex_alt);
float light_distance_fading(in float dist);
float fog_backscatter(in float avisibility);

vec3 rayleigh_out_shift(in vec3 color, in float outscatter);
vec3 get_hazeColor(in float light_arg);
vec3 searchlight();
vec3 landing_light(in float offset, in float offsetv);
vec3 filter_combined (in vec3 color) ;

float getShadowing();
vec3 getClusteredLightsContribution(vec3 p, vec3 n, vec3 texel);


// a fade function for procedural scales which are smaller than a pixel

float detail_fade (in float scale, in float angle, in float dist)
{
float fade_dist = 2000.0 * scale * angle/max(pow(steepness,4.0), 0.1);

return 1.0 - smoothstep(0.5 * fade_dist, fade_dist, dist);
}





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
// float altitude of fragment above sea level
float msl_altitude = (relPos.z + eye_alt);


  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
// this is taken from default.frag
    vec3 n;
    float NdotL, NdotHV, fogFactor;
    vec4 color = gl_Color;
    color.a = 1.0;
    vec3 lightDir = gl_LightSource[0].position.xyz;
    vec3 halfVector = normalize(normalize(lightDir) + normalize(ecViewdir));
    vec4 texel;
    vec4 snow_texel;
    vec4 detail_texel;
    vec4 mix_texel;
	vec4 grain_texel;
	vec4 dot_texel;
	vec4 gradient_texel;
	vec4 foam_texel;
    vec4 fragColor;
    vec4 specular = vec4(0.0);
    float intensity;
    


// Wind motion of the overlay noise simulating movement of vegetation and loose debris

vec2 windPos;

if (wind_effects > 1)
	{
	float windSpeed = length(vec2 (WindE,WindN)) /3.0480; 
	// interfering sine wave wind pattern
	float sineTerm = sin(0.35 * windSpeed * osg_SimulationTime + 0.05 * (rawPos.x + rawPos.y));
	sineTerm = sineTerm + sin(0.3 * windSpeed * osg_SimulationTime + 0.04 * (rawPos.x + rawPos.y));
	sineTerm = sineTerm + sin(0.22 * windSpeed * osg_SimulationTime + 0.05 * (rawPos.x + rawPos.y));
	sineTerm = sineTerm/3.0;
	// non-linear amplification to simulate gusts
	sineTerm = sineTerm * sineTerm;//smoothstep(0.2, 1.0, sineTerm);

	// wind starts moving dust and leaves at around 8 m/s
	float timeArg = 0.01 * osg_SimulationTime * windSpeed * smoothstep(8.0, 15.0, windSpeed);
	timeArg = timeArg + 0.02 * sineTerm;

 	windPos = vec2 (rawPos.x + WindN * timeArg, rawPos.y +  WindE * timeArg);
	}
else
	{
	windPos = rawPos.xy;
	}

	
	
// get noise at different wavelengths

// used:	5m, 5m gradient, 10m, 10m gradient: heightmap of the closeup terrain, 10m also snow
//		50m: detail texel
//		250m: detail texel
//		500m: distortion and overlay
// 		1500m: overlay, detail, dust, fog
//		2000m: overlay, detail, snow, fog

// Perlin noise

float noise_10m = Noise2D(rawPos.xy, 10.0);
float noise_5m = Noise2D(rawPos.xy ,5.0);
float noise_2m = Noise2D(rawPos.xy ,2.0); 
float noise_1m = Noise2D(rawPos.xy ,1.0); 
float noise_01m = Noise2D(windPos.xy, 0.1);

float noisegrad_10m;
float noisegrad_5m;
float noisegrad_2m;
float noisegrad_1m;



float noise_25m = Noise2D(rawPos.xy, 25.0);
float noise_50m = Noise2D(rawPos.xy, 50.0);


float noise_250m = Noise3D(worldPos.xyz,250.0);
float noise_500m = Noise3D(worldPos.xyz, 500.0);
float noise_1500m = Noise3D(worldPos.xyz, 1500.0);
float noise_2000m = Noise3D(worldPos.xyz, 2000.0);

// tiling noise

float vnoise_overlay = VoronoiNoise2D(rawPos.xy, overlay_scale, distortion_factor, distortion_factor);	
float vnoise_rotation = VoronoiNoise2D(rawPos.xy, rotation_scale, distortion_factor, distortion_factor);



// slope noise

float slopenoise_50m = SlopeLines2D(rawPos, grad_dir, 50.0, steepness);
float slopenoise_100m = SlopeLines2D(rawPos, grad_dir, 100.0, steepness);

float snownoise_25m = mix(noise_25m, slopenoise_50m, clamp(3.0*(1.0-steepness),0.0,1.0));
float snownoise_50m = mix(noise_50m, slopenoise_100m, clamp(3.0*(1.0-steepness),0.0,1.0));



// get the texels

    float distortion_factor = 1.0;
    vec2 stprime;
    int flag = 1;
    int mix_flag = 1;
    float noise_term;
    float snow_alpha;

	float angle = vnoise_rotation * 2.0 * 3.1415;
	
	if (rotation_flag ==2)
		{
		if (vnoise_rotation < 0.25) {angle = 0.5 * 3.1415926;}
		else if (vnoise_rotation < 0.5) {angle = 3.1415926;}
		else if (vnoise_rotation < 0.75) {angle = 1.5 * 3.1415926;}
		else {angle = 0.0;}
		}
	
	if (rotation_flag > 0)
		{
		stprime = vec2 (cos(angle)*gl_TexCoord[0].s + sin(angle)*gl_TexCoord[0].t, -sin(angle)*gl_TexCoord[0].s + cos(angle)*gl_TexCoord[0].t);
		}
	else
		{stprime = gl_TexCoord[0].st;}
	stprime+= vec2 (uv_xoffset, uv_yoffset);
	texel = texture2D(texture, stprime);
    float local_autumn_factor = texel.a;
	grain_texel = texture2D(grain_texture, gl_TexCoord[0].st * 25.0);
	gradient_texel = texture2D(gradient_texture, gl_TexCoord[0].st * 4.0);


	// we need to fade procedural structures when they get smaller than a single pixel, for this we need
	// to know under what angle we see the surface

    float view_angle = abs(dot(normalize(normal), normalize(ecViewdir)));
	float sfactor = sqrt(2.0 * (1.0-steepness)/0.03) + abs(ct)/0.15;

	// the snow texel is generated procedurally
    if (msl_altitude +500.0 > snowlevel)
	{
	snow_texel = vec4 (0.95, 0.95, 0.95, 1.0) * (0.9 + 0.1* noise_500m + 0.1* (1.0 - noise_10m) );
	snow_texel.r = snow_texel.r * (0.9 + 0.05 * (noise_10m + noise_5m));
	snow_texel.g = snow_texel.g * (0.9 + 0.05 * (noise_10m + noise_5m));
	snow_texel.a = 1.0;
	noise_term = 0.1 * (noise_500m-0.5) ;
	noise_term = noise_term + 0.2 * (snownoise_50m -0.5) * detail_fade(50.0, view_angle, 0.5*dist) ;
	noise_term = noise_term + 0.2 * (snownoise_25m -0.5) * detail_fade(25.0, view_angle, 0.5*dist) ;
	noise_term = noise_term + 0.3 * (noise_10m -0.5) * detail_fade(10.0, view_angle, 0.8*dist) ;
	noise_term = noise_term + 0.3 * (noise_5m - 0.5) * detail_fade(5.0, view_angle, dist);
	noise_term = noise_term + 0.15 * (noise_2m -0.5) * detail_fade(2.0, view_angle, dist);
	noise_term = noise_term + 0.08 * (noise_1m -0.5) * detail_fade(1.0, view_angle, dist);
	snow_texel.a = snow_texel.a * 0.2+0.8* smoothstep(0.2,0.8, 0.3 +noise_term + snow_thickness_factor +0.0001*(msl_altitude -snowlevel) );
	}

	// the mixture/gradient texture
	mix_texel = texture2D(mix_texture, stprime * 1.3);
	if (mix_texel.a <0.1) {mix_flag = 0;}

	

// texture preparation according to detail level

// mix in hires texture patches

float dist_fact; 
float nSum;
float mix_factor;
   
   // first the second texture overlay
   // transition model 0: random patch overlay without any gradient information
   // transition model 1: only gradient-driven transitions, no randomness
   
   
   if (mix_flag == 1)
	{
	//nSum =  0.18 * (2.0 * noise_2000m + 2.0 * noise_1500m + noise_500m);
	//nSum = mix(nSum, 0.5, max(0.0, 2.0 * (transition_model - 0.5)));
	//nSum = nSum + 0.4 * (1.0 -smoothstep(0.9,0.95, abs(steepness)+ 0.05 * (noise_50m - 0.5))) * min(1.0, 2.0 * transition_model);
	//mix_factor = smoothstep(0.5, 0.54, nSum);
    if (vnoise_overlay > overlay_fraction) {mix_factor = 0.0;} else {mix_factor = 1.0;}
	texel = mix(texel, mix_texel, mix_factor);
	local_autumn_factor = texel.a;
	}
   
  
	
	// rock for very steep gradients
	
	if (gradient_texel.a > 0.0)
		{
		texel = mix(texel, gradient_texel, 1.0 - smoothstep(0.75,0.8,abs(steepness)+ 0.00002* msl_altitude + 0.05 * (noise_50m - 0.5)));
		local_autumn_factor = texel.a;
		}
   


   
   
   
   // then the grain texture overlay
   
   texel.rgb = mix(texel.rgb, grain_texel.rgb, grain_strength * grain_texel.a * (1.0 - mix_factor) * (1.0-smoothstep(2000.0,5000.0, dist)));

   // for really hires, add procedural noise overlay
   texel.rgb = texel.rgb * (1.0 + 0.4 * (noise_01m-0.5) * detail_fade(0.1, view_angle, dist)) ;

// autumn colors

float autumn_factor = season * 2.0 * (1.0 - local_autumn_factor) ;


texel.r = min(1.0, (1.0 + 2.5 * autumn_factor) * texel.r);
texel.g = texel.g;
texel.b = max(0.0, (1.0 - 4.0 * autumn_factor) *  texel.b);


if (local_autumn_factor < 1.0)
	{
	intensity = length(texel.rgb) * (1.0 - 0.5 * smoothstep(1.1,2.0,season));
	texel.rgb = intensity * normalize(mix(texel.rgb, vec3(0.23,0.17,0.08), smoothstep(1.1,2.0, season)));
	}

 // slope line overlay
 texel.rgb = texel.rgb * (1.0  - 0.12 * slopenoise_50m - 0.08 * slopenoise_100m);	
	
//const vec4 dust_color  = vec4 (0.76, 0.71, 0.56, 1.0);
const vec4 dust_color  = vec4 (0.76, 0.65, 0.45, 1.0);
const vec4 lichen_color = vec4 (0.17, 0.20, 0.06, 1.0);

// mix vegetation
float gradient_factor = smoothstep(0.5, 1.0, steepness);
texel = mix(texel, lichen_color, gradient_factor * (0.4 * lichen_cover_factor +  0.8 * lichen_cover_factor * 0.5 * (noise_10m + (1.0 - noise_5m)))  );
// mix dust
texel = mix(texel, dust_color, clamp(0.5 * dust_cover_factor *dust_resistance + 3.0 * dust_cover_factor * dust_resistance *(((noise_1500m - 0.5) * 0.125)+0.125 ) - 0.03*slopenoise_100m,0.0, 1.0) );
// mix snow
float snow_mix_factor = 0.0;
if (msl_altitude +500.0 > snowlevel)
	{
   	snow_alpha = smoothstep(0.75, 0.85, abs(steepness));
	snow_mix_factor = snow_texel.a* smoothstep(snowlevel, snowlevel+200.0,  snow_alpha * msl_altitude+ (noise_2000m + 0.1 * noise_10m -0.55) *400.0);
	texel = mix(texel, snow_texel, snow_mix_factor);
	}
	
 


// get distribution of water when terrain is wet

float combined_wetness = min(1.0, wetness + intrinsic_wetness);
float water_threshold1;
float water_threshold2;
float water_factor =0.0;


if ((dist < 5000.0)&& (quality_level > 3) && (combined_wetness>0.0))
		{
		water_threshold1 = 1.0-0.5* combined_wetness;
		water_threshold2 = 1.0 - 0.3 * combined_wetness;
		water_factor = smoothstep(water_threshold1, water_threshold2 ,   (0.3 * (2.0 * (1.0-noise_10m) + (1.0 -noise_5m)) *   (1.0 - smoothstep(2000.0, 5000.0, dist))) - 5.0 * (1.0 -steepness));
	}

// darken wet terrain

    texel.rgb = texel.rgb * (1.0 - 0.6 * combined_wetness);
	


// light computations


    vec4 light_specular = gl_LightSource[0].specular;

    // If gl_Color.a == 0, this is a back-facing polygon and the
    // normal should be reversed.
    //n = (2.0 * gl_Color.a - 1.0) * normal;
    n = normal;//vec3 (nvec.x, nvec.y, sqrt(1.0 -pow(nvec.x,2.0) - pow(nvec.y,2.0) ));
    n = normalize(n);

    NdotL = dot(n, lightDir);
	
	noisegrad_10m = (noise_10m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),10.0))/0.05;
	noisegrad_5m = (noise_5m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),5.0))/0.05;
	noisegrad_2m = (noise_2m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),2.0))/0.05;
	noisegrad_1m = (noise_1m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),1.0))/0.05;


	
	NdotL = NdotL + (noisegrad_10m * detail_fade(10.0, view_angle,dist) + 0.5* noisegrad_5m * detail_fade(5.0, view_angle,dist)) * mix_factor/0.8;
	NdotL = NdotL + 0.15 * noisegrad_2m * mix_factor/0.8 * detail_fade(2.0,view_angle,dist);
	NdotL = NdotL + 0.1 * noisegrad_2m * detail_fade(2.0,view_angle,dist);
	NdotL = NdotL + 0.05 * noisegrad_1m * detail_fade(1.0, view_angle,dist);
	
    if (NdotL > 0.0) {
        float shadowmap = getShadowing();
	if (cloud_shadow_flag == 1) {NdotL = NdotL * shadow_func(relPos.x, relPos.y, 0.3 * noise_250m + 0.5 * noise_500m+0.2 * noise_1500m, dist);}
        color += diffuse_term * NdotL * shadowmap;
        NdotHV = max(dot(n, halfVector), 0.0);
        if (gl_FrontMaterial.shininess > 0.0)
            specular.rgb = ((gl_FrontMaterial.specular.rgb * 0.1 + (water_factor * vec3 (1.0, 1.0, 1.0)))
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
	secondary_light += searchlight();
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



// Rayleigh color shift due to out-scattering
    float rayleigh_length = 0.5 * avisibility * (2.5 - 1.9 * air_pollution)/alt_factor(eye_alt, eye_alt+relPos.z);
    float outscatter = 1.0-exp(-dist/rayleigh_length);
    fragColor.rgb = rayleigh_out_shift(fragColor.rgb,outscatter);

// Rayleigh color shift due to in-scattering

   float rShade = 1.0 - 0.9 * smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt + 420000.0);
   //float lightIntensity = length(diffuse_term.rgb)/1.73 * rShade;
   float lightIntensity = length(hazeColor * effective_scattering) * rShade;
   vec3 rayleighColor = vec3 (0.17, 0.52, 0.87) * lightIntensity;
   float rayleighStrength = rayleigh_in_func(dist, air_pollution, avisibility/max(lightIntensity,0.05), eye_alt, eye_alt + relPos.z);
  fragColor.rgb = mix(fragColor.rgb, rayleighColor,rayleighStrength);


// here comes the terrain haze model


float delta_z = hazeLayerAltitude - eye_alt;

float mvisibility = min(visibility,avisibility);

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
	
// blur of the haze layer edge

float blur_thickness = 50.0;
float cphi = dot(vec3(0.0, 1.0, 0.0), relPos)/dist;
float ctlayer = delta_z/dist-0.01 + 0.02 * Noise2D(vec2(cphi,1.0),0.1) -0.01;
float ctblur = 	0.035 ;

float blur_dist;

if (abs(delta_z) < 400.0)
	{
	blur_dist = dist * (1.0-smoothstep(0.0,300.0,-delta_z)) * smoothstep(-400.0,-200.0, -delta_z);
	blur_dist = blur_dist * smoothstep(ctlayer-4.0*ctblur, ctlayer-ctblur, ct) * (1.0-smoothstep(ctlayer+0.5*ctblur, ctlayer+ctblur, ct));
	distance_in_layer = max(distance_in_layer, blur_dist);
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


//float lightArg = (terminator-yprime_alt)/100000.0;



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

fragColor.rgb = mix(hazeColor  + secondary_light * fog_backscatter(mvisibility), fragColor.rgb,transmission);

}

fragColor.rgb = filter_combined(fragColor.rgb);

gl_FragColor =  fragColor;

}

