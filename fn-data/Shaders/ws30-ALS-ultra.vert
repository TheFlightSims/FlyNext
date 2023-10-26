// WS30 VERTEX SHADER
// -*-C++-*-
#version 120

// Shader that uses OpenGL state values to do per-pixel lighting
//
// The only light used is gl_LightSource[0], which is assumed to be
// directional.
//
// Colors are not assigned in this shader, as they will come from
// the landclass lookup in the fragment shader.
// Haze part added by Thorsten Renk, Oct. 2011


#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2


// The constant term of the lighting equation that doesn't depend on
// the surface normal is passed in gl_{Front,Back}Color. The alpha
// component is set to 1 for front, 0 for back in order to work around
// bugs with gl_FrontFacing in the fragment shader.
varying vec4 light_diffuse_comp;
varying vec3 normal;
varying vec3 relPos;
varying vec2 ground_tex_coord;
varying vec2 rawPos;
varying vec3 worldPos;
varying vec3 ecViewdir;
varying vec2 grad_dir;
varying vec4 ecPosition;
varying vec3 vertVec;

// For water calculations
varying float earthShade;
varying vec3 lightdir;
varying vec4 waterTex1;
varying vec4 waterTex2;
varying vec4 waterTex4;
varying vec3 specular_light;

uniform float osg_SimulationTime;
uniform float WindN;
uniform float WindE;

// Sent packed into alpha channels
//varying float yprime_alt;
varying float mie_angle;

varying float steepness;

uniform int colorMode;

uniform bool raise_vertex;

uniform float hazeLayerAltitude;
uniform float terminator;
uniform float terrain_alt; 
uniform float avisibility;
uniform float visibility;
uniform float overcast;
uniform float ground_scattering;
uniform float eye_alt;
uniform float moonlight;

uniform bool use_IR_vision;

uniform mat4 osg_ViewMatrixInverse;

// From VPBTechnique.cxx
uniform mat4 fg_zUpTransform;
uniform vec3 fg_modelOffset;

float yprime_alt;

vec3 moonlight_perception (in vec3 light);

void setupShadows(vec4 eyeSpacePos);

// This is the value used in the skydome scattering shader - use the same here for consistency?
const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;




float light_func (in float x, in float a, in float b, in float c, in float d, in float e)
{
  //x = x - 0.5;
  // use the asymptotics to shorten computations
  if (x < -15.0) {return 0.0;}
  return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}

void createRotationMatrix(in float angle, out mat4 rotmat)
{
  rotmat = mat4( cos( angle ), -sin( angle ), 0.0, 0.0,
      sin( angle ),  cos( angle ), 0.0, 0.0,
      0.0         ,  0.0         , 1.0, 0.0,
      0.0         ,  0.0         , 0.0, 1.0 );
}

