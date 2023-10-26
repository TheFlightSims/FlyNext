// WS30 FRAGMENT SHADER

// -*-C++-*-
#version 130
#extension GL_EXT_texture_array : enable
// written by Thorsten Renk, Oct 2011, based on default.frag

//////////////////////////////////////////////////////////////////
// TEST PHASE TOGGLES AND CONTROLS
//
//   Remove haze and lighting and shows just the texture. 
//     Useful for checking texture rendering and scenery.
//     The compiler will likely optimise out the haze and lighting calculations.
//     Possible values: 0:Normal, 1:Just the texture.
const int remove_haze_and_lighting = 0;

//   Randomise texture lookups for 5 non-base textures e.g. mix_texture, detaile_texture etc.
//    Each landclass is assigned 5 random textures from the ground texture array.
//    This simulates a worst case possible texture lookup scenario, without needing access to material parameters.
//      This does not simulate multiple texture sets, of which there may be up-to 4.
//      The performance will likely be worse than in a real situation - there might be fewer textures
//        for mix, detail and other textures. This might be easier on the GPUs texture caches.
//   Possible values: 0: disabled (default), 
//                    1: enabled, 
//                    2: remove texture array lookups for 5 textures - only base texture + neighbour base textures
const int randomise_texture_lookups = 0;

//   Use built-in water shader.  Use for testing impact of ws30-water.frag
const int water_shader = 1;

//
// End of test phase controls
//////////////////////////////////////////////////////////////////

// Ambient term comes in gl_Color.rgb.
varying vec4 light_diffuse_comp;
varying vec3 normal;
varying vec3 relPos;
varying vec2 ground_tex_coord;
varying vec3 worldPos;
varying vec2 rawPos;
varying vec3 ecViewdir;
varying vec2 grad_dir;
varying vec4 ecPosition;
varying float steepness;

uniform sampler2D landclass;
uniform sampler2DArray textureArray;
uniform sampler2D perlin;

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

uniform float WindE;
uniform float WindN;
uniform float landing_light1_offset;
uniform float landing_light2_offset;
uniform float landing_light3_offset;
uniform float osg_SimulationTime;

uniform int wind_effects;
uniform int cloud_shadow_flag;
uniform int use_searchlight;
uniform int use_landing_light;
uniform int use_alt_landing_light;
// Testing code: Currently hardcoded to 2000, to allow noise functions to run while waiting for landclass lookup(s)
uniform int swatch_size;  //in metres, typically 1000 or 2000

// Passed from VPBTechnique, not the Effect
uniform float fg_tileWidth;
uniform float fg_tileHeight;
uniform bool fg_photoScenery;
// Material parameters, from material definitions and effect defaults, for each landclass.
// xsize and ysize
uniform vec4 fg_dimensionsArray[128]; 
// RGBA ambient color
uniform vec4 fg_ambientArray[128];
// RGBA diffuse color
uniform vec4 fg_diffuseArray[128];    
// RGBA specular color
uniform vec4 fg_specularArray[128];
// Indicies of textures in the ground texture array for different 
// texture slots (grain, gradient, dot, mix, detail) for each landclass
uniform vec4 fg_textureLookup1[128];
uniform vec4 fg_textureLookup2[128];
// Each element of a vec4 contains a different materials parameter.
uniform vec4 fg_materialParams1[128];
uniform vec4 fg_materialParams2[128];
uniform vec4 fg_materialParams3[128];

// Coastline texture - generated from VPBTechnique
uniform sampler2D coastline;

// Sand texture
uniform sampler2D sand;

uniform mat4 fg_zUpTransform;
uniform vec3 fg_modelOffset;

const float terminator_width = 200000.0;

float shadow_func (in float x, in float y, in float noise, in float dist);
float DotNoise2D(in vec2 coord, in float wavelength, in float fractionalMaxDotSize, in float dot_density);
float Noise2D(in vec2 coord, in float wavelength);
float Noise3D(in vec3 coord, in float wavelength);
float SlopeLines2D(in vec2 coord, in vec2 gradDir, in float wavelength, in float steepness);
float Strata3D(in vec3 coord, in float wavelength, in float variation);
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

//////////////////////////
// Test-phase code:


// These should be sent as uniforms

// Tile dimensions in meters
// vec2 tile_size = vec2(fg_tileWidth , fg_tileHeight);
// Testing: texture coords are sent flipped right now:

// Note tile_size is defined in the shader include: ws30-landclass-search-functions.frag.
//vec2 tile_size = vec2(fg_tileHeight , fg_tileWidth);


