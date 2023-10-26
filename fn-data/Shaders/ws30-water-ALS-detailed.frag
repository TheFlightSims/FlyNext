// WS30 FRAGMENT SHADER

// -*-C++-*-
#version 130
#extension GL_EXT_texture_array : enable
// written by Thorsten Renk, Oct 2011, based on default.frag


//////////////////////////////////////////////////////////////////
// TEST PHASE TOGGLES AND CONTROLS
//

// Development tools:
//   Reduce haze to almost zero, while preserving lighting. Useful for observing distant tiles.
//     Keeps the calculation overhead. This can be used for profiling.
//     Possible values: 0:Normal, 1:Reduced haze.
    const int reduce_haze_without_removing_calculation_overhead = 0;

//   Remove haze and lighting and shows just the texture. 
//     Useful for checking texture rendering and scenery.
//     The compiler will likely optimise out the haze and lighting calculations.
//     Possible values: 0:Normal, 1:Just the texture.
  const int remove_haze_and_lighting = 0;

//   Use built-in water shader.  Use for testing impact of ws30-water.frag
  const int water_shader = 1;

//
// End of test phase controls
//////////////////////////////////////////////////////////////////













// written by Thorsten Renk, Oct 2011, based on default.frag
// Ambient term comes in gl_Color.rgb.
varying vec4 light_diffuse_comp;
varying vec3 normal;
varying vec3 relPos;
varying vec2 ground_tex_coord;
varying vec2 rawPos;
varying vec3 worldPos;
// Testing code:
//vec3 worldPos = vec3(5000.0, 6000.0, 7000.0) + vec3(vec2(rawPos), 600.0); // vec3(100.0, 10.0, 3.0);
varying vec4 eyePos;


uniform sampler2D landclass;
uniform sampler2DArray textureArray;
uniform sampler2D perlin;

//varying float yprime_alt;
//varying float mie_angle;
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
uniform float wetness;
uniform float fogstructure;
uniform float snow_thickness_factor;
uniform float cloud_self_shading;
uniform float season;

uniform int quality_level;
uniform int tquality_level;

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
uniform vec4 fg_materialParams1[128];
uniform vec4 fg_materialParams3[128];
uniform mat4 fg_zUpTransform;
uniform vec3 fg_modelOffset;

const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;

//Testing phase: Why are these in global scope in WS2 shaders?
float alt;
float eShade;
float yprime_alt;
float mie_angle;

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




//////////////////////////
// Test-phase code:


// These should be sent as uniforms

// Tile dimensions in meters
// vec2 tile_size = vec2(tile_width , tile_height);
// Testing: texture coords are sent flipped right now:

// Note tile_size is defined in the shader include: ws30-landclass-search-functions.frag.
// vec2 tile_size = vec2(tile_height , tile_width);

// From noise.frag
float rand2D(in vec2 co);

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
// Create a mix factor weighting the influences of nearby landclasses
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


yprime_alt = light_diffuse_comp.a;
//diffuse_term.a = 1.0;
mie_angle = gl_Color.a;
float effective_scattering = min(scattering, cloud_self_shading);

// distance to fragment

float dist = length(relPos);
// angle of view vector with horizon
float ct = dot(vec3(0.0, 0.0, 1.0), relPos)/dist;

// Altitude of fragment above sea level
float msl_altitude = (relPos.z + eye_alt);


  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
  // this is taken from default.frag
  vec3 n;
  float NdotL, NdotHV, fogFactor;
  vec3 lightDir = gl_LightSource[0].position.xyz;
  vec3 halfVector = gl_LightSource[0].halfVector.xyz;
  //vec3 halfVector = normalize(normalize(lightDir) + normalize(ecViewdir));
  vec4 texel;
  vec4 snow_texel;
  vec4 detail_texel;
  vec4 mix_texel;
  vec4 fragColor;
  vec4 specular = vec4(0.0);
  float intensity;

  // Material/texel properties
  float mat_shininess;
  vec2 st;
  vec4 mat_ambient, mat_diffuse, mat_specular, dxdy;

// get noise at different wavelengths

// used:	5m, 5m gradient, 10m, 10m gradient: heightmap of the closeup terrain, 10m also snow
//		50m: detail texel
//		250m: detail texel
//		500m: distortion and overlay
// 		1500m: overlay, detail, dust, fog
//		2000m: overlay, detail, snow, fog

float noise_10m; 
float noise_5m;  
noise_10m = Noise2D(rawPos.xy, 10.0);
noise_5m = Noise2D(rawPos.xy ,5.0);

float noisegrad_10m;
float noisegrad_5m;

float noise_50m = Noise2D(rawPos.xy, 50.0);; 


float noise_250m = Noise3D(worldPos.xyz,250.0);
float noise_500m = Noise3D(worldPos.xyz, 500.0);
float noise_1500m = Noise3D(worldPos.xyz, 1500.0);
float noise_2000m = Noise3D(worldPos.xyz, 2000.0);



//


// get the texels

  // Oct 27 2021:
  // Geometry is in the form of roughly rectangular 'tiles'
  // with a mesh forming a grid with regular spacing. 
  // Each vertex in the mesh is given an elevation

  // Tile dimensions in m
  // Testing: created from two float uniforms in global scope. Should be sent as a vec2
  // vec2 tile_size

  // Tile texture coordinates range [0..1] over the tile 'rectangle'

  // This is a water fragment, so calculate the fragment color procedurally
  fragColor = generateWaterTexel();
  fragColor.rgb += getClusteredLightsContribution(eyePos.xyz, n, fragColor.rgb);

  float lightArg = (terminator-yprime_alt)/100000.0;
  vec3 hazeColor = get_hazeColor(lightArg);
  gl_FragColor = applyHaze(fragColor, hazeColor, vec3(0.0), ct, hazeLayerAltitude, visibility, avisibility, dist, lightArg, mie_angle);


// Testing phase controls:
if (remove_haze_and_lighting == 1)
{
        gl_FragColor = texel;
}


        
}
