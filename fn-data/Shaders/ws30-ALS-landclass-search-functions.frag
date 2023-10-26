// WS30 FRAGMENT SHADER
// -*-C++-*-
#version 130
// WS30 terrain - Landclass search functions used by fragment shaders
// Split off from from ws30-ALS-ultra.frag


//////////////////////////////////////////////////////////////////
// TEST PHASE TOGGLES AND CONTROLS FOR PROFILING ON DIFFERENT GPUS 
//

// Instructions for power users: 
//   Change the numbers for values and controls, save the file, and 
//     reload shaders to compare the difference.
//     In-sim menu > debug > configure development extensions > reload shaders.
//   It's safe to tinker with things in this section. 
//   At worst the terrain will look odd. If there's an error or a stray 
//     character, the shader will just not compile - the terrain changes 
//     appearance to black.
//   Simply try again and hit reload shaders button. You can also save a backup 
//     of this file.
//   "//" means everything on that line is a comment. 
//   Lines assigning numbers to variables end in a ";"

// Testing performance:
//   Use the UFO or video assistant. Turn all scenery layers off (vegetation, 
//     buildings, random scenery objects etc.).
//   The terrain quality shader level determines the shaders used. Set it to ultra.
//   The view should be 100% terrain. No sky. Try to minimise parts of terrain 
//     or scenery rendered by other shaders, as the results will be inaccurate.
//     Avoid clouds in view. Minimise water in view.
//     WS3 OSM roads must be turned off to get accurate results:
//       in-sim menu > view > adjust LoD ranges > set all "Minimum Line Feature 
//         Width" sliders to 50m (move sliders slightly if initial value = 9999).
//   Going closer or reducing FoV works, but these also can change performance.
//   Looking towards the horizon at high altitude may cause perfomance to be CPU
//     bound due to OSG scene traveral.
//   Remember to mention factors that change performance: 
//     resolution, the rough area (regional definitions at work), altitude, 
//     WS3 scenery package, AA settings, driver control panel settings and overrides
//     - (you can set these to application controlled)


// Comparing performance:
//   GPU bound: To use FPS to compare performance you must be bottlenecked by 
//      the GPU (GPU bound).
//     When GPU bound (fragment bound), changing the window size slightly should
//       result in a change in FPS.
//     You can also tell if you are GPU bound, as GPU utilisation will be 100%.
//     Change in performance = FPS2/FPS1. 
//       e.g. increase of 15 FPS to 30 FPS = 30/15 = 2x or 200% increase. 
//   Not GPU bound: If your bottleneck is not the GPU, you need to measure 
//     GPU utilisation.
//     GPU utilisation is the GPU load - it will be less than 100%.
//     Change in performance = utilisation1/utilisation2. 
//       e.g. Drop from 40% to 20% = 40/20 = 2x increase in performance or 
//       doubling of FPS. e.g 40% to 30% = 40/30 = 1.33x increase.
//   CPU bound FPS limit: You can usually find your CPU bound FPS limit by 
//     reducing window size until FPS stops increasing. This depends on what's 
//     in view.
//   To Compare performace with WS2: untick the WS3 tick box in render settings, 
//     and make sure both WS2 and WS3 are GPU bound, and not CPU bound.     


//
// Note: 
//   Ensure in-sim menu > view > rendering options > throttle FPS is off. 
//   Ensure vsync is off.
//   Ensure WS3 OSM roads are off (see testing performance section).
//   Make sure your power plan is set to maximum or balanced in Windows, or 
//     results could be inaccurate - laptops may be on a power saving plan 
//     by default.

// To test: All transitions are off by default. Set both remove squareness and 
//   enable large scale transitions to 1 to get a quality with most features 
//   turned on.

// Maximum number of neighbor landclass textures to lookup if neighbors are found. 
//   The more landclass textures are looked up the more pressure on VRAM. 
//   Performance hit varies by altitude and how small the landclass blobs are.
//   More ground texture lookups may run slower on older generation GPUs - test and see.
//   Possible values: 0,1,2. Default: 2. To see texture mixing transitions you need 1 or 2.
  const int max_neighbor_landclass_texture_lookups = 2;



// Small scale transition controls

//   Remove squareness due to landclass texture by growing higher priority neighbors.
//     This adds 2 extra lookups of the landclass texture, and one math/noise lookup.
//     Large scale transition searches do not use this - as it triples the number of 
//        landclass texture acceses, as well as adding 1 noise lookup per search point.
//     This should be expected to be used on old GPUs, except when running at the absolute 
//       lowest graphics quality. It's faster than large scale transition searches.
//     Possible values: 1:enabled, 0:disabled. Default:0
    const int remove_squareness_from_landclass_texture = 0;

//   Transition at landclass texel scale
//     Mix in neighbor textures so landclass boundaries are not hard at the 
//       landclass texel scale.
//     Note: Disable enable large scale transition search, if using this. 
//       This needs extra ground texture lookups. It looks fine with 1 extra lookup.
//       This can be combined with removing squareness by growing borders.
//     Possible values: 1:enabled, 0:disabled
    const int use_landclass_texel_scale_transition_only = 0;



// Large scale transition controls

//   Enable large scale transitions: 1=on, 0=off
//     Disable use landclass texel scale transition, if using this.
  const int enable_large_scale_transition_search = 1;


//   The search pattern is center + n points in four directions forming a cross.
//     e.g. 1 search point = 1 + 4 * 1 = 5 points total. 
//     4 search points: 17 total. 10 search points = 41
//   The transition distance is the distance from the center to the furtherst 
//      point in any direction.


