// -*-C++-*-
//
// Chris Ringeval (November 2021)
//

#version 120


varying vec3 eye2VertInEyeSpace;
varying vec3 eye2ZenithInEyeSpace;
varying vec3 eye2MoonInEyeSpace;

uniform sampler2D milkyway;

uniform float moonlight;
uniform float mudarksky;
uniform float altitude;
uniform float atmosphere_top;

uniform float fg_ZenithSkyBrightness;
uniform float mugxybulge;


// conversion factor to recover moon logI in lux
const float max_loglux = -0.504030345621;
const float min_loglux = -4.399646345620;
// conversion factor to recover moon logI in footcandle
const float luxtofootcandle = -1.0319696543787917;

// the log10 of Mie + Rayleight scattering function at minimum,
// i.e., for a Moon-Sky distance of 90 degrees
const float logf90 = 5.399285;

//extinction coefficient at Maunea Kea (2800m asl), in mag/airmass
const float k2800 = 0.172;


// cos(3pi/5), at asl 0m, any light source < -18 degrees above the horizon does
// not light-up atmosphere -> zenital angle > 108 degrees.
const float cosUnvisible = -0.309016994374947;


// D65 white multiplied by rhodopic response function and converted
// to linear sRGB is [-0.321, 0.656, 0.455], i.e. out of gammut. We
// desaturate along red to mimic night vision color blindness
// (see https://github.com/eatdust/spectroll)
const vec4 nightColor = vec4(0.0,0.977,0.776,1.0);



vec3 filter_combined (in vec3 color) ;


float log10(in float x){
  return 0.434294481903252*log(x);
}


//Rayleight + Mie scattering in unit of the minimal scattering at
//90 degrees (const f90)
float scattering_angular_dependency(in float cosMoonSep) {

  float fR = 0.913514*(1.06 + cosMoonSep*cosMoonSep);

  float moonSepRad = acos(cosMoonSep);

  float fM = 5.63268*pow(10.0,-moonSepRad*1.432394);

  return fR + fM;
  
}

float airmass_angular_dependency(in float sineZenithDistanceSquare) {

  return 1.0/sqrt(1.0 - 0.96*sineZenithDistanceSquare);

}


//log10 of the moon illuminance in footcandles
float log10_moon_illuminance_fc(in float Inorm){

  return (max_loglux-min_loglux)*(Inorm-1.0) + max_loglux + luxtofootcandle ;
}


//in mag/arcsec^2 from flux in nano Lambert
float magnitude_from_lognL(in float logBnL){
  return 26.3313 - 2.5*logBnL;
}


void main()
{
  

  //unit vectors
  vec3 uViewDir = normalize(eye2VertInEyeSpace);
  vec3 uZenithDir = normalize(eye2ZenithInEyeSpace);
  vec3 uMoonDir = normalize(eye2MoonInEyeSpace);


  // the intrinsic sky brightness without the Moon at
  // zenith set in simgear and propagated as uniform
  
  float muzenithsky = fg_ZenithSkyBrightness;


  vec4 fragColor;

    

  // the galaxy is visible only if
  if (muzenithsky >= mugxybulge) {

    

    // texture look-up
    vec4 texel = texture2D(milkyway, gl_TexCoord[0].st);
  

  
    float cosZenithView = max(dot(uZenithDir,uViewDir),0.0);

    float sineZenithDist2 = 1.0 - pow(cosZenithView,2);

    float Xview = airmass_angular_dependency(sineZenithDist2);
    
  
    float k = k2800 * max(0.0,(atmosphere_top - altitude)/(atmosphere_top - 2800.0));


  
    // add angular dependence from scattering within the atmosphere
  
    float musky = muzenithsky  + k*(Xview-1.0);

    // main effect: airglow coming from the van Rhijn layer (height 130km)
    //
    // https://ui.adsabs.harvard.edu/abs/1986PASP...98..364G/abstract
    //
    // We smoothstep airglow to zero while approaching 130km of altitude

    musky = musky - 2.5*log10(0.4+0.6*Xview) * (1.0 - smoothstep(0.0,130000.0,altitude));


    
    // Moon illumination of the atmosphere, we use the same model as in
    // simgear (see moonpos.cxx), based on Publ. Astron. Soc. Pacif.
    // 103(667), 1033-1039 (DOI: http://dx.doi.org/10.1086/132921).
    //
    // https://ui.adsabs.harvard.edu/abs/1991PASP..103.1033K/abstract
    //
    // The altitude damping effect is encoded in k and the moon
    // scattering smoothly disappears with altitude as k->0. Only smoothstep added to
    // smooth the moon rising effects

    float cosZenithMoon = dot(uZenithDir,uMoonDir);
    float dmumoon = 0.0;
    
    // Include values under the horizon to smooth the Moon rising jumps effect
    if (cosZenithMoon >= cosUnvisible) {
        
      //however, we use the math only with sane input: cosZenithMoon >= 0
      float sineZenithMoon2 = 1.0 - pow(max(cosZenithMoon,0.0),2.0);
    
      float Xmoon = airmass_angular_dependency(sineZenithMoon2);      

      float cosMoonView = dot(uMoonDir,uViewDir);
      
      float moon_logI = log10_moon_illuminance_fc(moonlight);
            
      // log10(Bmoon) with Bmoon in nanoLambert
      float logBnL = logf90 + log10(scattering_angular_dependency(cosMoonView)) \
	+ moon_logI - 0.4*k*Xmoon + log10(1.0-pow(10.0,-0.4*k*Xview));
    
      // sky brightness from the moon in mag/arcsec^2
      float mumoon = magnitude_from_lognL(logBnL);
  
      //relative flux w.r.t background
      float Brel = pow(10.0,0.4*(musky-mumoon));

      // artificial smoothing for the moon between -18 degrees and 0
      Brel = Brel*smoothstep(cosUnvisible,0.0,cosZenithMoon);

      dmumoon = - 2.5*log10(1.0 + Brel);
      
            
    }

    // final angle dependent sky brightness
    musky = musky + dmumoon;
    
    // we put the damping in the colors as to keep alpha channel to 1
    // for the ALS filters to not being affected
  
    fragColor.rgb = texel.rgb * nightColor.rgb * (musky-mugxybulge)/musky;
    fragColor.a = 1.0;

    //For debugging and testing, uncomment. The red shows sky low surface brightness
    //fragColor.r = 8*(musky-mugxybulge)/musky;
    
  }
  
  else {
    // galaxy is invisible, too much sky brightness, color the night sphere is black

    fragColor = vec4(0.0,0.0,0.0,1.0);

  }


  
  fragColor.rgb = filter_combined(fragColor.rgb);
  
  gl_FragColor = clamp(fragColor,0.0,1.0);

}
