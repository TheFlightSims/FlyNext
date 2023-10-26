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

// Coastline texture - generated from VPBTechnique
uniform sampler2D coastline;

// Sand texture
uniform sampler2D sand;

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
  vec2 tile_coord = gl_TexCoord[0].st;

  // Test phase: Constants and toggles for transitions between landlcasses are defined at
  // the top of this file.

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
		texel = texture(landclass, vec2(gl_TexCoord[0].s, 1.0 - gl_TexCoord[0].t));
    water = (texture(coastline, vec2(tile_coord.s, tile_coord.t)).r > 0.1);
  } else if (coast.g > 0.1) {
    texel = lookup_ground_texture_array(0, tile_coord, lc, dxdy);
    water = texture(landclass, vec2(tile_coord.s, tile_coord.t)).z > 0.9;
  } else {
    // Lookup the base texture texel for this fragment and any neighbors, with mixing
    texel = get_mixed_texel(0, ground_tex_coord, lc, num_unique_neighbors, lc_n, mfact, dxdy_gc);
    water = texture(landclass, vec2(tile_coord.s, tile_coord.t)).z > 0.9;
  }

  float steep = 0.9;
  float steepToBeach = 0.93;
  float beachToWater = 0.95;
  float waterStart = 0.97;

  if ((water_shader == 1) && ((coast.b > 0.05) || (water && steepness < (waterStart + 0.02)))) { 

    // This is a water fragment, so calculate the fragment color procedurally, but mix in the steep and beach
    vec4 steep_texel = lookup_ground_texture_array(2, ground_tex_coord, lc, dxdy_gc);  // Uses the same index as the gradient texture, which it is
    vec4 beach_texel = texture2D(sand, ground_tex_coord);  // Use the dot texture, which is overloaded to be the beach texture
    texel = mix(steep_texel, beach_texel, smoothstep(steep, steepToBeach, steepness));
    fragColor = mix(texel, generateWaterTexel(), smoothstep(beachToWater,waterStart,steepness));    

    fragColor.rgb += getClusteredLightsContribution(eyePos.xyz, n, fragColor.rgb);
  } else if ((water_shader == 1) && water) { 
    fragColor = generateWaterTexel();
    fragColor.rgb += getClusteredLightsContribution(eyePos.xyz, n, fragColor.rgb);    
  } else {
    // Photoscenery or land fragment, so determine the shading and color normally
    vec4 color = gl_Color * mat_ambient;
    color.a = 1.0;

    // Testing code: mix with green to show values of variables at each point
    //vec4 green = vec4(0.0, 0.5, 0.0, 0.0);
    //texel = mix(texel, green, (mfact[2]));

    //mix_texel = texel;
    //detail_texel = texel;
    vec4 t = texel;

    int flag = 1;
    int mix_flag = 1;

    float local_autumn_factor = texel.a;

    if (fg_photoScenery) {
      flag = 0;
      mix_flag = 0;
    }

    float distortion_factor = 1.0;
    vec2 stprime;

    float noise_term;
    float snow_alpha;

    //float view_angle = abs(dot(normal, normalize(ecViewdir)));

    if ((quality_level > 3)&&(msl_altitude +500.0 > snowlevel)) {
      float sfactor;
      snow_texel = vec4 (0.95, 0.95, 0.95, 1.0) * (0.9 + 0.1* noise_500m + 0.1* (1.0 - noise_10m) );
      snow_texel.r = snow_texel.r * (0.9 + 0.05 * (noise_10m + noise_5m));
      snow_texel.g = snow_texel.g * (0.9 + 0.05 * (noise_10m + noise_5m));
      snow_texel.a = 1.0;
      noise_term = 0.1 * (noise_500m-0.5);
      sfactor = sqrt(2.0 * (1.0-steepness)/0.03) + abs(ct)/0.15;
      noise_term = noise_term + 0.2 * (noise_50m -0.5) * (1.0 - smoothstep(18000.0*sfactor, 40000.0*sfactor, dist)  ) ;
      noise_term = noise_term + 0.3 * (noise_10m -0.5) * (1.0 - smoothstep(4000.0 * sfactor, 8000.0 * sfactor, dist)  ) ;

      if (dist < 3000.0*sfactor) { 
        noise_term = noise_term + 0.3 * (noise_5m -0.5) * (1.0 - smoothstep(1000.0 * sfactor, 3000.0 *sfactor, dist)  );
      }
      
      snow_texel.a = snow_texel.a * 0.2+0.8* smoothstep(0.2,0.8, 0.3 +noise_term + snow_thickness_factor +0.0001*(msl_altitude -snowlevel) );
        
    }

    if ((tquality_level > 2) && (mix_flag == 1))
    {
      // Mix texture is material texture 15, which is mapped to the b channel of fg_textureLookup1
      //int tex2 = int(fg_textureLookup1[lc].b * 255.0 + 0.5);
      //mix_texel = texture(textureArray, vec3(gl_TexCoord[0].st * 1.3, tex2));
      if (mix_texel.a < 0.1) { mix_flag = 0;}
      //WS2: mix_texel = texture2D(mix_texture, gl_TexCoord[0].st * 1.3); // temp

      mix_texel = lookup_ground_texture_array(4, st * 1.3, lc, dxdy * 1.3);
    if (mix_texel.a <0.1) {mix_flag = 0;}
    }

    if (tquality_level > 3 && (flag == 1))  
    {
      stprime = vec2 (0.86*gl_TexCoord[0].s + 0.5*gl_TexCoord[0].t, 0.5*gl_TexCoord[0].s - 0.86*gl_TexCoord[0].t);
      //distortion_factor = 0.9375 + (1.0 * nvL[2]);
      distortion_factor = 0.97 + 0.06 * noise_500m;
      stprime = stprime * distortion_factor * 15.0;
      if (quality_level > 4)
      {
        stprime = stprime + normalize(relPos).xy * 0.02 * (noise_10m + 0.5 * noise_5m - 0.75);
      }

      // Detail texture is material texture 11, which is mapped to the g channel of fg_textureLookup1
      //int tex3 = int(fg_textureLookup1[lc].g * 255.0 + 0.5);
      //detail_texel = texture(textureArray, vec3(stprime, tex3));
      if (detail_texel.a < 0.1) { flag = 0;}
      //WS2: detail_texel = texture2D(detail_texture, stprime); // temp

      vec4 dxdy_prime = vec4(dFdx(stprime), dFdy(stprime));
      detail_texel = lookup_ground_texture_array(5, stprime, lc, dxdy_prime);
    }

  // texture preparation according to detail level

  // mix in hires texture patches

  float dist_fact; 
  float nSum;
  float mix_factor;
  float transition_model   = fg_materialParams1[lc].r;
  float hires_overlay_bias = fg_materialParams1[lc].g;

  if (tquality_level > 2) {
    // first the second texture overlay
    // transition model 0: random patch overlay without any gradient information
    // transition model 1: only gradient-driven transitions, no randomness
    
    
    if (mix_flag == 1)	{
      // Random patch overlay weighting with noise
      nSum =  0.18 * (2.0 * noise_2000m + 2.0 * noise_1500m + noise_500m);

      // Increase the weighting for the mix_texel if more gradient-driven.
      nSum = mix(nSum, 0.5, max(0.0, 2.0 * (transition_model - 0.5)));

      // Add the gradient element
      nSum = nSum + 0.4 * (1.0 -smoothstep(0.9,0.95, abs(steepness)+ 0.05 * (noise_50m - 0.5))) * min(1.0, 2.0 * transition_model);
      mix_factor = smoothstep(0.5, 0.54, nSum);
      texel = mix(texel, mix_texel, mix_factor);
      local_autumn_factor = texel.a;
    }
    
  }

  if (tquality_level > 3) {
    // then the detail texture overlay	
    if (dist < 40000.0)
    {
      if (flag == 1) {
        //noise_50m = Noise2D(rawPos.xy, 50.0);
        //noise_250m  = Noise2D(rawPos.xy, 250.0); 
        dist_fact =  0.1 * smoothstep(15000.0,40000.0, dist) - 0.03 * (1.0 - smoothstep(500.0,5000.0, dist));
        nSum = ((1.0 -noise_2000m) + noise_1500m + 2.0 * noise_250m  +noise_50m)/5.0;
        nSum = nSum - 0.08 * (1.0 -smoothstep(0.9,0.95, abs(steepness)));		
        mix_factor = smoothstep(0.47, 0.54, nSum +hires_overlay_bias - dist_fact);
        if (mix_factor > 0.8) {mix_factor = 0.8;}
        texel =  mix(texel, detail_texel,mix_factor);
        local_autumn_factor = texel.a;				
      }
    }
  }



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
    if (msl_altitude +500.0 > snowlevel)
      {
        snow_alpha = smoothstep(0.75, 0.85, abs(steepness));
      //texel = mix(texel, snow_texel, texel_snow_fraction);
      texel = mix(texel, snow_texel, snow_texel.a* smoothstep(snowlevel, snowlevel+200.0,  snow_alpha * (msl_altitude)+ (noise_2000m + 0.1 * noise_10m -0.55) *400.0));
      }
    }
  else if (msl_altitude +500.0 > snowlevel)
          {
              float snow_alpha = 0.5+0.5* smoothstep(0.2,0.8, 0.3 + snow_thickness_factor +0.0001*(msl_altitude -snowlevel) );
  //          texel = vec4(dot(vec3(0.2989, 0.5870, 0.1140), texel.rgb));
              texel = mix(texel, vec4(1.0), snow_alpha* smoothstep(snowlevel, snowlevel+200.0,  (msl_altitude)));
          }



  // get distribution of water when terrain is wet

  float water_threshold1;
  float water_threshold2;
  float water_factor =0.0;


  if ((dist < 5000.0)&& (quality_level > 3) && (wetness>0.0))
      {
      water_threshold1 = 1.0-0.5* wetness;
      water_threshold2 = 1.0 - 0.3 * wetness;
      water_factor = smoothstep(water_threshold1, water_threshold2 ,   (0.3 * (2.0 * (1.0-noise_10m) + (1.0 -noise_5m)) *   (1.0 - smoothstep(2000.0, 5000.0, dist))) - 5.0 * (1.0 -steepness));
    }

  // darken wet terrain

      texel.rgb = texel.rgb * (1.0 - 0.6 * wetness);


  // light computations


      vec4 light_specular = gl_LightSource[0].specular;

      // If gl_Color.a == 0, this is a back-facing polygon and the
      // normal should be reversed.
      //n = (2.0 * gl_Color.a - 1.0) * normal;
      n = normal;//vec3 (nvec.x, nvec.y, sqrt(1.0 -pow(nvec.x,2.0) - pow(nvec.y,2.0) ));
      n = normalize(n);

    NdotL = dot(n, lightDir);
      if ((tquality_level > 3) && (mix_flag ==1)&& (dist < 2000.0) && (quality_level > 4)) 
    {
    noisegrad_10m = (noise_10m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),10.0))/0.05;
    noisegrad_5m = (noise_5m - Noise2D(rawPos.xy+ 0.05 * normalize(lightDir.xy),5.0))/0.05;
    NdotL = NdotL + 1.0 * (noisegrad_10m + 0.5* noisegrad_5m) * mix_factor/0.8 *  (1.0 - smoothstep(1000.0, 2000.0, dist));
    }


    if (NdotL > 0.0) {
        float shadowmap = getShadowing();
        vec4 diffuse_term = light_diffuse_comp * mat_diffuse;
        color += diffuse_term * NdotL * shadowmap;
        NdotHV = max(dot(n, halfVector), 0.0);
        if (mat_shininess > 0.0)
            specular.rgb = (mat_specular.rgb
                            * light_specular.rgb
                            * pow(NdotHV, mat_shininess)
                            * shadowmap);
    }
    color.a = 1.0;//diffuse_term.a;
    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    color = clamp(color, 0.0, 1.0);

    fragColor = color * texel + specular;
    fragColor.rgb += getClusteredLightsContribution(eyePos.xyz, n, texel.rgb);
  }

  float lightArg = (terminator-yprime_alt)/100000.0;
  vec3 hazeColor = get_hazeColor(lightArg);
  gl_FragColor = applyHaze(fragColor, hazeColor, vec3(0.0), ct, hazeLayerAltitude, visibility, avisibility, dist, lightArg, mie_angle);


// Testing phase controls:
if (remove_haze_and_lighting == 1)
{
        gl_FragColor = texel;
}


        
}
