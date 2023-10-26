#version 120

uniform sampler2D baseTexture;
varying float fogFactor;

vec3 filter_combined (in vec3 color) ;

void main(void)
{
      vec4 base = texture2D( baseTexture, gl_TexCoord[0].st);
      vec4 finalColor = base * gl_Color;
      gl_FragColor.rgb = mix(gl_Fog.color.rgb, finalColor.rgb, fogFactor );
      gl_FragColor.a = mix(0.0, finalColor.a, fogFactor);
}