//   Landclass transition search distance in meters
//     Note: transitions occur on both sides of the landclass borders. 
//       The width of the transition is equal to 2x this value.
//     Default: 100m
  const float transition_search_distance_in_m = 25.0;

//   Number of points to search in any direction, in addition to this fragment
//     Default:4 points. Fewer points results in a less smooth transition (more banding)
//       Choose the lowest number of points to get a desired transition quality.
  const int num_search_points_in_a_direction = 4;




// Landclass transition weightings options
//   More options mean slightly more GPU math load
//
//   Use 2nd closest neighbour for transition weighting. 
//   Note this won't lookup a ground texture by itself, just sort through results
//     Possible values: 1:enable, 0=disable. Default: 1  
  const int enable_2nd_closest_neighbor_for_large_scale_transition_weights = 0;

//   Enable dithering to smooth transitions by reducing visible banding
//   Possible values: 1=enable, 0=disable. Default = 1
  const int enable_dithering_for_large_scale_transitions = 1;

//   Scale of dithering as a faction of the size of the bands - distance between
//     search points (=transition distance / number of steps)
//     0.2 seems to work ok - not real need to tinker with this.
//   Different values won't change performance.
  const float dithering_noise_wavelength_as_fraction_of_step_size = 0.2;

//   Grow the borders of landclasses a bit when large scale transitions are used
//     Higher priority landclasses grow onto lower priority ones. 
//     Landclass numbers are used as a placeholder for landclass priority.
//     This works by changing the weighting in the transition region using a 
//       noise lookup
//     Possibe values: 0=off, 1=on. Default:0
  const int grow_landclass_borders_with_large_scale_transition = 1; 

//  Use the edge-hardness parameter from materials.xml to determine
//  weighting of the landclass in transitions
  const int use_edge_hardness_with_large_scale_transition = 1;


//////////////////////////////////////////////////////////////////
// Advanced controls - these are for testing scenery generation and rendering


// Landclass source:
//   Possible values: Default=1;
//     0=Normal landclass texture, 1 = Random landclass squares along s and t axes.    
//   Choose 1 to test impact of searching a texture. You should normally leave 
//     it at default.
  const int landclass_source = 0;

//   Random landclass square size in meters. Remember to adjust transition search distance.
//     Default: 200m 
    const float random_landclass_square_size_in_m = 3.3*transition_search_distance_in_m;

// Detiling noise source
//   Possible values: 0 = texture source, 1 = math source
//   The texture source still shows some tiling. The math source detiles better, but might
//     be slightly slower.
  const int detiling_noise_type = 1;

// Development tools - 2 controls, now located at the top of WS30-ALS-ultra.frag:
//   1. Reduce haze to almost zero, while preserving lighting. Useful for observing distant tiles.
//     Keeps the calculation overhead. This can be used for profiling.
//   2. Remove haze and lighting and shows just the texture. 
//     Useful for checking texture rendering and scenery.
//     The compiler will likely optimise out the haze and lighting calculations.
//

//   Debugging: ground texture array lookup function
//   Possible values:
//     0: Normal: TextureGrad() with partial derivatives. GLSL 1.30.
//     1: textureLod() using partial derivatives to manually calculate LoD. GLSL 1.20
//     2: texture() without partial derivatives. GLSL 1.20
  const int tex_lookup_type = 0;

//     
// End of test phase controls
//////////////////////////////////////////////////////////////////



























//////////////////////////
// Test-phase code:

// Uniforms used by landclass search functions.
// If any uniforms change name or form, remember to update here and in fragment shaders.


uniform sampler2D landclass;
uniform sampler2DArray textureArray;
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

// These should be sent as uniforms

// Tile dimensions in meters
// vec2 tile_size = vec2(tile_width , tile_height);
// Testing: texture coords are sent flipped right now:
vec2 tile_size = vec2(fg_tileHeight , fg_tileWidth);

// These are defined in noise.frag
float rand2D(in vec2 co);
float Noise2D(in vec2 coord, in float wavelength);

// Generates a full precision 32 bit random number from 2 seeds
//     as well as 6 random integers between 0 and factor that are rescaled 0.0-1.0
//     by re-using the significant figures from the full precision number.
//     This avoids having to generate 6 random numbers when 
//     limited variation is needed: say 6 numbers with 100 levels (i.e between 0 and 100).
// Seed 2 is incremented so the function can be called again to generate
//      a different set of numbers
float get6_rand_nums(in float PRNGseed1, inout float PRNGseed2, float factor, out float [6] random_integers)
{
      
    float r = fract(sin(dot(vec2(PRNGseed1,PRNGseed2),vec2(12.9898,78.233))) * 43758.5453);

    // random number left over after extracting some decimal places
    float rlo = r;
    // To look at: can this be made simd friendly?
    for (int i=0;i<6;i++)
    {
        rlo = (rlo*factor);
        random_integers[i] = floor(rlo)/factor;
        rlo = fract(rlo);
    }
      
   PRNGseed2+=1.0;
   return r;
}


// Create random landclasses without a texture lookup to stress test.
// Each square of square_size in m is assigned a random landclass value.
int get_random_landclass(in vec2 co, in vec2 tile_size)
{
  float r = rand2D(  floor(vec2(co.s*tile_size.x, co.t*tile_size.y)/random_landclass_square_size_in_m)  );
  int lc = int(r*48.0); // only 48 landclasses mapped so far
  return lc;
}


/*
// Look up stretching scale of ground textures for the base texture.
//   Note terrain default effect only has controls for the texture stretching dimensions for the base texture.
//   Non-base textures use hardcoded stretching of the ground texture coords, which are in units of meters.
vec2 get_ground_texture_scale(in int lc)
{
  // Look up stretching dimensions of ground textures in m - scaled to 
  // fit in [0..1], so rescale 
  vec2 g_texture_stretch_dim = fg_dimensionsArray[lc].st;
  return (tile_size.xy / g_texture_stretch_dim.xy);
}
*/