void main()
{
  
  vec4 light_diffuse;
  vec4 light_ambient;
  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
  vec3 moonLightColor = vec3 (0.095, 0.095, 0.15) * moonlight + vec3 (0.005, 0.005, 0.005);
  
  moonLightColor = moonlight_perception (moonLightColor);
  
  
  //float yprime_alt;
  float yprime;
  float lightArg;
  float intensity;
  float vertex_alt;
  float scattering;
  
  // The ALS code assumes that units are in meters - e.g. model space vertices (gl_Vertex) are in meters
  
  // WS30 model space, Nov 21, 2021: 
  //   Coordinate axes are the same for geocentric, but not the origin.
  //           +z direction points from the Earth center to North pole.
  //           +x direction points from the Earth center to longitude = 0 on the equator.
  //           +y direction points from the Earth center to logntitude = East on the equator.
  //   Model space origin is at sea level. Units are in meters. 
  //   Each tile, for each LoD level, its own model origin
  //   modelOffset is the model origin relative to the Earth center. It is in a geocentric 
  //     space with the same axes, but with the Earth center as the origin. Units are in meters.


  vec4 pos = gl_Vertex;
  if (raise_vertex) 
  {
  pos.z+=0.1;
    gl_Position =  gl_ModelViewProjectionMatrix * pos;
  }
  else gl_Position = ftransform();


  // this code is copied from default.vert
  
  ecPosition = gl_ModelViewMatrix * gl_Vertex;
  //gl_Position = ftransform();
  gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
  normal = gl_NormalMatrix * gl_Normal;

  // Required for water calculations
  lightdir = normalize(vec3(fg_zUpTransform * vec4(gl_ModelViewMatrixInverse * gl_LightSource[0].position)));
  waterTex4 = vec4( ecPosition.xzy, 0.0 );

  vec4 t1 = vec4(0.0, osg_SimulationTime * 0.005217, 0.0, 0.0);
  vec4 t2 = vec4(0.0, osg_SimulationTime * -0.0012, 0.0, 0.0);

  float Angle;

  float windFactor = sqrt(WindE * WindE + WindN * WindN) * 0.05;
  if (WindN == 0.0 && WindE == 0.0) {
      Angle = 0.0;
  } else {
      Angle = atan(-WindN, WindE) - atan(1.0);
  }

  mat4 RotationMatrix;
  createRotationMatrix(Angle, RotationMatrix);
  waterTex1 = gl_MultiTexCoord0 * RotationMatrix - t1 * windFactor;
  waterTex2 = gl_MultiTexCoord0 * RotationMatrix - t2 * windFactor;


///////////////////////////////////////////
// Test phase code:
//
  // Coords for ground textures 
  // Due to precision issues coordinates should restart (i.e. go to zero) every 5000m or so.
  const float restart_dist_m = 5000.0;
  
  // Model position
  vec3 mp = gl_Vertex.xyz;

  // Temporary approximation to get shaders to compile:
  ground_tex_coord = gl_TexCoord[0].st;

//
// End test phase code
///////////////////////////////////////////

  // WS2:
  // first current altitude of eye position in model space
  // vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
  // and relative position to vector
  //relPos = gl_Vertex.xyz - ep.xyz;
  
  
  // Transform for frame of reference where:
  //   +z is in the up direction.
  //   The orientation of x and y axes are unknown currently.
  //   The origin is at the same position as the model space origin.
  //   The units are in meters.
  mat4 viewSpaceToZUpSpace = fg_zUpTransform * gl_ModelViewMatrixInverse;
  
  vec4 vertexZUp = fg_zUpTransform * gl_Vertex;

  // WS2: rawPos = gl_Vertex.xy;
  rawPos = vertexZUp.xy;

  // WS2: worldPos = (osg_ViewMatrixInverse *gl_ModelViewMatrix * gl_Vertex).xyz;
  worldPos = fg_modelOffset + gl_Vertex.xyz;
  
  steepness = abs(dot(normalize(vec3(fg_zUpTransform * vec4(gl_Normal,1.0))), vec3 (0.0, 0.0, 1.0)));
  // Gradient direction used for small scale noise. In the same space as noise coords, rawpos.xy.
  grad_dir = normalize(gl_Normal.xy);
  
  // here start computations for the haze layer
  // we need several geometrical quantities
  
  
  // Eye position in z up space
  vec4 epZUp = viewSpaceToZUpSpace * vec4(0.0,0.0,0.0,1.0);
  
  // Position of vertex relative to the eye position in z up space
  vec3 relPosZUp = (vertexZUp - epZUp).xyz;
  
  
  // first current altitude of eye position in model space
  vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
  
  
  // Eye position in model space
  vec4 epMS = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
  
  /*
  //old:  and relative position to vector. This is also used for cloud shadow positioning.
  relPosOld = (fg_zUpTransform * vec4(gl_Vertex - ep)).xyz;
  if (any(notEqual(relPosOld, relPosZUp))) relPos = vec3(1000000.0);
  */

  relPos = relPosZUp;
  vertVec = relPosZUp;
  
  ecViewdir = (gl_ModelViewMatrix * (epMS - gl_Vertex)).xyz;	
  // unfortunately, we need the distance in the vertex shader, although the more accurate version
  // is later computed in the fragment shader again
  float dist = length(relPos);
  
  // Altitude of the vertex above mean sea level in meters.
  //   This is equal to vertexZUp.z as the model space origin is at mean sea level. 
  //   Somehow zero leads to artefacts, so ensure it is at least 100m.
  //WS2: vertex_alt = max(gl_Vertex.z,100.0);
  vertex_alt = max(vertexZUp.z,100.0);
  scattering = ground_scattering + (1.0 - ground_scattering) * smoothstep(hazeLayerAltitude -100.0, hazeLayerAltitude + 100.0, vertex_alt); 
  

  // branch dependent on daytime

if (terminator < 1000000.0) // the full, sunrise and sunset computation
{
    // establish coordinates relative to sun position
    
    vec3 lightFull = (gl_ModelViewMatrixInverse * gl_LightSource[0].position).xyz;
    vec3 lightHorizon = normalize(vec3(lightFull.x,lightFull.y, 0.0));
    
    // yprime is the distance of the vertex into sun direction
    yprime = -dot(relPos, lightHorizon);
    
    // this gets an altitude correction, higher terrain gets to see the sun earlier
    yprime_alt = yprime - sqrt(2.0 * EarthRadius * vertex_alt);
    
    // two times terminator width governs how quickly light fades into shadow
    // now the light-dimming factor
    earthShade = 0.6 * (1.0 - smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt)) + 0.4;
    
    // parametrized version of the Flightgear ground lighting function
    lightArg = (terminator-yprime_alt)/100000.0;

    // directional scattering for low sun
    if (lightArg < 10.0)
      {mie_angle = (0.5 *  dot(normalize(relPos), normalize(lightFull)) ) + 0.5;}
    else 
      {mie_angle = 1.0;}


    light_diffuse.b = light_func(lightArg, 1.330e-05, 0.264, 3.827, 1.08e-05, 1.0);
    light_diffuse.g = light_func(lightArg, 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
    light_diffuse.r = light_func(lightArg, 8.305e-06, 0.161, 3.827, 3.04e-05, 1.0);
    light_diffuse.a = 1.0;
    light_diffuse = light_diffuse * scattering;

    //light_ambient.b = light_func(lightArg, 0.000506, 0.131, -3.315, 0.000457, 0.5);
    //light_ambient.g = light_func(lightArg, 2.264e-05, 0.134, 0.967, 3.66e-05, 0.4);
    light_ambient.r = light_func(lightArg, 0.236, 0.253, 1.073, 0.572, 0.33);
    light_ambient.g = light_ambient.r * 0.4/0.33; //light_func(lightArg, 0.236, 0.253, 1.073, 0.572, 0.4);
    light_ambient.b = light_ambient.r * 0.5/0.33; //light_func(lightArg, 0.236, 0.253, 1.073, 0.572, 0.5);
    light_ambient.a = 1.0;

    // Water specular calculations
    specular_light.b = light_func(lightArg, 1.330e-05, 0.264, 3.827, 1.08e-05, 1.0);
    specular_light.g = light_func(lightArg, 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
    specular_light.r = light_func(lightArg, 8.305e-06, 0.161, 3.827, 3.04e-05, 1.0);
    specular_light = max(specular_light * scattering, vec3 (0.05, 0.05, 0.05));
    intensity = length(specular_light.rgb);
    specular_light.rgb = intensity * normalize(mix(specular_light.rgb,  shadedFogColor, 1.0 -smoothstep(0.1, 0.6,ground_scattering) ));
    specular_light.rgb = intensity * normalize(mix(specular_light.rgb,  shadedFogColor, 1.0 -smoothstep(0.5, 0.7,earthShade)));



    // correct ambient light intensity and hue before sunrise
    if (earthShade < 0.5)
    {
      intensity = length(light_ambient.rgb); 
      light_ambient.rgb = intensity * normalize(mix(light_ambient.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.8,earthShade) ));
      light_ambient.rgb = light_ambient.rgb +   moonLightColor *  (1.0 - smoothstep(0.4, 0.5, earthShade));
      
      intensity = length(light_diffuse.rgb); 
      light_diffuse.rgb = intensity * normalize(mix(light_diffuse.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.7,earthShade) ));
    }

    // directional scattering for low sun
    if (lightArg < 10.0) {
        mie_angle = (0.5 *  dot(normalize(relPos), lightdir) ) + 0.5;
    } else {
        mie_angle = 1.0;
    }


    // the haze gets the light at the altitude of the haze top if the vertex in view is below
    // but the light at the vertex if the vertex is above
    
    vertex_alt = max(vertex_alt,hazeLayerAltitude);

    if (vertex_alt > hazeLayerAltitude)
    {
      if (dist > 0.8 * avisibility)
      {
        vertex_alt = mix(vertex_alt, hazeLayerAltitude, smoothstep(0.8*avisibility, avisibility, dist));
        yprime_alt = yprime -sqrt(2.0 * EarthRadius * vertex_alt);
      }
    }
    else
    {
      vertex_alt = hazeLayerAltitude;
      yprime_alt = yprime -sqrt(2.0 * EarthRadius * vertex_alt);
    }
  
  } // End if (terminator < 1000000.0)
  else // the faster, full-day version without lightfields
  {
    //vertex_alt = max(gl_Vertex.z,100.0);
    
    earthShade = 1.0;
    mie_angle = 1.0;
    
    if (terminator > 3000000.0)
    {
      light_diffuse = vec4 (1.0, 1.0, 1.0, 1.0);
      light_ambient = vec4 (0.33, 0.4, 0.5, 1.0);
      specular_light = vec3 (1.0, 1.0, 1.0);
    }
    else
    {
      lightArg = (terminator/100000.0 - 10.0)/20.0;
      light_diffuse.b = 0.78  + lightArg * 0.21;
      light_diffuse.g = 0.907 + lightArg * 0.091;
      light_diffuse.r = 0.904 + lightArg * 0.092;
      light_diffuse.a = 1.0;
    
      //light_ambient.b = 0.41 + lightArg * 0.08;
      //light_ambient.g = 0.333 + lightArg * 0.06;
      light_ambient.r = 0.316 + lightArg * 0.016;
      light_ambient.g = light_ambient.r * 0.4/0.33; 
      light_ambient.b = light_ambient.r * 0.5/0.33;
      light_ambient.a = 1.0;

      specular_light.b = 0.78  + lightArg * 0.21;
      specular_light.g = 0.907 + lightArg * 0.091;
      specular_light.r = 0.904 + lightArg * 0.092;
    }

    light_diffuse = light_diffuse * scattering;
    specular_light = specular_light * scattering;

    yprime_alt = -sqrt(2.0 * EarthRadius * hazeLayerAltitude);
    
  } //End the faster, full-day version without lightfields
 

  // a sky/earth irradiation map model - the sky creates much more diffuse radiation than the ground, so
  // steep faces end up shaded more
  
  light_ambient = light_ambient * ((1.0+steepness)/2.0 * 1.2 + (1.0-steepness)/2.0 * 0.2);

  // deeper shadows when there is lots of direct light

  float shade_depth =  1.0 * smoothstep (0.6,0.95,ground_scattering) * (1.0-smoothstep(0.1,0.5,overcast)) * smoothstep(0.4,1.5,earthShade);
  
  light_ambient.rgb = light_ambient.rgb * (1.0 - shade_depth);
  light_diffuse.rgb = light_diffuse.rgb * (1.0 + 1.2 * shade_depth);
  specular_light.rgb *= (1.0 + 1.2 * shade_depth);
  
  if (use_IR_vision)
  {
    light_ambient.rgb = max(light_ambient.rgb, vec3 (0.5, 0.5, 0.5));
  }


  // default lighting based on texture and material using the light we have just computed
  
  light_diffuse_comp = light_diffuse;
  //Testing phase code: ambient colours are not sent to fragement shader yet. 
  //  They are all default except for water/ocean etc. currently
  //  Emission is all set to the default of vec4(0.0, 0.0, 0.0, 1.0)
  //To do: Fix this once ambient colour becomes available in the fragment shaders.
  //const vec4 ambient_color = vec4(0.2, 0.2, 0.2, 1.0);
  const vec4 ambient_color = vec4(1.0);
  vec4 constant_term = ambient_color * (gl_LightModel.ambient +  light_ambient);
  
  light_diffuse_comp.a = yprime_alt;
  gl_FrontColor.rgb = constant_term.rgb;  // gl_FrontColor.a = 1.0;
  gl_BackColor.rgb = constant_term.rgb; // gl_BackColor.a = 0.0;
  gl_FrontColor.a = mie_angle;
  gl_BackColor.a = mie_angle;
  
  setupShadows(ecPosition);
}




