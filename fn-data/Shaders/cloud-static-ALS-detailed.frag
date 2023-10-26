// -*-C++-*-
#version 120

uniform sampler2D baseTexture;

uniform float ring_factor;
uniform float rainbow_factor;

varying float fogFactor;
varying float mie_frag;
varying float eShade;

varying vec3 hazeColor;

vec3 filter_combined (in vec3 color) ;

void main(void)
{
      vec4 base = texture2D( baseTexture, gl_TexCoord[0].st);
	  
	  float fwd_enhancement = smoothstep(0.8, 1.0, mie_frag) * eShade;
	  float light_intensity = length(gl_Color.rgb)/1.76;

	  
	  //22 deg ring
	  
	  float halo_ring_enhancement =  smoothstep (0.88, 0.927, mie_frag) * (1.0 - smoothstep(0.927, 0.94, mie_frag)) * eShade * 1.5 * ring_factor;

	  
	  float halo_ring_enhancement_b =  smoothstep (0.88, 0.90, mie_frag) * (1.0 - smoothstep(0.90, 0.92, mie_frag)) * eShade * ring_factor;
	  float halo_ring_enhancement_r =  smoothstep (0.91, 0.93, mie_frag) * (1.0 - smoothstep(0.93, 0.955, mie_frag)) * eShade * ring_factor;
	  
	  
      vec4 finalColor = base * gl_Color;
	  
	  float reduction = 0.16 * light_intensity * rainbow_factor;
	  
	  finalColor.g *= (1.0 - reduction * halo_ring_enhancement_r);
	  finalColor.b *= (1.0 - reduction * halo_ring_enhancement_r);

	  finalColor.r *= (1.0 - reduction * halo_ring_enhancement_b);
	  finalColor.g *= (1.0 - reduction * halo_ring_enhancement_b);

	  fwd_enhancement *=(1.0-smoothstep(0.8, 1.0, light_intensity));
	  finalColor.rgb *=  (1.0 + fwd_enhancement) * (1.0 + 0.5 * halo_ring_enhancement * (1.0-smoothstep(0.8, 1.0, light_intensity))) ;
	  finalColor.a *= (1.0 + 0.5 * halo_ring_enhancement);
	  

	  
	  finalColor.rgb = clamp(finalColor.rgb, 0.0, 1.0);
	  finalColor.a = clamp(finalColor.a, 0.0, 1.0);
	  
      vec4 fragColor = vec4 (mix(hazeColor, finalColor.rgb, fogFactor ), mix(0.0, finalColor.a, 1.0 - 0.5 * (1.0 - fogFactor)));

   
      fragColor.rgb = filter_combined(fragColor.rgb);
	  //fragColor.rgb = vec3 (1.0, 0.0, 0.0);
      gl_FragColor = fragColor;
}