// Look up texture coordinates and stretching scale of ground textures for the base texture.
//   Note terrain default effect only has controls for the texture stretching dimensions for the base texture.
//   Non-base textures use hardcoded stretching of the ground texture coords, which are in units of meters.
void get_ground_texture_data(in int lc, in vec2 tile_coord, 
  out vec2 st, out vec2 g_texture_scale, inout vec4 dFdx_and_dFdy)
{
  // Look up stretching dimensions of ground textures in m - scaled to 
  // fit in [0..1], so rescale 
  vec2 g_texture_stretch_dim = fg_dimensionsArray[lc].st;
  g_texture_scale = tile_size.xy / g_texture_stretch_dim.xy;
  // Correct partial derivatives to account for stretching of different textures
  dFdx_and_dFdy = dFdx_and_dFdy * vec4(g_texture_scale.st, g_texture_scale.st);
  // Ground texture coords
  st = g_texture_scale * tile_coord.st;
}


// Rotate texture using the perlin texture as a mask to reduce tiling.
// type=0: use perlin texture, type = 1: use Noise2D to avoid texture lookup
// Testing: if this or get_ground_texture_data used in final WS3 to handle 
// many base texture lookups, see if optimising to handle many inputs helps 
// (vectorising Noise2D versus just many texture calls)
// To do: adjust for non-tile based ground coords.
vec2 detile_texcoords_with_perlin_noise(in vec2 st, in vec2 ground_texture_scale, 
  in vec2 tile_coord, inout vec4 dFdx_and_dFdy)
{
  vec4 dxdy = dFdx_and_dFdy;

  vec2 pnoise;

  // Ratio tile dimensions are stretched relative to s.
  // Tiles may not have equal dimensions.
  vec2 stretch_r = tile_size.st/tile_size.s;

  // Note: unresolved texture discontinuties (i.e. mipmap problems) with unequal stretch factors
  const vec2 local_stretch_factors = vec2(8.0, 8.0 /*16.0*/);

  if (detiling_noise_type==1) 
  {
      pnoise[0] = texture(perlin, st / local_stretch_factors[0]).r;
      pnoise[1] = texture(perlin, - st / local_stretch_factors[1]).r;
  } 
  else 
  {
      //Testing: Non texture alternative

      // Estimate of wavelength in /Textures/perlin.png in normalised texture coords
      const float ptex_wavelength = (1.0/7.0); 

      pnoise[0] = Noise2D(st / (local_stretch_factors[0]), ptex_wavelength);
      pnoise[1] = Noise2D(-st / (local_stretch_factors[1]), ptex_wavelength);
  }

  if (pnoise[0] >= 0.5) 
  {
    // To do: fix once ground coords are no longer tile based
    st = ground_texture_scale.st * (tile_coord * stretch_r).ts;
    // Get back original partial derivatives by undoing 
    // previous texture stretching adjustment done in get_ground_data
    dxdy = dxdy / vec4(ground_texture_scale.st, ground_texture_scale.st);

    // Recalculate new derivatives
    vec2 factor = ground_texture_scale.st * stretch_r.ts;
    dxdy.st = dxdy.ts * factor;	
    dxdy.pq = dxdy.qp * factor;

  } 

  if (pnoise[1] >= 0.5)
  {
    st = -st; dxdy = -dxdy;
  }

  dFdx_and_dFdy = dxdy;
  return st;
}


// Lookup a ground texture at a point based on the landclass at that point, without visible 
//   seams at coordinate discontinuities or at landclass boundaries where texture are switched.
//   The partial derivatives of the tile_coord at the fragment is needed to adjust for 
//   the stretching of different textures, so that the correct mip-map level is looked 
//   up and there are no seams.
//   Texture types: 0: base texture, 1: grain texture, 2: gradient texture, 3 dot texture, 
//     4: mix texture, 5: detail texture.

