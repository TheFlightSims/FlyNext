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
  
  // Tile texture coordinates range [0..1] over the tile 'rectangle'
  vec2 tile_coord = gl_TexCoord[0].st;

  // Testing code: Coordinate used by ground texture arrays
  //vec2 ground_tex_coord = gl_TexCoord[0].st;
  
  // Test phase: Constants and toggles for transitions between landlcasses are defined at
  // the top landclass-search-functions.frag.
  // There are some controls for haze and lighting at the top of this file.
  
  // Look up the landclass id [0 .. 255] for this particular fragment
  // and any neighbouring landclass that is close.
  // Each tile has 1 texture containing landclass ids stetched over it.
  
  // Landclass for current fragment, and up-to 4 neighboring landclasses - 2 used currently
  int lc;
  ivec4 lc_n;
  
  int num_unique_neighbors = 0;
  
  // Mix factor of base textures for 2 neighbour landclass(es)
  vec4 mfact;

  bool water = false;
  
  // Partial derivatives of s and t of ground texture coords for this fragment, 
  // with respect to window (screen space) x and y axes.
  // Used to pick mipmap LoD levels, and turn off unneeded procedural detail
  // dFdx and dFdy are packed in a vec4 so multiplying everything
  // to scale takes 1 instruction slot.
  vec4 dxdy_gc = vec4(dFdx(ground_tex_coord) , dFdy(ground_tex_coord));
  
  get_landclass_id(tile_coord, dxdy_gc, lc, lc_n, num_unique_neighbors, mfact);
  get_material(lc, ground_tex_coord, dxdy_gc, mat_shininess, mat_ambient, mat_diffuse, mat_specular, dxdy, st);
  vec4 coast = texture2D(coastline, tile_coord);
  
  if (fg_photoScenery) {
    // The photoscenery orthophotos are stored in the landclass texture
    // and use normalised tile coordinates
    texel = texture(landclass, vec2(tile_coord.s, 1.0 - tile_coord.t));
    water = (texture(coastline, vec2(tile_coord.s, tile_coord.t)).r > 0.1);

    // Do not attempt any mixing
    flag = 0;
    mix_flag = 0;
  } else if (coast.g > 0.1) {
    texel = lookup_ground_texture_array(0, tile_coord, lc, dxdy);
    water = texture(landclass, vec2(tile_coord.s, tile_coord.t)).z > 0.9;
  } else {
    // Lookup the base texture texel for this fragment and any neighbors, with mixing
    texel = get_mixed_texel(0, ground_tex_coord, lc, num_unique_neighbors, lc_n, mfact, dxdy_gc);
    water = texture(landclass, vec2(tile_coord.s, tile_coord.t)).z > 0.9;
  }
  
  vec4 color = gl_Color * mat_ambient;
  color.a = 1.0;
  
  // Testing code: mix with green to show values of variables at each point
  //vec4 green = vec4(0.0, 0.5, 0.0, 0.0);
  //texel = mix(texel, green, (mfact[2]));

  float steep = 0.9;
  float steepToBeach = 0.93;
  float beachToWater = 0.95;
  float waterStart = 0.97;

  if ((coast.b > 0.05) || (water && steepness < (waterStart + 0.02))) { 
    float waterline_min_steepness = fg_materialParams3[lc].y;
    float waterline_max_steepness = fg_materialParams3[lc].z;
    vec4 steep_texel = lookup_ground_texture_array(2, ground_tex_coord, lc, dxdy_gc);  // Uses the same index as the gradient texture, which it is
    vec4 beach_texel = texture2D(sand, ground_tex_coord);  // Use the dot texture, which is overloaded to be the beach texture
    texel = mix(steep_texel, beach_texel, smoothstep(steep, steepToBeach, steepness));
    fragColor = mix(texel, generateWaterTexel(), smoothstep(beachToWater,waterStart,steepness));    
    fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, fragColor.rgb);    
  } else if (water) { 
    fragColor = generateWaterTexel();
    fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, fragColor.rgb);    
  } else {
    // Lookup material parameters for the landclass at this fragment.
    // Material parameters are from material definitions XML files (e.g. regional definitions in data/Materials/regions). They have the same names.
    // These parameters are contained in arrays of uniforms fg_materialParams1 and fg_materialParams2.
    // The uniforms are vec4s, and each parameter is mapped to a vec4 element (rgba channels).
    // In WS2 these parameters were available as uniforms of the same name.
    // Testing: The mapping is hardcoded at the moment.
    float transition_model   = fg_materialParams1[lc].r;
    float hires_overlay_bias = fg_materialParams1[lc].g;
    float grain_strength     = fg_materialParams1[lc].b;
    float intrinsic_wetness  = fg_materialParams1[lc].a;

    float dot_density     = fg_materialParams2[lc].r;
    float dot_size        = fg_materialParams2[lc].g;
    float dust_resistance = fg_materialParams2[lc].b;
    int rock_strata     = int(fg_materialParams2[lc].a);

    // dot noise
    float dotnoise_2m = DotNoise2D(rawPos.xy, 2.0 * dot_size,0.5, dot_density);
    float dotnoise_10m = DotNoise2D(rawPos.xy, 10.0 * dot_size, 0.5, dot_density);
    float dotnoise_15m = DotNoise2D(rawPos.xy, 15.0 * dot_size, 0.33, dot_density);


    // Testing code - set randomise_texture_lookups = 2 to only look up the base texture with no extra transitions.
    detail_texel = texel;
    mix_texel = texel;
    grain_texel = texel;
    dot_texel = texel;
    gradient_texel = texel;


  /*  
    // Texture lookup testing code:
    //   To test this block, uncomment it and turn off normal and random texture lookups
    //   by setting randomise_texture_lookups = 2 or more.
    
    int tex2;


    // Grain texture is material texture 14, which is mapped to the r channel of fg_textureLookup2
    tex2 = int(fg_textureLookup2[lc].r * 255.0 + 0.5);
    grain_texel = texture(textureArray, vec3(gl_TexCoord[0].st * 1.3, tex2));
    
    // Gradient texture is material texture 13, which is mapped to the a channel of fg_textureLookup1
    tex2 = int(fg_textureLookup1[lc].a * 255.0 + 0.5);
    gradient_texel = texture(textureArray, vec3(gl_TexCoord[0].st * 1.3, tex2));
    
    // Dot texture is material texture 15, which is mapped to the g channel of fg_textureLookup2
    tex2 = int(fg_textureLookup2[lc].g * 255.0 + 0.5);
    dot_texel = texture(textureArray, vec3(gl_TexCoord[0].st * 1.3, tex2));

    // Mix texture is material texture 12, which is mapped to the b channel of fg_textureLookup1
    tex2 = int(fg_textureLookup1[lc].b * 255.0 + 0.5);
    mix_texel = texture(textureArray, vec3(gl_TexCoord[0].st * 1.3, tex2));
    if (mix_texel.a < 0.1) { mix_flag = 0;} // Disable if no index found
    
    // Detail texture is material texture 11, which is mapped to the g channel of fg_textureLookup1
    tex2 = int(fg_textureLookup1[lc].g * 255.0 + 0.5);
    detail_texel = texture(textureArray, vec3(gl_TexCoord[0].st * 1.3, tex2));
    if (detail_texel.a < 0.1) { flag = 0;} // Disable if no index found
    
    //Examples of how lookup_ground_texture array is used with the above grain/gradient texture lookups:
    //grain_texel = lookup_ground_texture_array(1, st * 1.3, lc, dxdy * 1.3);
    //gradient_texel = lookup_ground_texture_array(2, st * 1.3, lc, dxdy * 1.3);
  */


    // Generate 6 random numbers 
    
    float pseed2 = 1.0;
    int tex_id_lc[6];
      float rn[6];
    if (randomise_texture_lookups == 1)
    {
    
      get6_rand_nums(float(lc)*33245.31, pseed2, 47.0, rn);
      for (int i=0;i<6;i++) tex_id_lc[i] = int(mod( (float(lc)+(rn[i]*47.0)+1.0) , 48.0));
    }
    
    //texel = mix(vec4(vec3(0.0),1.0), vec4(0.0,0.5,0.0,1.0), float(tex_id_lc[2])/48.0);
    
    // WS2:
    //grain_texel = texture2D(grain_texture, gl_TexCoord[0].st * 25.0);
    //gradient_texel = texture2D(gradient_texture, gl_TexCoord[0].st * 4.0);
    //stprime = gl_TexCoord[0].st * 80.0;
    //stprime = stprime + normalize(relPos).xy * 0.01 * (dotnoise_10m +  dotnoise_15m);
    //dot_texel = texture2D(dot_texture, vec2 (stprime.y, stprime.x) );
    

    if (randomise_texture_lookups == 0)
    {
      grain_texel = lookup_ground_texture_array(1, st * 25.0, lc, dxdy * 25.0);
      gradient_texel = lookup_ground_texture_array(2, st * 4.0, lc, dxdy * 4.0);
    }
    else if (randomise_texture_lookups == 1) 
    {
      grain_texel = lookup_ground_texture_array(0, st * 25.0, tex_id_lc[0], dxdy * 25.0);
      gradient_texel = lookup_ground_texture_array(0, st * 4.0, tex_id_lc[1], dxdy * 4.0);
    }
    
    stprime = st * 80.0;
    stprime = stprime + normalize(relPos).xy * 0.01 * (dotnoise_10m +  dotnoise_15m);
    vec4 dxdy_prime = vec4(dFdx(stprime), dFdy(stprime));
    
    if (randomise_texture_lookups == 0)
    {
      dot_texel = lookup_ground_texture_array(3, stprime.ts, lc, dxdy_prime.tsqp);
    }
    else if (randomise_texture_lookups == 1)
    {
      dot_texel = lookup_ground_texture_array(0, stprime.ts, tex_id_lc[2], dxdy_prime.tsqp);
    }
    
    // Testing: WS2 code after this, except for random texture lookups and partial derivatives
    
    float local_autumn_factor = texel.a;

    // we need to fade procedural structures when they get smaller than a single pixel, for this we need
    // to know under what angle we see the surface

    float view_angle = abs(dot(normalize(normal), normalize(ecViewdir)));

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
      noise_term = noise_term + 0.15 * (noise_2m -0.5) *  detail_fade(2.0, view_angle, dist);
      noise_term = noise_term + 0.08 * (noise_1m -0.5) * detail_fade(1.0, view_angle, dist);
      snow_texel.a = snow_texel.a * 0.2+0.8* smoothstep(0.2,0.8, 0.3 +noise_term + snow_thickness_factor +0.0001*(msl_altitude -snowlevel) );
    }
    
    if (mix_flag == 1) 
    {
      //WS2: mix_texel = texture2D(mix_texture, gl_TexCoord[0].st * 1.3);

      if (randomise_texture_lookups == 0)
      {
        mix_texel = lookup_ground_texture_array(4, st * 1.3, lc, dxdy * 1.3);
      }
      else if (randomise_texture_lookups == 1) 
      {
        mix_texel = lookup_ground_texture_array(0, st * 1.3, tex_id_lc[3], dxdy * 1.3);
      }
      if (mix_texel.a <0.1) {mix_flag = 0;}
    }
    
    // the hires overlay texture is loaded with parallax mapping
    
    if (flag == 1) 
    {
      stprime = vec2 (0.86*st.s + 0.5*st.t, 0.5*st.s - 0.86*st.t);
      distortion_factor = 0.97 + 0.06 * noise_500m;
      stprime = stprime * distortion_factor * 15.0;
      stprime = stprime + normalize(relPos).xy * 0.022 * (noise_10m + 0.5 * noise_5m +0.25 * noise_2m - 0.875 );
      
      //WS2: detail_texel = texture2D(detail_texture, stprime); // temp
      
      dxdy_prime = vec4(dFdx(stprime), dFdy(stprime));
      if (randomise_texture_lookups == 0)
      {
        detail_texel = lookup_ground_texture_array(5, stprime , lc, dxdy_prime);
      }
      else if (randomise_texture_lookups == 1) 
      {  
        detail_texel = lookup_ground_texture_array(0, stprime, tex_id_lc[4], dxdy_prime);
      }
      if (detail_texel.a <0.1) {flag = 0;}
    } // End if (flag == 1)
    
    
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
      nSum =  0.167 * (noise_4000m + 2.0 * noise_2000m + 2.0 * noise_1500m + noise_500m);
      nSum = mix(nSum, 0.5, max(0.0, 2.0 * (transition_model - 0.5)));
      nSum = nSum + 0.4 * (1.0 -smoothstep(0.9,0.95, abs(steepness)+ 0.05 * (noise_50m - 0.5))) * min(1.0, 2.0 * transition_model);
      mix_factor = smoothstep(0.5, 0.54, nSum);
      texel = mix(texel, mix_texel, mix_factor);
      local_autumn_factor = texel.a;
    }
      
    // then the detail texture overlay	  
    mix_factor = 0.0;
    //WS2: condition was broken up - does it matter for dynamic branching?
    if ((flag == 1) && (dist < 40000.0)) 
    {
      dist_fact =  0.1 * smoothstep(15000.0,40000.0, dist) - 0.03 * (1.0 - smoothstep(500.0,5000.0, dist));
      nSum = ((1.0 -noise_2000m) + noise_1500m + 2.0 * noise_250m  +noise_50m)/5.0;
      nSum = nSum - 0.08 * (1.0 -smoothstep(0.9,0.95, abs(steepness)));		
      mix_factor = smoothstep(0.47, 0.54, nSum +hires_overlay_bias- dist_fact);
      if (mix_factor > 0.8) {mix_factor = 0.8;}
      texel =  mix(texel, detail_texel,mix_factor);
    }
    
    // rock for very steep gradients  
    if (gradient_texel.a > 0.0)
    {
      texel = mix(texel, gradient_texel, 1.0 - smoothstep(0.75,0.8,abs(steepness)+ 0.00002* msl_altitude + 0.05 * (noise_50m - 0.5)));
      local_autumn_factor = texel.a;
    }


    // strata noise
    float stratnoise_50m;
    float stratnoise_10m;

    // Testing: if rock_strata parameter is not cast into int, need (rock_strata > 0.99)
    if (rock_strata==1)
    {
      stratnoise_50m = Strata3D(vec3 (rawPos.x, rawPos.y, msl_altitude), 50.0, 0.2);
      stratnoise_10m = Strata3D(vec3 (rawPos.x, rawPos.y, msl_altitude), 10.0, 0.2);
      stratnoise_50m = mix(stratnoise_50m, 1.0, smoothstep(0.8,0.9, steepness));
      stratnoise_10m = mix(stratnoise_10m, 1.0, smoothstep(0.8,0.9, steepness));
      texel *= (0.4 + 0.4 * stratnoise_50m + 0.2 * stratnoise_10m);
    }
    
    // the dot vegetation texture overlay
    texel.rgb = mix(texel.rgb, dot_texel.rgb, dot_texel.a * (dotnoise_10m + dotnoise_15m) * detail_fade(1.0 * (dot_size * (1.0 +0.1*dot_size)), view_angle,dist));
    texel.rgb = mix(texel.rgb, dot_texel.rgb, dot_texel.a * dotnoise_2m * detail_fade(0.1 * dot_size, view_angle,dist));
    
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
    texel = mix(texel, dust_color, clamp(0.5 * dust_cover_factor *dust_resistance + 3.0 * dust_cover_factor * dust_resistance *(((noise_1500m - 0.5) * 0.125)+0.125 ),0.0, 1.0) );
    
    // mix snow
    float snow_mix_factor = 0.0;

    if (msl_altitude + 500.0 > snowlevel)
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

    if ((dist < 5000.0) && (combined_wetness>0.0))
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
    vec3 n = normal;//vec3 (nvec.x, nvec.y, sqrt(1.0 -pow(nvec.x,2.0) - pow(nvec.y,2.0) ));
    n = normalize(n);

    NdotL = dot(n, lightDir);

    float noisegrad_10m = (noise_10m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),10.0))/0.05;
    float noisegrad_5m = (noise_5m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),5.0))/0.05;
    float noisegrad_2m = (noise_2m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),2.0))/0.05;
    float noisegrad_1m = (noise_1m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),1.0))/0.05;
    
    dotnoisegrad_10m = (dotnoise_10m - DotNoise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),10.0 * dot_size,0.5, dot_density))/0.05;
    
    
    NdotL = NdotL + (noisegrad_10m * detail_fade(10.0, view_angle,dist) + 0.5* noisegrad_5m * detail_fade(5.0, view_angle,dist)) * mix_factor/0.8;
    NdotL = NdotL + 0.15 * noisegrad_2m * mix_factor/0.8 * detail_fade(2.0,view_angle,dist);
    NdotL = NdotL + 0.1 * noisegrad_2m * detail_fade(2.0,view_angle,dist);
    NdotL = NdotL + 0.05 * noisegrad_1m * detail_fade(1.0, view_angle,dist);
    NdotL = NdotL + (1.0-snow_mix_factor) * 0.3* dot_texel.a * (0.5* dotnoisegrad_10m * detail_fade(1.0 * dot_size, view_angle, dist) +0.5 * dotnoisegrad_10m * noise_01m * detail_fade(0.1, view_angle, dist)) ;

    // Testing: Very temporary - reduce procedural normal map features with photoscenery active without breaking profiling as the controls are default (by request)
    if (fg_photoScenery) NdotL = mix(dot(n, lightDir), NdotL, 0.00001);
    
    if (NdotL > 0.0) 
    {
      float shadowmap = getShadowing();
      if (cloud_shadow_flag == 1) {NdotL = NdotL * shadow_func(relPos.x, relPos.y, 0.3 * noise_250m + 0.5 * noise_500m+0.2 * noise_1500m, dist);}
        vec4 diffuse_term = light_diffuse_comp * mat_diffuse;
        color += diffuse_term * NdotL * shadowmap;
        NdotHV = max(dot(n, halfVector), 0.0);
        if (mat_shininess > 0.0)
          specular.rgb = ((mat_specular.rgb * 0.1 + (water_factor * vec3 (1.0, 1.0, 1.0)))
          * light_specular.rgb
          * pow(NdotHV, mat_shininess + (20.0 * water_factor))
          * shadowmap);
    }
    color.a = 1.0;//diffuse_term.a; // as gl_Color.a and light_diffuse.comp.a were packed with other values
    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    color = clamp(color, 0.0, 1.0);


    if (use_searchlight == 1) {
      secondary_light += searchlight();
    }
    
    if (use_landing_light == 1) {
      secondary_light += landing_light(landing_light1_offset, landing_light3_offset);
    }

    if (use_alt_landing_light == 1) {
      secondary_light += landing_light(landing_light2_offset, landing_light3_offset);
    }

    color.rgb += secondary_light * light_distance_fading(dist);

    fragColor = color * texel + specular;
    fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, texel.rgb);
  }
    
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
