// -*-C++-*-

// Ambient term comes in gl_Color.rgb.
#version 120

varying vec4 diffuse_term;
varying vec3 normal;
varying vec3 ecViewDir;
varying vec3 VTangent;

uniform float visibility;
uniform float air_pollution;
uniform float moonlight;
uniform float sun_angle;
uniform bool use_clouds;
uniform bool use_cloud_shadows;
uniform bool use_overlay;
uniform sampler2D texture;
uniform sampler2D shadowtex;
uniform sampler2D grain_texture;
uniform sampler2D normal_texture;

float Noise2D(in vec2 coord, in float wavelength);
vec3 filter_combined (in vec3 color) ;
vec3 moonlight_perception (in vec3 light);

void main()
{
    vec3 n;
    float NdotL, NdotHV;
    vec4 color = gl_Color;
    vec3 lightDir = normalize(gl_LightSource[0].position.xyz);

	vec3 halfVector = normalize(lightDir + normalize(ecViewDir));
    vec4 texel;
    vec4 shadowTexel;
    vec4 grainTexel;
    vec4 fragColor;
    vec4 specular = vec4(0.0);

    // If gl_Color.a == 0, this is a back-facing polygon and the
    // normal should be reversed.
    n = (2.0 * gl_Color.a - 1.0) * normal;
    n = normalize(n);
	
	float parallaxFactor = max(1.0 - dot(normalize(ecViewDir), n),0.0);

	vec3 VBinormal;
	VBinormal = normalize(cross(normal, VTangent));
	
	float xOffset1 = -1.0 * dot(ecViewDir, normalize(VTangent));
	float yOffset1 = -1.0 * dot(ecViewDir, VBinormal);
	
	vec2 grad_dir = normalize (vec2 (xOffset1, yOffset1));
	
    vec4 nmap  = texture2D(normal_texture, gl_TexCoord[0].st);
	

	

	float hmap = 1.0 - nmap.a;
	nmap  = texture2D(normal_texture, gl_TexCoord[0].st -  0.0005 * grad_dir * hmap * 2.0 * parallaxFactor);

	
	// nmap.rgb should not be normalized, it adversely modifies  N = 2 nmap - 1
	// nmap.rgb = normalize(nmap.rgb);
	//if (nmap.b < 0.0) {nmap.b = -nmap.b;}
		
	vec3 N = nmap.rgb * 2.0 - 1.0;
    N = normalize(N.x * normalize(VTangent) * 0.6 + N.y * VBinormal * 0.6 + N.z * n);

	
	float xOffset = -0.005 * dot(lightDir, normalize(VTangent));
	float yOffset = -0.005 * dot(lightDir, VBinormal);
	


	
     	if ((use_cloud_shadows)&&(use_clouds))
		{shadowTexel = texture2D(shadowtex, vec2(gl_TexCoord[0].s-xOffset, gl_TexCoord[0].t-yOffset));}
	else
		{shadowTexel = vec4 (0.0,0.0,0.0,0.0);}	
 
	texel = texture2D(texture, gl_TexCoord[0].st -  0.0005 * grad_dir * hmap * 2.0 * parallaxFactor);
        float night_light = (1.0 -texel.a);
	texel.a = 1.0;
	grainTexel = texture2D(grain_texture, gl_TexCoord[0].st * 40.0);

	float noise = Noise2D( gl_TexCoord[0].st, 0.00005);
	 noise += Noise2D( gl_TexCoord[0].st, 0.0002);
	 noise += Noise2D( gl_TexCoord[0].st, 0.0001);
	
	noise= noise/3.0;

	
    vec3 light_specular = vec3 (1.0, 1.0, 1.0);
    NdotL = dot(N, lightDir);
    float NdotLraw = NdotL;
    // due to atmosphere scattering, we should make this harder
    NdotL = smoothstep(-0.2 ,0.2,NdotL);	
    // fog does not feel normal map
    float NdotLfog = smoothstep(-0.2 , 0.2, dot(n, lightDir));
   
    float intensity = length(diffuse_term);
    vec4 dawn = intensity * normalize (vec4 (1.0,0.5,0.3,1.0));
    vec4 diff_term = mix(dawn, diffuse_term, smoothstep(0.0, 0.3, NdotL));

   
    intensity = length(light_specular);
    light_specular = mix(dawn.rgb, light_specular, smoothstep(0.0, 0.4, NdotL));
    
    float oceanness = smoothstep(0.0, 0.1,length(texel.rgb - vec3 (0.007,0.019, 0.078)));
    float specular_enhancement = 4.0 * (1.0 - oceanness);

    if (use_overlay) {
		//texel.rgb = mix(texel.rgb, grainTexel.rgb, 0.4* grainTexel.a * oceanness);
		texel.rgb = texel.rgb * (0.85 + 0.3 * noise);
		texel.r = smoothstep(0.0, 0.95, texel.r);
		texel.g = smoothstep(0.0, 0.95, texel.g);
		texel.b = smoothstep(0.0, 0.95, texel.b);
		float intensity = length(texel.rgb);
		texel.rgb = mix(texel.rgb, intensity * vec3 (1.0,1.0,1.0), 0.3);
		}

	//texel.rgb = vec3 (0.5,0.5,0.5);



    // strictly positive produces visible hard cut
    if (NdotL >= 0.0) {
        color += diff_term * NdotL * (1.0-shadowTexel.a);
        NdotHV = max(dot(n, halfVector), 0.0);
        if (gl_FrontMaterial.shininess > 0.0)
            specular.rgb = (gl_FrontMaterial.specular.rgb * specular_enhancement
                            * light_specular * (1.0-shadowTexel.a)
                            * pow(NdotHV, gl_FrontMaterial.shininess));
    }
	
	vec3 moonLightColor = vec3 (0.095, 0.095, 0.15) * moonlight;
	moonLightColor = moonlight_perception (moonLightColor); 
	color.rgb += moonLightColor;
	
    color.a = diffuse_term.a;


    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    color = clamp(color, 0.0, 1.0);

    fragColor = color * texel + specular;


    float night_light_factor = night_light * (1.0 - smoothstep(-0.3, 0.0, NdotLraw));

    float noise_factor = (0.4 + 0.6* smoothstep(0.7 - 0.4* night_light,0.9 - 0.4 * night_light,noise));
    night_light_factor *= noise_factor;


    vec3 light_color = vec3(1.0, 0.7, 0.3);
    vec3 central_light_color = vec3 (1.0, 1.0, 1.0);
    light_color = mix(light_color, central_light_color, smoothstep(0.3, 0.6,noise*noise * night_light));
	
    fragColor.rgb += light_color * night_light_factor * 1.4;
	
	float angle = dot(normalize(ecViewDir), normalize(normal));
	float distance_through_atmosphere = min(10.0 / (abs(angle)+0.001),500.0);

   
	float fogLighting = clamp(NdotLfog,0.0,1.0) * length(diff_term.rgb/1.73);
	
	vec4 fogColor = vec4 (0.83,0.9,1.0,1.0) * fogLighting;
	vec3 rayleighColor = vec3 (0.17, 0.52, 0.87) * fogLighting;
		
	float heightFactor = exp(-hmap * 0.8);
	distance_through_atmosphere *= heightFactor;
		
	float fogFactor = exp(-distance_through_atmosphere/(visibility/1000.0));
	float rayleighFactor = exp(-distance_through_atmosphere/(300.0 / (1.0 + 4.0 * air_pollution)) );
  

  
    fragColor.rgb = mix(rayleighColor, fragColor.rgb, rayleighFactor);
	fragColor = mix(fogColor, fragColor, fogFactor);

	fragColor.rgb = filter_combined(fragColor.rgb);


	

    gl_FragColor = clamp(fragColor, 0.0, 1.0);
		

}