vec4 lookup_ground_texture_array(in int texture_type, in vec2 ground_texture_coord, in int landclass_id,
  in vec4 dFdx_and_dFdy)
{
  // Testing: may be able to save 1 or 2 op slots by combining dx/dy in a vec4 and
  // using swizzles which are free, but mostly operations are working independenly on s and t.
  // Only 1 place so far that just multiplies everything by a scalar.
  vec2 st;
  vec2 g_tex_coord = ground_texture_coord;
  vec2 g_texture_scale;
  vec4 texel;
  int lc = landclass_id;
  vec4 dxdy = dFdx_and_dFdy;
  
  // Find the index of the specified texture type (e.g. mix or gradient texture ) in 
  // the ground texture lookup array.
  // Since texture_type is a constant in the fragment shader, there should be no performance hit for branching.

  int tex_idx = 0;
  int type = texture_type;

  // Index for the base texture is contained fg_textureLookup1[lc].r
  if (type == 0) tex_idx = int(uint(fg_textureLookup1[lc].r * 255.0 + 0.5));

  // Grain texture is material texture slot 14, the index of which is mapped to the r channel of fg_textureLookup2
  else if (type == 1) tex_idx = int(fg_textureLookup2[lc].r * 255.0 + 0.5);

  // Gradient texture is material texture 13, the index of which is mapped to the a channel of fg_textureLookup1
  else if (type == 2) tex_idx = int(fg_textureLookup1[lc].a * 255.0 + 0.5);

  // Dot texture is material texture 15, the index of which is mapped to the g channel of fg_textureLookup2
  else if (type == 3) tex_idx = int(fg_textureLookup2[lc].g * 255.0 + 0.5);

  // Mix texture is material texture 12, the index of which is mapped to the b channel of fg_textureLookup1
  else if (type == 4) tex_idx = int(fg_textureLookup1[lc].b * 255.0 + 0.5);

  // Detail texture is material texture 11, the index of which is mapped to the g channel of fg_textureLookup1
  else if (type == 5) tex_idx = int(fg_textureLookup1[lc].g * 255.0 + 0.5);


  if (type == 0)
  {
    // Scale normalised tile coords by stretching factor, and get info
    vec2 tile_coord = g_tex_coord;
    get_ground_texture_data(lc, tile_coord, st, g_texture_scale, dxdy);
    st = detile_texcoords_with_perlin_noise(st, g_texture_scale, tile_coord, dxdy);
  }
  else
  {
    st = g_tex_coord;
  }


  // Debugging: multiple texture lookup functions if there are issues
  // with old GPUs and compilers.
  if (tex_lookup_type == 0)
  {
    texel = textureGrad(textureArray, vec3(st, tex_idx), dxdy.st, dxdy.pq);
  }
  else if (tex_lookup_type == 1) 
  { 
    float lod = max(length(dxdy.sp), length(dxdy.tq)); 
    lod = log2(lod); 
    texel = textureLod(textureArray, vec3(st, tex_idx), lod); 
  }
  else texel = texture(textureArray, vec3(st, tex_idx));


  //texel = textureGrad(textureArray, vec3(st, tex_idx), dxdy.st, dxdy.pq);
  return texel;
}


//  Look up the texel of the specified texture type (e.g. grain or detail textures) for this fragment
//    and any neighbor texels, then mix.

vec4 get_mixed_texel(in int texture_type, in vec2 g_texture_coord, 
  in int landclass_id, in int num_unique_neighbors, 
  in ivec4 neighbor_texel_landclass_ids, in vec4 neighbor_mix_factors,
  in vec4 dFdx_and_dFdy
  )
{
    vec2 st = g_texture_coord;
    int lc = landclass_id;
    ivec4 lc_n = neighbor_texel_landclass_ids;
    // Not implemented yet
    int type = texture_type;
    vec4 dxdy = dFdx_and_dFdy;
    vec4 mfact = neighbor_mix_factors;

    vec4 texel = lookup_ground_texture_array(0, st, lc, dxdy);


    // Mix texels - to work consistently it needs a more preceptual interpolation than mix()
    if (num_unique_neighbors != 0)
    {
      // Closest neighbor landclass
      vec4 texel_closest = lookup_ground_texture_array(0, st, lc_n[0], dxdy);
  
      // Neighbor contributions
      vec4 texel_nc=texel_closest;
  
      if (num_unique_neighbors > 1)
      {
        // 2nd Closest neighbor landclass
        vec4 texel_2nd_closest = lookup_ground_texture_array(0, st, lc_n[1], dxdy);
  
        texel_nc = mix(texel_closest, texel_2nd_closest, mfact[1]);
      }
  
      texel = mix(texel, texel_nc, mfact[0]);
    }
    return texel;
}


// Landclass sources: texture or random 
int read_landclass_id(in vec2 tile_coord)
{
  int lc;

  if (landclass_source == 0) lc = (int(texture2D(landclass, tile_coord.st).g * 255.0 + 0.5));
  else lc = (get_random_landclass(tile_coord.st, tile_size));
  return lc;
}


int read_landclass_id_non_pixelated(in vec2 tile_coord, 
  const in float landclass_texel_size_m)
{
  vec2 c0 = tile_coord;
  vec2 sz = tile_size;
  vec2 tsz = vec2(landclass_texel_size_m)/tile_size;

  // Landclass sources: texture or random
  int lc = read_landclass_id(c0);

  return lc;
}


// Determine whether to grow a neighbor landclass onto current. 
// 1 = grow neighbor, 0 = don't grow neighbor
float get_growth_priority(in int current_landclass, in int neighbor_landclass)
{
  int lc1 = current_landclass;
  int lc2 = neighbor_landclass;
  return ((lc1 < lc2)?1.0:0.0);
}


// Determine whether to grow a one of 2 neighbor landclasses onto current. 
// 1 = grow neighbor, 0 = don't grow neighbor
float get_growth_priority(in int current_landclass, in int neighbor_landclass1, in int neighbor_landclass2)
{
  int lc1 = current_landclass;
  int lc2 = neighbor_landclass1;
  int lc3 = neighbor_landclass2;
  return ((lc1 < max(lc2,lc3))?1.0:0.0);
}


