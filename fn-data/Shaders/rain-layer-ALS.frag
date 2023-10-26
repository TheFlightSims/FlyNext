#version 120

uniform sampler2D baseTexture;
varying float fogFactor;
varying vec3 hazeColor;
varying vec3 relVector;

vec3 filter_combined (in vec3 color) ;

uniform bool is_lightning;

vec3 rainbow (in float index)
{

float red = max(1.0 - 2.0 * index,0.0);
float green;

if (index < 0.5)
  {green = 2.0 * index;}
else 
  {green = 1.0 - 2.0 *(index - 0.5);}



float blue = max(2.0 * (index - 0.5), 0.0);

red *= 1.3;
green *=0.6;

return vec3 (red, green, blue) * hazeColor;
}

void main(void)
{
      vec4 base = texture2D( baseTexture, gl_TexCoord[0].st);
      vec4 finalColor = base * gl_Color;

      vec4 fragColor;     


      if (is_lightning==false)
      	{
	vec3 nView =  normalize(relVector);
        vec3 lightFull = normalize((gl_ModelViewMatrixInverse * gl_LightSource[0].position).xyz);

        float calpha = dot(-lightFull, nView);

        float rainbow_shape = smoothstep(0.743 -0.03, 0.743, calpha) * (1.0 - smoothstep(0.743, 0.743+0.03, calpha));
 
        float color_index = clamp((calpha - 0.713)/ 0.06,0.0,1.0);

        vec3 rainbow_color = rainbow(color_index);
        finalColor.rgb = mix(finalColor.rgb, rainbow_color, 0.5* rainbow_shape); 


	fragColor.rgb = mix(hazeColor, finalColor.rgb, fogFactor );
	}
      else 
	{fragColor.rgb = finalColor.rgb;}
      fragColor.a = mix(0.0, finalColor.a, fogFactor);

      fragColor.rgb = filter_combined(fragColor.rgb); 

	gl_FragColor = fragColor;

}
