// SPDX-FileCopyrightText: (C) 2022 Stuart Buchanan stuart13@gmail.com
// SPDX-License-Identifier: GPL-2.0-or-later

// Helper functions for WS30 water implementation, heavily based on the
// water-ALS-base.frag and waterr_ALS-high.frag

#version 130
#extension GL_EXT_texture_array : enable

// Hardcoded indexes into the texture atlas
const int ATLAS_INDEX_WATER                 = 0;
const int ATLAS_INDEX_WATER_REFLECTION      = 1;
const int ATLAS_INDEX_WAVES_VERT10_NM       = 2;
const int ATLAS_INDEX_WATER_SINE_NMAP       = 3;
const int ATLAS_INDEX_WATER_REFLECTION_GREY = 4;
const int ATLAS_INDEX_SEA_FOAM              = 5;
const int ATLAS_INDEX_PERLIN_NOISE_NM       = 6;
const int ATLAS_INDEX_OCEAN_DEPTH           = 7;
const int ATLAS_INDEX_GLOBAL_COLORS         = 8;
const int ATLAS_INDEX_PACKICE_OVERLAY       = 9;

// WS30 uniforms
uniform sampler2DArray textureArray;
uniform float ground_scattering;
uniform float overcast;
uniform float fg_tileWidth;
uniform float fg_tileHeight;

// Water.eff uniforms
uniform float sea_r;
uniform float sea_g;
uniform float sea_b;
uniform float osg_SimulationTime;
uniform float WindN;
uniform float WindE;
uniform float WaveFreq;
uniform float WaveAmp;
uniform float WaveSharp;
uniform float WaveAngle;
uniform float WaveFactor;
uniform float saturation;

// WS30 varying
varying vec3 relPos;

// Water.eff varying
varying float earthShade;
varying vec3 lightdir;
varying vec4 waterTex1;
varying vec4 waterTex2;
varying vec4 waterTex4;
varying vec3 specular_light;

//WS3.0 varying
varying float steepness;


/////// functions /////////

float getShadowing();
vec3 getClusteredLightsContribution(vec3 p, vec3 n, vec3 texel);

void rotationmatrix(in float angle, out mat4 rotmat)
{
  rotmat = mat4( cos( angle ), -sin( angle ), 0.0, 0.0,
  sin( angle ),  cos( angle ), 0.0, 0.0,
  0.0         ,  0.0         , 1.0, 0.0,
  0.0         ,  0.0         , 0.0, 1.0 );
}

// wave functions ///////////////////////
struct Wave {
  float freq;  // 2*PI / wavelength
  float amp;   // amplitude
  float phase; // speed * 2*PI / wavelength
  vec2 dir;
};

Wave wave0 = Wave(1.0, 1.0, 0.5, vec2(0.97, 0.25));
Wave wave1 = Wave(2.0, 0.5, 1.3, vec2(0.97, -0.25));
Wave wave2 = Wave(1.0, 1.0, 0.6, vec2(0.95, -0.3));
Wave wave3 = Wave(2.0, 0.5, 1.4, vec2(0.99, 0.1));

float evaluateWave(in Wave w, in vec2 pos, in float t) {
  return w.amp * sin( dot(w.dir, pos) * w.freq + t * w.phase);
}

// derivative of wave function
float evaluateWaveDeriv(in Wave w, in vec2 pos, in float t) {
  return w.freq * w.amp * cos( dot(w.dir, pos)*w.freq + t*w.phase);
}

// sharp wave functions
float evaluateWaveSharp(in Wave w, in vec2 pos, in float t, in float k) {
  return w.amp * pow(sin( dot(w.dir, pos)*w.freq + t*w.phase)* 0.5 + 0.5 , k);
}

float evaluateWaveDerivSharp(in Wave w, in vec2 pos, in float t, in float k) {
  return k*w.freq*w.amp * pow(sin( dot(w.dir, pos)*w.freq + t*w.phase)* 0.5 + 0.5 , k - 1) * cos( dot(w.dir, pos)*w.freq + t*w.phase);
}