int lookup_landclass_id(in vec2 tile_coord, in vec4 dFdx_and_dFdy,
    out ivec4 neighbor_texel_landclass_ids, 
    out int number_of_unique_neighbors_found, out vec4 landclass_neighbor_texel_weights)
{

  // To do: fix landclass border artifacts, with all shaders.

  vec4 dxdy = dFdx_and_dFdy;

  // Number of unique neighbours found
  int num_n = 0;

  vec2 c0 = tile_coord;
  vec2 sz = tile_size;

  // Landclass sources: texture or random
  int lc = read_landclass_id(c0);
  int output_landclass = lc;

  // Landclasses of up to 4 neighbor texels
  ivec4 lc_n = ivec4(lc);

  // Landclasses sorted
  ivec4 lc_n_s;

  // Combined weight from 2 neighbor texels
  float w = 0.0;

  // Landclass neighbor weights - for texel mixing only
  vec4 lc_n_w = vec4(0.0);

// Test phase controls
if ( (remove_squareness_from_landclass_texture == 1) || 
     ( (use_landclass_texel_scale_transition_only == 1) &&
       (enable_large_scale_transition_search == 0) ) 
   ) 
{


  // Remove squareness from the landclass texture due to nearest neighbour interpolation
  // A landclass with higher growth priority grows on to an adjacent landclass
  // with lower priority 

  // Landclass texture dimensions, in texels - Needs glsl 1.30+ 
  // Probably best to just send as uniforms if texture sizes don't vary, or are fixed per terrain LoD level.
  vec2 texture_dim_tx = vec2(textureSize(landclass, 0));

  // Coordinates of current fragment, in texels
  vec2 c0_tx = c0 * texture_dim_tx;

  // Coordinates of the center of the current texel, in texels
  // centers are n+(0.5,0.5) for n = 0,1,2...
  vec2 ct_c0_tx = floor(c0_tx) + 0.5;
  // center in normalised tex coords
  vec2 ct_c0 = ct_c0_tx/texture_dim_tx;

  // Landclass at center of current texel - same anywhere within a texel
  int lc_ct = lc;

  // Coords of centers of closest neighbors, in texels
  vec2 c_n_tx[2];


  // Coordinate of fragment relative to center of texel, in texels
  vec2 c0_rel_ct_tx = c0_tx - ct_c0_tx;

  float dist_ct = length(c0_rel_ct_tx);
  
  // need to avoid division by 0?
  if (dist_ct < 0.00001) dist_ct += 0.00001;

  // Choose closest neighbor based on angle wrt. to 
  // c0, center of texel, and s & t axes.
  // Choose the texel in the direction of the largest s & t component.
  // NB: This method will select a diagonal neighbor if 
  // both components of c0_rel_ct_tx are equal to cos(45).
  // Testing: look for a way that uses fewer instructions, 
  // maybe calculating 2 neighbors at once using a vec4.

  //vec2 a = abs(c0_rel_ct_tx);
  //offset_ct0 = ((a.s > a.t)?vec2(1.0,0.0):vec2(0.0,1.0))*sign(c0_rel_ct_tx);

  // Vectorisable
  const float cos45deg = cos(radians(45.0));
  vec2 offset_ct0 = step(cos45deg, abs(c0_rel_ct_tx/dist_ct))
                      *sign(c0_rel_ct_tx);
  
  c_n_tx[0] = (ct_c0_tx + offset_ct0);

  // Landclass of closest neighbor
  lc_n[0] = read_landclass_id(c_n_tx[0]/texture_dim_tx);


  // Choose 2nd closest neighbor
  // Choose texels in the direction of the smaller of s & t components
  vec2 offset_ct1 = abs(offset_ct0.ts)*step(0.0, abs(c0_rel_ct_tx/dist_ct))
                    * sign(c0_rel_ct_tx);

  c_n_tx[1] = (ct_c0_tx + offset_ct1);

  // Land class of 2nd closest neighbor
  lc_n[1] = read_landclass_id(c_n_tx[1]/texture_dim_tx);


  // Distinct neighbors found
  // Testing: possible optimisation, use booleans. 
  // Needs ivec4/1.30+, or vec4/1.20 - reliably supported by old compilers?
  // bvec4 n_found = notEqual(lc_n, ivec4(lc));

  ivec4 n_found = ivec4(((lc_n[0] != lc)?1:0), ((lc_n[1] != lc)?1:0), 0, 0);

  num_n = n_found[0]+ n_found[1];


  //if (any(n_found))
  if ((n_found[0] == 1) || (n_found[1] == 1))
  {
    
    // Weights for influence from neighbor landclasses
    //   The distance away from the neighbor texel side is used to determine influence.
    //   w_n: 0.5 at minimum possible distance, 0.0 at maximum possible distance 
  
    // Neighbor weights
    vec4 w_n = vec4(0.0);

  
    // Method 1:
    //   Use distance from side of neighbor texel for mixing
    //   This is has some issues, including with corners
  
    vec2 dir0 = offset_ct0;
    vec2 dir1 = offset_ct1;
  
    // Distance from side of neighbor texel, in texels
    vec2 d0 = dir0*c0_rel_ct_tx;
    vec2 d1 =dir1*c0_rel_ct_tx;
  
    w_n[0] = max(d0.x, d0.y);
    w_n[1] = max(d1.x, d1.y);



/*
    //Method 2:
    // use distance from center of neighbor texel for mixing
    // This doesn't really give better results than 1

    // Distance from center of neighbor texels, in texels
    vec2 dist_n_tx = vec2(0.0);

    dist_n_tx[0] = length(c0_tx - c_n_tx[0]);
    dist_n_tx[1] = length(c0_tx - c_n_tx[1]);


    // Weighting for closest neighbor - [0.5 to 0.0] as distance goes from [min to max]
    const float max_dist = sqrt(0.5*0.5+1.0);
    const float min_dist = 0.5;
    w_n[0] = (dist_n_tx[0]-min_dist)/(max_dist - min_dist);
    w_n[0] = mix(0.5, 0.0, w_n[0]);


    // Weighting for 2nd closest neighbor - [0.5 to 0.0] as distance goes from [min to max]
    //const float max_dist1 = sqrt(0.5*0.5+1.0);
    //const float min_dist = 0.5;
    w_n[1] = (dist_n_tx[1]-min_dist)/(max_dist-min_dist);
    w_n[1] = mix(0.5, 0.0, w_n[1]);
*/


    // Use weighting only if neighbour is different from landclass for this fragment
    // Testing: Can be omitted if not doing texture mixing as it doesn't really 
    //   make a difference.
    w_n = w_n * vec4(n_found);

    // Combined weighting - increase w_n[0] if the 2nd closest neigbour is
    // different such that w_n[0] remains under 0.5
    w = w_n[0];
    w = w + (0.5-w)*2.0*w_n[1];

    // Sort landclasses and weights
    lc_n_s = lc_n;
    // If closest neighbour is lc, move 2nd closest neighbour to closest slot, and
    // clear the 2nd closest slot
    if (n_found[0] == 0)
    {
      lc_n_s.xy = lc_n.yz;
      w_n.xy = w_n.yz;
    }


// Testing phase controls
if ( (use_landclass_texel_scale_transition_only == 1) && 
     (max_neighbor_landclass_texture_lookups > 0) &&
     (enable_large_scale_transition_search == 0)
   )
{
    // Assign mix factors for transitions by mixing texels
    // [0]: 0 to 0.5
    // [1]: split [0 to 1] between closest and 2nd closest landclass 
    lc_n_w[0] = w;
    lc_n_w[1] = w_n[1]/(w_n[0]+w_n[1]);
}


} // Testing controls: End if ((remove_squareness_from_landclass_texture == 1) || (use_landclass_texel_scale_transition_only == 1))


if (remove_squareness_from_landclass_texture == 1)
{
    // Turn neighbor growth off at longer ranges, otherwise there is flickering noise
    // Testing: The exact cutoff could be done sooner to save some performance - needs
    // to be part of a larger solution to similar issues. User should set a tolerance factor.
    // Effectively: lod_factor = min(length(vec2(dFdx(..).s, dFdy(..).s)),length(vec2(dFdx(..).t, dFdy(..).t)));
    float lod_factor = min(length(vec2(dxdy.s, dxdy.p)),length(vec2(dxdy.t, dxdy.q)));

    // Estimate of frequency of growth noise in texels - i.e. how many peaks and troughs fit in one texel
    const float frequency_g_n = 1000.0;
    const float cutoff = 1.0/frequency_g_n;

    if (lod_factor < cutoff)
    {
      // Decide whether to grow neighbor on to lc
      float grow_n = get_growth_priority(lc,lc_n[0]);

      // Noise on the scale of landclass texels in the texture
      // Testing: reduce instructions if this method is to be used. 
      //   To look at: corner visuals & sharp diagonals.

      // Minimum wavelength of transition noise
      const float wl_tn = (1.0/8.0);
      float tn = Noise2D(c0*texture_dim_tx, wl_tn); // old val 1.6

      float threshold = mix(1.0,0.0, w);

      float neighbor_growth_weight = (0.3*2.0)*w*step(threshold-0.15, tn);

      // Growth factor
      float g = ((grow_n > 0.0)?neighbor_growth_weight:-neighbor_growth_weight);
      //g = sqrt(abs(g))*sign(g);

      // Neighbor growth value
      float v;
      //v=w+g;
      v = w*(0.7+50.5*g);

      // Whether or not to grow neighbour onto nearby pixel

      // To do - mix factor between different neighbour lanclasses 
      // when using an extra ground texture lookup

      if (v > 0.5) output_landclass = lc_n_s[0];




// Testing phase controls
if ( (use_landclass_texel_scale_transition_only == 1) && 
     (max_neighbor_landclass_texture_lookups > 0) &&
     (enable_large_scale_transition_search == 0)
   )
{

    lc_n_w[0] = 0.0;
/*
    // Adjust mix factor weights and swap landclasses for extrusions

    // Method 1:

    lc_n_w[0] = (w-0.5*neighbor_growth_weight);
    if (v > 0.5) lc_n_s[0] = lc;
*/


    // Method 2:
    // Mix in neighbour texel, instead of change output landclass.

    // Undo previous output class assignment
    output_landclass = lc;

    // Reduce flickering noise due to small detail added when far away. Contrasting colors mean more visible issues.
    // Fade 0 to 1 as lod_factor goes from 1.0 to 4.0
    // The goal is to avoid flickering with worst case texture filtering and supersampling.
    // Testing: However, the quicker the detil fades, the more square distant ladnclasses look.
    //          Right now the noise function generates too many high frequency components (small detail)

    //const float mmax = 4000.0; const float mmin = mmax-1000.0; /* no flickering */
    const float mmax = 3000.0; const float mmin = mmax-1000.0;  /* bit of filckering */
    float fade = smoothstep(mmin, mmax, 1.0/lod_factor);

    lc_n_w[0] = (w-0.5*3.333*0.9*(neighbor_growth_weight*fade));
    if (v > 0.5) lc_n_w[0] = w+0.4*fade;



}



    } // End if (lod_factor > some value)


} // Testing code: End if (remove_squareness_from_landclass_texture == 1)



  } // End if (nfound[0] == 1) || (n_found[1] == 1)




  landclass_neighbor_texel_weights = lc_n_w;
  neighbor_texel_landclass_ids = lc_n_s;
  number_of_unique_neighbors_found = num_n;
  return output_landclass;

}