// Uniform array lookup functions example:
// Access data[] as if it was a 1-d array of floats
// with data sorted as rows of data values for each row of texture variants
// using index for the relevant value
/*
float getFloatFromArrayData(int i)
{
    int n = int(floor(float(i/4.0)));
    vec4 v4 = someArray[n];
    int index_within_v4 = int(mod(float(i),4.0));
    float value = v4[index_within_v4];
    return value;
}


vec4 getVec4FromArrayData(int i) 
{
  return (vec4(getFloatFromArrayData(i), getFloatFromArrayData(i+1), getFloatFromArrayData(i+2), getFloatFromArrayData(i+3)));
}
*/



// From noise.frag
float rand2D(in vec2 co);


// Generates a full precision 32 bit random number from 2 seeds
//     as well as 6 random integers between 0 and factor that are rescaled 0.0-1.0
//     by re-using the significant figures from the full precision number.
//     This avoids having to generate 6 random numbers when 
//     limited variation is needed: say 6 numbers with 100 levels (i.e between 0 and 100).
// Seed 2 is incremented so the function can be called again to generate
//      a different set of numbers
float get6_rand_nums(in float PRNGseed1, 
  inout float PRNGseed2, float factor, out float [6] random_integers
  );



// Create random landclasses without a texture lookup to stress test.
// Each square of square_size in m is assigned a random landclass value.
int get_random_landclass(in vec2 co, in vec2 tile_size);

// End Test-phase code
////////////////////////


// These functions, and other function they depend on, are defined
// in ws30-ALS-landclass-search.frag.

// Lookup a ground texture at a point based on the landclass at that point, without visible 
//   seams at coordinate discontinuities or at landclass boundaries where texture are switched.
//   The partial derivatives of the tile_coord at the fragment is needed to adjust for 
//   the stretching of different textures, so that the correct mip-map level is looked 
//   up and there are no seams.
//   Texture types: 0: base texture, 1: grain texture, 2: gradient texture, 3 dot texture, 
//     4: mix texture, 5: detail texture.

vec4 lookup_ground_texture_array(in int texture_type, in vec2 ground_texture_coord, in int landclass_id,
  in vec4 dFdx_and_dFdy);


// Look up the landclass id [0 .. 255] for this particular fragment.
// Lookup id of any neighbouring landclass that is within the search distance.
// Searches are performed in upto 4 directions right now, but only one landclass is looked up
// Create a mix factor werighting the influences of nearby landclasses
void get_landclass_id(in vec2 tile_coord, in vec4 dFdx_and_dFdy, 
  out int landclass_id, out ivec4 neighbor_landclass_ids, 
  out int num_unique_neighbors,out vec4 mix_factor
  );


//  Look up the texel of the specified texture type (e.g. grain or detail textures) for this fragment
//    and any neighbor texels, then mix.

vec4 get_mixed_texel(in int texture_type, in vec2 g_texture_coord, 
  in int landclass_id, in int num_unique_neighbors, 
  in ivec4 neighbor_texel_landclass_ids, in vec4 neighbor_mix_factors,
  in vec4 dFdx_and_dFdy
  );

// Determine the texel and material parameters for a particular fragment, 
// Taking into account photoscenery etc.
void get_material(in  int   landclass, 
                  in  vec2  ground_tex_coord,
                  in  vec4  dxdy_gc,
                  out float mat_shininess,
                  out vec4  mat_ambient,
                  out vec4  mat_diffuse,
                  out vec4  mat_specular,
                  out vec4  dxdy,
                  out vec2  st
  );

// Apply the ALS haze model to a specific fragment
vec4 applyHaze(inout vec4  fragColor, 
               inout vec3  hazeColor, 
			   in    vec3  secondary_light,
			   in    float ct,
			   in    float hazeLayerAltitude,
			   in    float visibility,
			   in    float avisibility,
			   in    float dist,
			   in    float lightArg,
         in    float mie_angle);

// Procedurally generate a water texel for this fragment
vec4 generateWaterTexel();


