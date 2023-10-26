// -*-C++-*-
#version 120

uniform float air_pollution;
uniform int quality_level;
uniform float fogstructure;
uniform float cloud_self_shading;
uniform float scattering;
uniform float terminator;
uniform float terrain_alt; 
uniform float overcast;
uniform float eye_alt;

const float terminator_width = 200000.0;
const float EarthRadius = 5800000.0;

varying vec3 relPos;
varying vec4 light_diffuse_comp;
varying vec3 normal;
varying vec3 worldPos;

float Noise2D(in vec2 coord, in float wavelength);
vec3 filter_combined (in vec3 color) ;
float Noise3D(in vec3 coord, in float wavelength);

const float AtmosphericScaleHeight = 8500.0;

// Development tools:
//   Reduce haze to almost zero, while preserving lighting. Useful for observing distant tiles.
//     Keeps the calculation overhead. This can be used for profiling.
//     Possible values: 0:Normal, 1:Reduced haze.
    const int reduce_haze_without_removing_calculation_overhead = 0;

// standard ALS fog function with exp(-d/D) fading and cutoff at low altitude and exp(-d^2/D^2) at high altitude
float fog_func (in float targ, in float alt)
{
  float fade_mix;

  targ = 1.25 * targ * smoothstep(0.04,0.06,targ); // need to sync with the distance to which terrain is drawn

  // for large altitude > 30 km, we switch to some component of quadratic distance fading to
  // create the illusion of improved visibility range

  if (alt < 30000.0) {
    return exp(-targ - targ * targ * targ * targ);
  } else if (alt < 50000.0) {
    fade_mix = (alt - 30000.0)/20000.0;
    return fade_mix * exp(-targ*targ - pow(targ,4.0)) + (1.0 - fade_mix) * exp(-targ - pow(targ,4.0));  
  } else {
    return exp(- targ * targ - pow(targ,4.0));
  }
}

// altitude correction for exponential drop in atmosphere density
float alt_factor(in float eye_alt, in float vertex_alt)
{
  float h0 = AtmosphericScaleHeight;
  float h1 = min(eye_alt,vertex_alt);
  float h2 = max(eye_alt,vertex_alt);

  if ((h2-h1) < 200.0) // use a Taylor-expanded version
  {
    return  0.5 * (exp(-h2/h0) + exp(-h1/h0));
  } else {
    return h0/(h2-h1) * (exp(-h1/h0) - exp(-h2/h0));
  }
}

// Rayleigh in-scatter function
float rayleigh_in_func(in float dist, in float air_pollution, in float avisibility, in float eye_alt, in float vertex_alt)
{
  float fade_length = avisibility * (2.5 - 2.2 * sqrt(air_pollution));
  fade_length = fade_length / alt_factor(eye_alt, vertex_alt);
  return 1.0-exp(-dist/max(15000.0,fade_length));
}

// Rayleigh out-scattering color shift
vec3 rayleigh_out_shift(in vec3 color, in float outscatter)
{
  color.r = color.r * (1.0 - 0.4 * outscatter);
  color.g = color.g * (1.0 - 0.8 * outscatter);
  color.b = color.b * (1.0 - 1.6 * outscatter);
  return color;
} 

// the generalized logistic function used to compute lightcurves
float light_curve (in float x, in float a, in float b, in float c, in float d, in float e)
{
  x = x - 0.5;
  // use the asymptotics to shorten computations
  if (x > 30.0)  { return e; }
  if (x < -15.0) { return 0.0; }
  return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}