// Look up the landclass id [0 .. 255] for this particular fragment.
// Lookup id of any neighbouring landclass that is within the search distance.
// Searches are performed in upto 4 directions right now, but only one landclass is looked up
// Create a mix factor werighting the influences of nearby landclasses

void get_landclass_id(in vec2 tile_coord, in vec4 dFdx_and_dFdy,
  out int landclass_id, out ivec4 neighbor_landclass_ids, 
  out int num_unique_neighbors,out vec4 mix_factor
  )

{ 
  // Each tile has 1 texture containing landclass ids stetched over it

  // Landclass source type: 0=texture, 1=random squares
  // Controls are defined at global scope. 
  vec2 sz = tile_size;

  vec4 dxdy = dFdx_and_dFdy;

  // Number of unique neighbors found
  int num_n = 0;

  // Only used for mixing textures of neighboring texels:
  // Landclass ids of neigbors in neighboring texels
  ivec4 lc_n_tx;
  // Weights of neighbour landclass texels
  vec4 lc_n_w;
  // Number of unique neighbors in neighboring texels
  int num_n_tx = 0;

  int lc = lookup_landclass_id(tile_coord, dxdy, lc_n_tx, num_n_tx, lc_n_w);

  float edge_hardness = 0.0;
  if (use_edge_hardness_with_large_scale_transition == 1) {
    edge_hardness = fg_dimensionsArray[lc].a;
  }

  // Neighbor landclass ids
  ivec4 lc_n = ivec4(lc);

  // Mix factors: texels are mixed in from furthest, to closest
  //   mfact[1]: [0 to 1] mixing 1st and 2nd closest texels
  //   mfact[0]: [0 to 0.5] texel and previous neighbour contributions
  vec4 mfact = vec4(0.0);


// Testing phase controls
if ( (use_landclass_texel_scale_transition_only == 1) && 
     (max_neighbor_landclass_texture_lookups > 0) &&
     (enable_large_scale_transition_search == 0)
   )

{
  // Use the ground texture lookups to do a transition on the scale of
  // the landclass textures instead of doing a large scale transition
  num_n = num_n_tx;
  lc_n = lc_n_tx;
  mfact = lc_n_w;
}
      

// Testing phase controls
if ( (enable_large_scale_transition_search == 1) && 
     (max_neighbor_landclass_texture_lookups > 0) &&
     (use_landclass_texel_scale_transition_only == 0)
   )
{


  // Transition search
  const int n = num_search_points_in_a_direction;

  const float search_dist = transition_search_distance_in_m;
  vec2 step_size_m = vec2(search_dist/float(n));
  // step size in tile coords.  Modulated by the edge hardness which makes 
  // the step size smaller and hence the range of adjacent landclasses
  // smaller.
  vec2 steps = step_size_m.st / tile_size.st * (1.0 - edge_hardness);

  vec2 c0 = tile_coord;

  // Min number of points (loop counter value (i)) before 
  // a different landclass is found
  ivec4 mi = ivec4(n+1);

  // landclass - l can be accessed as an array e.g. l[0]=l.x
  ivec4 l = ivec4(lc);

  // Search in 4 directions. These for loops likely need unrolling, 
  // and optimising to use minimum instructions, if they are 
  // to be used outside of testing the search concept.
  // The texture access patterns may be suboptimal as well.
  // Travelling along s and t axes might work better.
  // Note: this returns the closest neighbor. There could be blobs
  // of multiple neighbors, or a tiny islands of neighbors among this
  // landclass.


  // Testing: breaking the loop once the closest neighbour is found
  //   results in very slightly lower FPS on a 10 series GPU for 100m search 
  //   distance and 4 points. May be faster on old GPUs with slow caching.


  // +s direction
  vec2 dir = vec2(steps.s, 0.0);

  for (int i=1;i<=n;i++) {
      vec2 c = c0+float(i)*dir;
      int v = read_landclass_id(c);
      if ((v != lc) && (mi[0] > n)) {l[0] = v; mi[0] = i; }
  }


  // -s direction
  dir = vec2(-steps.s, 0.0);
  for (int i=1;i<=n;i++) 
  {
      vec2 c = c0+float(i)*dir; 
      int v = read_landclass_id(c);
      if ((v != lc) && (mi[1] > n)) {l[1] = v; mi[1] = i; }
  }


  // +t direction
  dir = vec2(0.0, steps.t);
  for (int i=1;i<=n;i++) 
  {
      vec2 c = c0+float(i)*dir;  
      int v = read_landclass_id(c);
      if ((v != lc) && (mi[2] > n)) {l[2] = v; mi[2] = i; }
  }


  // -t direction
  dir = vec2(0.0, -steps.t);
  for (int i=1;i<=n;i++) 
  {
      vec2 c = c0+float(i)*dir;
      int v = read_landclass_id(c);
      if ((v != lc) && (mi[3] > n)) {l[3] = v; mi[3] = i; }
  }


  // Set neighbour landclass

  // Choose closest neighbor
  // min number of steps before a neighbor was found in any direction
  int mns = n+1;
  // index of mi[] with min number of steps
  int idx1=-1;
  for (int j=0;j<4;j++)
  {
      if (mi[j] < mns) {mns = mi[j]; idx1 = j; lc_n[0] = l[j]; num_n=1;}
  }

  // Transitions:
  // Possible landclass property: Transition distance or weighting
  // e.g. larger transition between sand/grass terrain compared to forest/agriculture

  // Find mix factor and increase influence for 2, 3 or 4 nearby landclass blobs. 
  // If one neighbor landclass texture is looked up, even if the nearby landclasses 
  // are different only one texture will get prominence

  // At the boundary between landclasses there should be 50% influence.
  // If needed it's possible to add a dominance factor.

  // mi ranges from n+1 to 1. Mix factor ranges from [0.0 to 0.5] 
  // 3 point search example: 
  // [Num steps=Mixfactor value]: [no neighbor found = 0.0], [1 = 0.25], [2 = 0.5]

  
  // Calculate weights: map [n+1 to 1] to [0.0 to 0.5]
  vec4 w = 0.5*(1.0-(vec4(mi-1)/float(n)));


  // Calculate mix factor to draw one neighbor landclass
  float mf1=0.0;

  // Method 1:
  float max_w = max(max(max(w[0],w[1]),w[2]),w[3]);
  //mf1 = max_w;

  // Method 2: add up the influence and clamp to 0.5
  //mf1 = min(w.x+w.y+w.z+w.w, 0.5);


  // Method 3: weight influence without going over limit or needing to clamp
  // Example with influence [0 to 1]: 
  //    2 neighbors with 0.5 influence: 0.75 . 3 neighbors with 0.5 = 87.25
  //    of course influence is [0 to 0.5] but idea is the same
  mf1 = w[0];
  mf1 += (0.5-mf1)*w[1];
  mf1 += (0.5-mf1)*w[2];
  mf1 += (0.5-mf1)*w[3];

  // Mix factors: texels are mixed in from furthest, to closest
  //   mfact[0]: [0 to 0.5] texel and previous neighbour contributions
  //   mfact[1]: [0 to 1] mixing 1st and 2nd closest texels
  mfact[0] = mf1;


// Test phase controls:
if (enable_2nd_closest_neighbor_for_large_scale_transition_weights == 1)
{
  
  // Calculate mix factor for the case of two neighbour landclasses

  // index of mi[] with the 2nd lowest number of steps
  int idx2=-1;
  if (idx1 != -1) {

      // Choose 2nd closest neighbor        
      // Testing: look at a way to find 2 closest neighbors with less instructions
      // 2nd lowest number of steps
      int mns2 = n+1;
      for (int j=0;j<4;j++) {
          if ((mi[j] < mns2) && (mi[j] >= mns) && (j != idx1))
              {mns2 = mi[j]; lc_n[1] = l[j]; idx2=j; num_n=2;}
      }
  }


  // If two neighbors are found split available mix factor (mf1) by relative weights
  if (idx2 != -1) {
      float rw = w[idx2]/(w[idx1]+w[idx2]);
      mfact[1] = rw;
   }


} // End if (enable_2nd_closest_neighbor_for_large_scale_transition_weights == 1)


// Test phase controls
if (enable_dithering_for_large_scale_transitions == 1)
{ 
  // Add noise to change transition
  float tnoise1= Noise2D(tile_coord, dithering_noise_wavelength_as_fraction_of_step_size*steps.x);
  float noise = 0.5*(1.0-tnoise1)/float(n);
  mfact[0]=mfact[0]+noise; 
  mfact[0]=clamp(mfact[0],0.0,0.5);
}


// Test phase controls
if (grow_landclass_borders_with_large_scale_transition == 1)
{

  // Grow landclass borders with noise so landclass blobs that are too artificial
  // looking or coarse look natural.
  // A landclass with higher growth priority grows on to an adjacent landclass
  // with lower priority 

  // Decide whether to grow neighbor on to lc
  float grow_n = get_growth_priority(lc,lc_n[0],lc_n[1]);

  // Noise on the scale of landclass texels in the texture
  float tnoise2 = Noise2D(tile_coord, 0.4*transition_search_distance_in_m/tile_size.x);
  float threshold = mix(1.0,0.0, mfact[0]);
  float neighbor_growth_mixf = 0.3*mix(0.0,1.0,mfact[0]*2.0)*step(threshold-0.15,tnoise2);

  mfact[0] = mfact[0]+((grow_n > 0.0)?neighbor_growth_mixf:-neighbor_growth_mixf);
  mfact[0] = clamp(mfact[0],0.0,1.0);


  // Decide whether to extrude furthest neighbor or closest neighbor onto lc
  float grow_n1 = get_growth_priority(lc_n[0],lc_n[1]);

  mfact[1] = mfact[1]+((grow_n > 0.0)?neighbor_growth_mixf:-neighbor_growth_mixf);
  mfact[1] = clamp(mfact[1],0.0,1.0);


} // Testing: End if (grow_landclass_borders_with_large_scale_transition == 1)


} // Testing: End if ((enable_large_scale_transition_search == 1) && (max_neighbor_landclass_texture_lookups > 0))


  //lc = int(t);
  //mfact[2] = t;

  landclass_id = lc;
  neighbor_landclass_ids=lc_n;
  num_unique_neighbors = num_n;
  mix_factor = mfact;
}



