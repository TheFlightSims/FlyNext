#version 120

uniform sampler2D baseTexture;
uniform float scattering;

varying float fogFactor;
varying float mie_frag;
varying float mie_frag_mod;
varying float z_pos;
varying float bottom_shade;

varying vec3 internal_pos;
varying vec3 hazeColor;

vec3 filter_combined (in vec3 color) ;

void main(void)
{
      vec4 base = texture2D( baseTexture, gl_TexCoord[0].st);
      if (base.a < 0.02)
        discard;
		
      float mie_factor = 0.0;
      float geo_factor = 1.0;

	  float mie_sign = 1.0;
	  if (mie_frag < 0.0) {mie_sign = -1.0;}

	  if (mie_sign > 0.0)
		{mie_factor = smoothstep(0.8, 1.0, mie_frag);}
	  else
 		{mie_factor = -1.0 * (1.0 - smoothstep(-1.0, -0.8, mie_frag));}

	      mie_factor *= mie_frag_mod;

	//  suppress effect in cloud center

	  float z_bias = 0.2 * (1.0 - smoothstep(2.0, 3.0, z_pos)); 
	
	  geo_factor *= smoothstep(-0.9 - z_bias, -0.4 - z_bias, internal_pos.x) * (1.0 -smoothstep(0.4 + z_bias, 0.9 + z_bias, internal_pos.x));
	  geo_factor *= smoothstep(-0.9 - z_bias, -0.4 - z_bias, internal_pos.y) * (1.0 -smoothstep(0.4 + z_bias, 0.9 + z_bias, internal_pos.y));
	  geo_factor *= smoothstep(0, 0.3, internal_pos.z) * (1.0 - smoothstep(0.5, 1.2, internal_pos.z));

	 if (mie_sign > 0.0)
		{
		mie_factor *=(1.0 -geo_factor);
		}

		float transparency = smoothstep(0.0, 0.7, base.a);
		float opacity = smoothstep(0.7, 1.0, base.a);

		float inverse_mie = 0.0;
			  
		if ((opacity == 0.0) && (mie_sign > 0.0)) // Mie forward scattering enhancing light
				{mie_factor *= (1.0 -  pow(transparency, 2.0));}
		else if ((opacity == 0.0) && (mie_sign < 0.0))	// Mie forward scattering reducing reflected light
				{
				inverse_mie = (1.0 -  pow(transparency, 2.0)) * smoothstep(0.65, 0.8, scattering);
				inverse_mie *= (1.0 - smoothstep(-1.0, -0.5, mie_frag));
				}
		else if (mie_sign > 0.0) // bulk light absorption
				{mie_factor *= - 4.0 * pow(opacity, 2.0);}
		

	// darken the bulk of the away-facing cloud

	float bulk_shade_factor = (1.0 - 0.6 * geo_factor * smoothstep(0.5, 1.0, mie_frag));
    bulk_shade_factor -= 0.3 * smoothstep(0.5, 1.0, mie_frag) * (1.0 - mie_frag_mod) * (1.0 - smoothstep(0.4, 0.5, bottom_shade));
		
	  
      float mie_enhancement = 1.0 + clamp(mie_factor, 0.0, 1.0);
      mie_enhancement = mie_enhancement * bulk_shade_factor;	  
	  
	 vec4 finalColor = base * gl_Color;
	 finalColor.rgb *= mie_enhancement * (1.0 - 0.4 * inverse_mie);
	 finalColor.rgb = max(finalColor.rgb, gl_Color.rgb * 1.2 * bottom_shade);
	
      finalColor.rgb = mix(hazeColor, finalColor.rgb, fogFactor ); 
      finalColor.rgb = filter_combined(finalColor.rgb);

	  
      gl_FragColor.rgb = finalColor.rgb;
      gl_FragColor.a = mix(0.0, finalColor.a, 1.0 - 0.5 * (1.0 - fogFactor));
}