// the haze color function
vec3 get_hazeColor(in float lightArg)
{
  vec3 hazeColor;
  hazeColor.r = light_curve(lightArg, 8.305e-06, 0.161, 4.827-3.0 *air_pollution, 3.04e-05, 1.0);
  hazeColor.g = light_curve(lightArg, 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
  hazeColor.b = light_curve(lightArg, 1.330e-05, 0.264, 1.527+ 2.0*air_pollution, 1.08e-05, 1.0);
  return hazeColor;
}

// Apply the ALS haze model to a given fragment
vec4 applyHaze(inout vec4  fragColor, 
               inout vec3  hazeColor, 
               in    vec3  secondary_light,
               in    float ct,
               in    float hazeLayerAltitude,
               in    float visibility,
               in    float avisibility,
               in    float dist,
               in    float lightArg,
               in    float mie_angle)
{
  float mvisibility = min(visibility,avisibility);

  if (dist > 0.04 * mvisibility) 
  {
    float transmission;
    float vAltitude;
    float delta_zv;
    float H;
    float distance_in_layer;
    float transmission_arg;
    float intensity;
    float eShade;

    float delta_z = hazeLayerAltitude - eye_alt;
    float effective_scattering = min(scattering, cloud_self_shading);
    float yprime_alt = light_diffuse_comp.a;
    vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
    vec3 lightDir = gl_LightSource[0].position.xyz;
    vec3 n = normal;
    n = normalize(n);

    // we solve the geometry what part of the light path is attenuated normally and what is through the haze layer
    if (delta_z > 0.0) { // we're inside the layer
      if (ct < 0.0) { // we look down 
        distance_in_layer = dist;
        vAltitude = min(distance_in_layer,mvisibility) * ct;
        delta_zv = delta_z - vAltitude;
      } else {
        // we may look through upper layer edge
        H = dist * ct;
        
        if (H > delta_z) {
          distance_in_layer = dist/H * delta_z;
        } else {
          distance_in_layer = dist;
        }

        vAltitude = min(distance_in_layer,visibility) * ct;
        delta_zv = delta_z - vAltitude;  
      }
    } else { // we see the layer from above, delta_z < 0.0
      H = dist * -ct;
      if (H  < (-delta_z)) { // we don't see into the layer at all, aloft visibility is the only fading
        distance_in_layer = 0.0;
        delta_zv = 0.0;
      } else {
        vAltitude = H + delta_z;
        distance_in_layer = vAltitude/H * dist; 
        vAltitude = min(distance_in_layer,visibility) * (-ct);
        delta_zv = vAltitude;
      } 
    }

    if ((quality_level > 4) && (abs(delta_z) < 400.0)) {
      float blur_thickness = 50.0;
      float cphi = dot(vec3(0.0, 1.0, 0.0), relPos)/dist;
      float ctlayer = delta_z/dist-0.01 + 0.02 * Noise2D(vec2(cphi,1.0),0.1) -0.01;
      float ctblur = 0.035 ;
      float blur_dist;

      blur_dist = dist * (1.0-smoothstep(0.0,300.0,-delta_z)) * smoothstep(-400.0,-200.0, -delta_z);
      blur_dist = blur_dist * smoothstep(ctlayer-4.0*ctblur, ctlayer-ctblur, ct) * (1.0-smoothstep(ctlayer+0.5*ctblur, ctlayer+ctblur, ct));
      distance_in_layer = max(distance_in_layer, blur_dist);
    }
  
    // ground haze cannot be thinner than aloft visibility in the model,
    // so we need to use aloft visibility otherwise
    transmission_arg = (dist-distance_in_layer)/avisibility;
    float eqColorFactor;

    if (quality_level > 3) {
      float noise_1500m = Noise3D(worldPos.xyz, 1500.0);
      float noise_2000m = Noise3D(worldPos.xyz, 2000.0);
      transmission_arg = transmission_arg + (distance_in_layer/(1.0 * mvisibility + 1.0 * mvisibility * fogstructure * 0.06 * (noise_1500m + noise_2000m -1.0) ));
    } else {
      transmission_arg = transmission_arg + (distance_in_layer/mvisibility);
    }

    // this combines the Weber-Fechner intensity
    eqColorFactor = 1.0 - 0.1 * delta_zv/mvisibility - (1.0 - effective_scattering);
    transmission =  fog_func(transmission_arg, eye_alt);
  
    // there's always residual intensity, we should never be driven to zero
    if (eqColorFactor < 0.2) eqColorFactor = 0.2;
    
    // now dim the light for haze
    eShade = 1.0 - 0.9 * smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt);
    
    // Mie-like factor
    if (lightArg < 10.0) {
      intensity = length(hazeColor);
      float mie_magnitude = 0.5 * smoothstep(350000.0, 150000.0, terminator-sqrt(2.0 * EarthRadius * terrain_alt));
      hazeColor = intensity * ((1.0 - mie_magnitude) + mie_magnitude * mie_angle) * normalize(mix(hazeColor,  vec3 (0.5, 0.58, 0.65), mie_magnitude * (0.5 - 0.5 * mie_angle)) ); 
    }
    
    intensity = length(hazeColor);
  
    if (intensity > 0.0) // this needs to be a condition, because otherwise hazeColor doesn't come out correctly
    {
      // high altitude desaturation of the haze color
      hazeColor = intensity * normalize (mix(hazeColor, intensity * vec3 (1.0,1.0,1.0), 0.7* smoothstep(5000.0, 50000.0, eye_alt)));
      
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
    
    // Testing phase controls
    if (reduce_haze_without_removing_calculation_overhead == 1)
    {
      transmission = 1.0 - (transmission/1000000.0);
    }
    
    // finally, mix fog in
    if (quality_level > 4) {
      float backscatter = 0.5* min(1.0,10000.0/(mvisibility*mvisibility));
      fragColor.rgb = mix(hazeColor+secondary_light * backscatter , fragColor.rgb,transmission);
    } else {
      fragColor.rgb = mix(clamp(hazeColor,0.0,1.0) , clamp(fragColor.rgb,0.0,1.0),transmission);   
    }
  } // end if (dist > 0.04 * mvisibility) 
  
  fragColor.rgb = filter_combined(fragColor.rgb);
  return fragColor;
}