// End Test-phase code
////////////////////////


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
  )
{ 
  // Calculate texture coords for ground textures
  // Textures are stretched along the ground to different 
  // lengths along each axes as set by <xsize> and <ysize> 
  // regional definitions parameters.
  vec2 stretch_dimensions = fg_dimensionsArray[landclass].st;
  vec2 tileSize = vec2(fg_tileWidth, fg_tileHeight);
  vec2 texture_scaling =  tileSize.yx / stretch_dimensions.st;
  st = texture_scaling.st * ground_tex_coord.st;

  // Scale partial derivatives
  dxdy = vec4(texture_scaling.st, texture_scaling.st)  * dxdy_gc;

  if (fg_photoScenery) {
    // In the photoscenery case we don't have landclass or materials available, so we
    // just use constants for the material properties.
    mat_ambient = vec4(0.2,0.2,0.2,1.0);
    mat_diffuse = vec4(0.8,0.8,0.8,1.0);
    mat_specular = vec4(0.0,0.0,0.0,1.0);
    mat_shininess = 1.2;
  } else {
    // Color Mode is always AMBIENT_AND_DIFFUSE, which means
    // using a base colour of white for ambient/diffuse,
    // rather than the material color from ambientArray/diffuseArray.
    mat_ambient = vec4(1.0,1.0,1.0,1.0);
    mat_diffuse = vec4(1.0,1.0,1.0,1.0);
    mat_specular = fg_specularArray[landclass];
    mat_shininess = fg_dimensionsArray[landclass].z;
  }
}