void sumWaves(in float angle, in float dangle, in float windScale, in float factor, out float ddx, float ddy) {
  mat4 RotationMatrix;
  float deriv;
  vec4 P = waterTex1 * 1024;

  rotationmatrix(radians(angle + dangle * windScale + 0.6 * sin(P.x * factor)), RotationMatrix);
  P *= RotationMatrix;

  P.y += evaluateWave(wave0, P.xz, osg_SimulationTime);
  deriv = evaluateWaveDeriv(wave0, P.xz, osg_SimulationTime );
  ddx = deriv * wave0.dir.x;
  ddy = deriv * wave0.dir.y;

  //P.y += evaluateWave(wave1, P.xz, osg_SimulationTime);
  //deriv = evaluateWaveDeriv(wave1, P.xz, osg_SimulationTime);
  //ddx += deriv * wave1.dir.x;
  //ddy += deriv * wave1.dir.y;

  P.y += evaluateWaveSharp(wave2, P.xz, osg_SimulationTime, WaveSharp);
  deriv = evaluateWaveDerivSharp(wave2, P.xz, osg_SimulationTime, WaveSharp);
  ddx += deriv * wave2.dir.x;
  ddy += deriv * wave2.dir.y;

  //P.y += evaluateWaveSharp(wave3, P.xz, osg_SimulationTime, WaveSharp);
  //deriv = evaluateWaveDerivSharp(wave3, P.xz, osg_SimulationTime, WaveSharp);
  //ddx += deriv * wave3.dir.x;
  //ddy += deriv * wave3.dir.y;
}

