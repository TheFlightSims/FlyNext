#version 120

uniform sampler2D baseTexture;
varying float fogFactor;

varying vec3 hazeColor;

vec3 filter_combined (in vec3 color) ;

void main(void)
{
      vec4 base = texture2D( baseTexture, gl_TexCoord[0].st);
      vec4 finalColor = base * gl_Color;

      vec4 fragColor = vec4 (mix(hazeColor, finalColor.rgb, fogFactor ), mix(0.0, finalColor.a, 1.0 - 0.5 * (1.0 - fogFactor)));

   
      fragColor.rgb = filter_combined(fragColor.rgb);
      gl_FragColor = fragColor;
}
