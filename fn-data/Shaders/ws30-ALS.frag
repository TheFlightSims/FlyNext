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














// Ambient term comes in gl_Color.rgb.
varying vec4 light_diffuse_comp;
varying vec3 normal;
varying vec3 relPos;
varying vec2 ground_tex_coord;

uniform sampler2D landclass;
uniform sampler2DArray textureArray;

varying float yprime_alt;
varying float mie_angle;
varying vec4 ecPosition;

uniform float visibility;
uniform float avisibility;
uniform float scattering;
uniform float terminator;
uniform float terrain_alt; 
uniform float hazeLayerAltitude;
uniform float overcast;
uniform float eye_alt;
uniform float cloud_self_shading;

// Passed from VPBTechnique, not the Effect
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
uniform vec4 fg_materialParams3[128];

#define MAX_TEXTURES 8
uniform mat4 fg_zUpTransform;
uniform vec3 fg_modelOffset;

const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;

float alt;
float eShade;

float fog_func (in float targ, in float alt);
vec3 get_hazeColor(in float light_arg);
vec3 filter_combined (in vec3 color) ;

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
vec4 generateWaterTexel();

// Not used
float luminance(vec3 color)
{
    return dot(vec3(0.212671, 0.715160, 0.072169), color);
}


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
  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
  // this is taken from default.frag
  float NdotL, NdotHV, fogFactor;
  vec3 n = normalize(normal);
  vec3 lightDir = gl_LightSource[0].position.xyz;
  vec3 halfVector = gl_LightSource[0].halfVector.xyz;
  vec4 texel;
  vec4 fragColor;
  vec4 specular = vec4(0.0);
  float intensity;

  // Material/texel properties
  float mat_shininess;
  vec2 st;
  vec4 mat_ambient, mat_diffuse, mat_specular, dxdy;

  
  // Tile texture coordinates range [0..1] over the tile 'rectangle'
  vec2 tile_coord = gl_TexCoord[0].st;

  // Look up the landclass id [0 .. 255] for this particular fragment
  // and any neighbouring landclass that is close.
  // Each tile has 1 texture containing landclass ids stetched over it.
  // Landclass for current fragment, and up-to 4 neighboring landclasses - 2 used currently
  int lc;
  ivec4 lc_n;

  int num_unique_neighbors = 0;

  // Mix factor of base textures for 2 neighbour landclass(es)
  vec4 mfact;

  // Partial derivatives of s and t for this fragment, 
  // with respect to window (screen space) x and y axes.
  // Used to pick mipmap LoD levels, and turn off unneeded procedural detail
  // dFdx and dFdy are packed in a vec4 so multiplying 
  // to scale takes 1 instruction slot.
  vec4 dxdy_gc = vec4(dFdx(tile_coord) , dFdy(tile_coord));

  get_landclass_id(tile_coord, dxdy_gc, lc, lc_n, num_unique_neighbors, mfact);
  get_material(lc, ground_tex_coord, dxdy_gc, mat_shininess, mat_ambient, mat_diffuse, mat_specular, dxdy, st);

  if (fg_photoScenery) {
		texel = texture(landclass, vec2(gl_TexCoord[0].s, 1.0 - gl_TexCoord[0].t));
  } else {
    // Lookup the base texture texel for this fragment.  No mixing at this quality level.
    texel = lookup_ground_texture_array(0, st, lc, dxdy);
  }

  if ((water_shader == 1) && (fg_photoScenery == false) && fg_materialParams3[lc].x > 0.5) { 
    // This is a water fragment, so calculate the fragment color procedurally
    fragColor = generateWaterTexel();
    fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, fragColor.rgb);
    
  } else {
    // Photoscenery or land fragment, so determine the shading and color normally
    vec4 color = mat_ambient * (gl_LightModel.ambient + gl_LightSource[0].ambient);

    // Testing code:
    // Use rlc even when looking up textures to recreate the extra performance hit
    // so any performance difference between the two is due to the texture lookup
    // color = color+0.00001*float(get_random_landclass(tile_coord.st, tile_size));

    float effective_scattering = min(scattering, cloud_self_shading);

    vec4 light_specular = gl_LightSource[0].specular;

    // If gl_Color.a == 0, this is a back-facing polygon and the
    // normal should be reversed.
    //n = (2.0 * gl_Color.a - 1.0) * normal;
    


    NdotL = dot(n, lightDir);
    vec4 diffuse_term = light_diffuse_comp * mat_diffuse;
    if (NdotL > 0.0) {
        float shadowmap = getShadowing();
        vec4 diffuse_term = light_diffuse_comp * mat_diffuse;
        color += diffuse_term * NdotL * shadowmap;
        NdotHV = max(dot(n, halfVector), 0.0);
        if (mat_shininess > 0.0)
            specular.rgb = (mat_specular.rgb
                            * light_specular.rgb
                            * pow(NdotHV, gl_FrontMaterial.shininess)
                            * shadowmap);
    }
    color.a = diffuse_term.a;
    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    color = clamp(color, 0.0, 1.0);


    // Testing code: mix with green to show values of variables at each point
    //vec4 green = vec4(0.0, 0.5, 0.0, 0.0);
    //texel = mix(texel, green, (mfact[2]));


    fragColor = color * texel + specular;
    fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, texel.rgb);
  }

  // angle with horizon
  float dist = length(relPos);
  float ct = dot(vec3(0.0, 0.0, 1.0), relPos)/dist;

  float lightArg = (terminator-yprime_alt)/100000.0;
  vec3 hazeColor = get_hazeColor(lightArg);
  gl_FragColor = applyHaze(fragColor, hazeColor, vec3(0.0), ct, hazeLayerAltitude, visibility, avisibility, dist, lightArg, mie_angle);

  // Testing phase controls:
  if (remove_haze_and_lighting == 1)
  {
    gl_FragColor = texel;
  }
}