vec4 generateWaterTexel()
{
  vec4 texel;
  float dist = length(relPos);
  float tileScale = 1 / (fg_tileHeight + fg_tileWidth) / 2.0;

  vec4 sca = vec4(0.005, 0.005, 0.005, 0.005) * tileScale;
  vec4 sca2 = vec4(0.02, 0.02, 0.02, 0.02) * tileScale;
  vec4 tscale = vec4(0.25, 0.25, 0.25, 0.25) / 10000.0 * tileScale;

  mat4 RotationMatrix;

  // compute direction to viewer
  vec3 E = normalize(-relPos);

  // compute direction to light source
  vec3 L = normalize(lightdir);

  // half vector
  vec3 Hv = normalize(L + E);

  vec3 Normal = vec3 (0.0, 0.0, 1.0);

  const float water_shininess = 240.0;

  float windEffect = sqrt( WindE*WindE + WindN*WindN ) * 0.6; //wind speed in kt
  float windScale =  15.0/(3.0 + windEffect);                 //wave scale
  float windEffect_low = 0.3 + 0.7 * smoothstep(0.0, 5.0, windEffect);    //low windspeed wave filter
  float waveRoughness = 0.01 + smoothstep(0.0, 40.0, windEffect);         //wave roughness filter

  float mixFactor = 0.2 + 0.02 * smoothstep(0.0, 50.0, windEffect);
  mixFactor = clamp(mixFactor, 0.3, 0.8);

  // there's no need to do wave patterns or foam for pixels which are so far away that we can't actually see them
  // we only need detail in the near zone or where the sun reflection is

  int detail_flag;
  if ((dist > 15000.0) && (dot(normalize(vec3 (lightdir.x, lightdir.y, 0.0) ), normalize(relPos)) < 0.7 ))  {detail_flag = 0;} 
  else {detail_flag = 1;}

  // sine waves
  float ddx, ddx1, ddx2, ddx3, ddy, ddy1, ddy2, ddy3;
  float angle;

  ddx = 0.0, ddy = 0.0;
  ddx1 = 0.0, ddy1 = 0.0;
  ddx2 = 0.0, ddy2 = 0.0;
  ddx3 = 0.0, ddy3 = 0.0;

  if (detail_flag == 1)
  {
    angle = 0.0;

    wave0.freq = WaveFreq ;
    wave0.amp = WaveAmp;
    wave0.dir =  vec2 (0.0, 1.0); //vec2(cos(radians(angle)), sin(radians(angle)));

    angle -= 45;
    wave1.freq = WaveFreq * 2.0 ;
    wave1.amp = WaveAmp * 1.25;
    wave1.dir =  vec2(0.70710, -0.7071); //vec2(cos(radians(angle)), sin(radians(angle)));

    angle += 30;
    wave2.freq = WaveFreq * 3.5;
    wave2.amp = WaveAmp * 0.75;
    wave2.dir =  vec2(0.96592, -0.2588);// vec2(cos(radians(angle)), sin(radians(angle)));

    angle -= 50;
    wave3.freq = WaveFreq * 3.0 ;
    wave3.amp = WaveAmp * 0.75;
    wave3.dir =  vec2(0.42261, -0.9063); //vec2(cos(radians(angle)), sin(radians(angle)));

    // sum waves
    sumWaves(WaveAngle, -1.5, windScale, WaveFactor, ddx, ddy);
    sumWaves(WaveAngle, 1.5, windScale, WaveFactor, ddx1, ddy1);

    //reset the waves
    angle = 0.0;
    float waveamp = WaveAmp * 0.75;

    wave0.freq = WaveFreq ;
    wave0.amp = waveamp;
    wave0.dir =  vec2 (0.0, 1.0); //vec2(cos(radians(angle)), sin(radians(angle)));

    angle -= 20;
    wave1.freq = WaveFreq * 2.0 ;
    wave1.amp = waveamp * 1.25;
    wave1.dir =  vec2(0.93969, -0.34202);// vec2(cos(radians(angle)), sin(radians(angle)));

    angle += 35;
    wave2.freq = WaveFreq * 3.5;
    wave2.amp = waveamp * 0.75;
    wave2.dir =  vec2(0.965925, 0.25881);  //vec2(cos(radians(angle)), sin(radians(angle)));

    angle -= 45;
    wave3.freq = WaveFreq * 3.0 ;
    wave3.amp = waveamp * 0.75;
    wave3.dir =  vec2(0.866025, -0.5); //vec2(cos(radians(angle)), sin(radians(angle)));
  }
  // end sine stuff

  //cover = 5.0 * smoothstep(0.6, 1.0, scattering);
  //cover = 5.0 * ground_scattering;

  vec4 viewt = normalize(waterTex4);
  vec2 st = vec2(waterTex2 * tscale * windScale);
  vec4 disdis = texture(textureArray, vec3(st, ATLAS_INDEX_WATER_SINE_NMAP)) * 2.0 - 1.0;

  vec4 vNorm;	

  //normalmaps
  st = vec2(waterTex1 + disdis * sca2) * windScale;
  vec4 nmap   = texture(textureArray, vec3(st, ATLAS_INDEX_WAVES_VERT10_NM)) * 2.0 - 1.0;
  vec4 nmap1  = texture(textureArray, vec3(st, ATLAS_INDEX_PERLIN_NOISE_NM)) * 2.0 - 1.0;

  rotationmatrix(radians(3.0 * sin(osg_SimulationTime * 0.0075)), RotationMatrix);
  st = vec2(waterTex2 * RotationMatrix * tscale) * windScale;
  nmap  += texture(textureArray, vec3(st, ATLAS_INDEX_WAVES_VERT10_NM)) * 2.0 - 1.0;

  nmap  *= windEffect_low;
  nmap1 *= windEffect_low;

  // mix water and noise, modulated by factor
  vNorm = normalize(mix(nmap, nmap1, mixFactor) * waveRoughness);
  vNorm.r += ddx + ddx1 + ddx2 + ddx3;

  //if (normalmap_dds > 0) {vNorm = -vNorm;}		//dds fix

  //load reflection
  vec4 refl ;
  refl.r = sea_r;
  refl.g = sea_g;
  refl.b = sea_b;
  refl.a = 1.0; 

  float intensity;
  // de-saturate for reduced light
  refl.rgb = mix(refl.rgb,  vec3 (0.248, 0.248, 0.248), 1.0 - smoothstep(0.1, 0.8, ground_scattering)); 

    // de-saturate light for overcast haze
  intensity = length(refl.rgb);
  refl.rgb = mix(refl.rgb,  intensity * vec3 (1.0, 1.0, 1.0), 0.5 * smoothstep(0.1, 0.9, overcast)); 	

  vec3 N;
  st = vec2(waterTex1 + disdis * sca2) * windScale;
  vec3 N0 = vec3(texture(textureArray, vec3(st, ATLAS_INDEX_WAVES_VERT10_NM))) * 2.0 - 1.0;
  st = vec2(waterTex1 + disdis * sca) * windScale;
  vec3 N1 = vec3(texture(textureArray, vec3(st, ATLAS_INDEX_PERLIN_NOISE_NM))) * 2.0 - 1.0;

  st = vec2(waterTex1 * tscale) * windScale;
  N0 += vec3(texture(textureArray, vec3(st, ATLAS_INDEX_WAVES_VERT10_NM))) * 2.0 - 1.0;
  N1 += vec3(texture(textureArray, vec3(st, ATLAS_INDEX_PERLIN_NOISE_NM))) * 2.0 - 1.0;
    
  rotationmatrix(radians(2.0 * sin(osg_SimulationTime * 0.005)), RotationMatrix);
  st = vec2(waterTex2 * RotationMatrix * (tscale + sca2)) * windScale;
  N0 += vec3(texture(textureArray, vec3(st, ATLAS_INDEX_WAVES_VERT10_NM))) * 2.0 - 1.0;
  N1 += vec3(texture(textureArray, vec3(st, ATLAS_INDEX_PERLIN_NOISE_NM))) * 2.0 - 1.0;

  rotationmatrix(radians(-4.0 * sin(osg_SimulationTime * 0.003)), RotationMatrix);
  st = vec2(waterTex1 * RotationMatrix + disdis * sca2) * windScale;
  N0 += vec3(texture(textureArray, vec3(st, ATLAS_INDEX_WAVES_VERT10_NM))) * 2.0 - 1.0;
  st = vec2(waterTex1 * RotationMatrix + disdis * sca) * windScale;
  N1 += vec3(texture(textureArray, vec3(st, ATLAS_INDEX_PERLIN_NOISE_NM))) * 2.0 - 1.0;
    
  N0 *= windEffect_low;
  N1 *= windEffect_low;

  N0.r += (ddx + ddx1 + ddx2 + ddx3);
  N0.g += (ddy + ddy1 + ddy2 + ddy3);

  N = normalize(mix(Normal + N0, Normal + N1, mixFactor) * waveRoughness);

  vec3 specular_color = vec3(specular_light * earthShade) * pow(max(0.0, dot(N, Hv)), water_shininess) * 6.0;

  // secondary reflection of sky irradiance
  vec3 ER = E - 2.0 * N * dot(E,N);
  float ctrefl = dot(vec3(0.0,0.0,1.0), -normalize(ER));
  //float fresnel = -0.5 + 8.0 * (1.0-smoothstep(0.0,0.4, dot(E,N)));
  float fresnel =  8.0 * (1.0-smoothstep(0.0,0.4, dot(E,N)));
  //specular_color += (ctrefl*ctrefl) * fresnel*  specular_light.rgb;

  specular_color += ((0.15*(1.0-ctrefl* ctrefl) * fresnel) - 0.3) * specular_light.rgb * earthShade;
  vec4 specular = vec4(specular_color, 0.5);

  specular = specular * saturation * 0.3  * earthShade  ;

  //calculate fresnel
  vec4 invfres = vec4( dot(vNorm, viewt) );
  vec4 fres = vec4(1.0) + invfres;
  refl *= fres;

  vec4 ambient_light;
  //intensity = length(specular_light.rgb);
  ambient_light.rgb = max(specular_light.rgb * earthShade, vec3(0.05, 0.05, 0.05));
  //ambient_light.rgb = max(intensity * normalize(vec3 (0.33, 0.4, 0.5)), vec3 (0.1,0.1,0.1));
  ambient_light.a = 1.0;

  // compute object shadow effect

  float shadowValue = getShadowing();
  specular = specular * shadowValue;
  refl = refl * (0.7 + 0.3 *shadowValue);


  texel = refl + specular * smoothstep(0.3, 0.6, ground_scattering);

  // For the clustered lighting function we use the simple up direction (Normal) to get an 
  // approximate lighting contribution, as the procedural normal map is done afterwards.
  //texel += vec4(getClusteredLightsContribution(ecPosition.xyz, Normal, vec3(1.0)), 0.0) * light_distance_fading(dist) * 2.0 * pow(max(0.0,dot(E,N)), water_shininess);

  if (dist < 10000.0)
  {
    float foamSlope = 0.10 + 0.1 * windScale;
    float waveSlope = N.g + min(50.0*(1.0 - steepness), 0.1);

    if ((steepness < 0.9999) || (windEffect >= 8.0) && (waveSlope >= foamSlope)) {
      //add foam
      st = vec2(waterTex2 * tscale) * 25.0;
      vec4 foam_texel = texture(textureArray, vec3(st, ATLAS_INDEX_SEA_FOAM) );

      texel = mix(texel, max(texel, texel + foam_texel), smoothstep(0.01, 0.50, waveSlope));
    }
  }

  texel *= ambient_light;

  return texel;
}