void main()
{
  float yprime_alt = light_diffuse_comp.a;
  //diffuse_term.a = 1.0;
  float mie_angle = gl_Color.a;
  float effective_scattering = min(scattering, cloud_self_shading);
  
  // distance to fragment
  float dist = length(relPos);
  // angle of view vector with horizon
  float ct = dot(vec3(0.0, 0.0, 1.0), relPos)/dist;
  // float altitude of fragment above sea level
  float msl_altitude = (relPos.z + eye_alt);
  
  
  // this is taken from default.frag
  float NdotL, NdotHV, fogFactor;
  vec3 n = normalize(normal);
  vec3 lightDir = gl_LightSource[0].position.xyz;
  vec3 halfVector = normalize(normalize(lightDir) + normalize(ecViewdir));
  vec3 secondary_light = vec3 (0.0,0.0,0.0);
  

  // Material/texel properties
  float mat_shininess;
  vec2 st;
  vec4 mat_ambient, mat_diffuse, mat_specular, dxdy;

  vec4 texel;
  vec4 snow_texel;
  vec4 detail_texel;
  vec4 mix_texel;
  vec4 grain_texel;
  vec4 dot_texel;
  vec4 gradient_texel;
  
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


  // get noise at different wavelengths in units of swatch_size
  // original assumed 4km texture.
  
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
  
  // Noise relative to swatch size
  float noise_25m = Noise2D(rawPos.xy, swatch_size*0.000625);
  float noise_50m = Noise2D(rawPos.xy, swatch_size*0.00125);
  float noise_250m = Noise3D(worldPos.xyz,swatch_size*0.0625);
  float noise_500m = Noise3D(worldPos.xyz, swatch_size*0.125);
  float noise_1500m = Noise3D(worldPos.xyz, swatch_size*0.3750);
  float noise_2000m = Noise3D(worldPos.xyz, swatch_size*0.5);
  float noise_4000m = Noise3D(worldPos.xyz, swatch_size);

  float dotnoisegrad_10m;
  

  // slope noise
  float slopenoise_50m = SlopeLines2D(rawPos.xy, grad_dir, 50.0, steepness);
  float slopenoise_100m = SlopeLines2D(rawPos.xy, grad_dir, 100.0, steepness);
  
  float snownoise_25m = mix(noise_25m, slopenoise_50m, clamp(3.0*(1.0-steepness),0.0,1.0));
  float snownoise_50m = mix(noise_50m, slopenoise_100m, clamp(3.0*(1.0-steepness),0.0,1.0));
  
  // get the texels
  
  

  float distortion_factor = 1.0;
  vec2 stprime;
  int flag = 1;
  int mix_flag = 1;
  float noise_term;
  float snow_alpha;

  // Oct 27 2021:
  // Geometry is in the form of roughly rectangular 'tiles'
  // with a mesh forming a grid with regular spacing. 
  // Each vertex in the mesh is given an elevation
  
  // Tile dimensions in m
  // Testing: created from two float uniforms in global scope. Should be sent as a vec2
  // vec2 tile_size
  
  // This is a water fragment, so calculate the fragment color procedurally
  // and mix with some sand and cliff colour depending on steepness
  //vec4 steep_texel = lookup_ground_texture_array(2, ground_tex_coord, lc, dxdy_gc);  // Uses the same index as the gradient texture, which it is
  //vec4 beach_texel = lookup_ground_texture_array(3, ground_tex_coord, lc, dxdy_gc);  // Use the dot texture, which is overloaded to be the beach texture

  // Mix from a rocky texture to beach for steep slopes, which invariably represent the elevation mesh not being perfectly
  // aligned with the landclass mesh.
  // texel = mix(steep_texel, beach_texel, smoothstep(waterline_max_steepness - 0.1, waterline_max_steepness - 0.03, steepness));

  // Mix from the beach into the water, which produces a pleasing translucent shallow water effect.
  //fragColor = mix(texel, generateWaterTexel(), smoothstep(waterline_min_steepness,waterline_max_steepness,steepness));    
  fragColor = generateWaterTexel();
  fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, fragColor.rgb);    
    
  float lightArg = (terminator-yprime_alt)/100000.0;
  vec3 hazeColor = get_hazeColor(lightArg);

  // Rayleigh color shift due to out-scattering
  float rayleigh_length = 0.5 * avisibility * (2.5 - 1.9 * air_pollution)/alt_factor(eye_alt, msl_altitude);
  float outscatter = 1.0-exp(-dist/rayleigh_length);
  fragColor.rgb = rayleigh_out_shift(fragColor.rgb,outscatter);

  // Rayleigh color shift due to in-scattering
  
  float rShade = 1.0 - 0.9 * smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt + 420000.0);
  //float lightIntensity = length(diffuse_term.rgb)/1.73 * rShade;
  float lightIntensity = length(hazeColor * effective_scattering) * rShade;
  vec3 rayleighColor = vec3 (0.17, 0.52, 0.87) * lightIntensity;
  float rayleighStrength = rayleigh_in_func(dist, air_pollution, avisibility/max(lightIntensity,0.05), eye_alt, msl_altitude);
  fragColor.rgb = mix(fragColor.rgb, rayleighColor,rayleighStrength);
  
  gl_FragColor = applyHaze(fragColor, hazeColor, secondary_light, ct, hazeLayerAltitude, visibility, avisibility, dist, lightArg, mie_angle);
  
  // Testing phase controls:
  if (remove_haze_and_lighting == 1)
  {
    gl_FragColor = texel;
  }
}
