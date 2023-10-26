// -*-C++-*-
#version 120

// written by Thorsten Renk, Oct 2017

varying vec4 diffuse_term;
varying vec3 normal;
varying vec3 relPos;
varying vec4 ecPosition;


uniform sampler2D texture;
uniform sampler2D dust_texture;
uniform sampler2D lightmap_texture;
uniform sampler2D grain_texture;
uniform samplerCube cube_texture;


varying float yprime_alt;
varying float mie_angle;


uniform float visibility;
uniform float avisibility;
uniform float scattering;
uniform float terminator;
uniform float terrain_alt; 
uniform float hazeLayerAltitude;
uniform float overcast;
uniform float eye_alt;
uniform float cloud_self_shading;
uniform float angle;
uniform float threshold_low;
uniform float threshold_high;
uniform float emit_intensity;
uniform float light_radius;
uniform float dirt_factor;
uniform float lightmap_r_factor;
uniform float lightmap_g_factor;
uniform float lightmap_b_factor;
uniform float lightmap_a_factor;
uniform float grain_magnification;
uniform float sample_res;


uniform float contrast;

uniform vec3 offset_vec;
uniform vec3 scale_vec;
uniform vec3 tag_color;
uniform vec3 emit_color;
uniform vec3 light_filter_one;
uniform vec3 light_filter_two;
uniform vec3 lightmap_r_color;
uniform vec3 lightmap_g_color;
uniform vec3 lightmap_b_color;
uniform vec3 lightmap_a_color;


uniform int quality_level;
uniform int tquality_level;
uniform int use_searchlight;
uniform int implicit_lightmap_enabled;
uniform int use_flashlight;
uniform int lightmap_enabled;
uniform int lightmap_multi;
uniform int grain_texture_enabled;

uniform bool shadow_mapping_enabled;


const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;

float alt;
float eShade;


float fog_func (in float targ, in float alt);
float alt_factor(in float eye_alt, in float vertex_alt);
float light_distance_fading(in float dist);
float fog_backscatter(in float avisibility);

vec3 addLights(in vec3 color1, in vec3 color2);
vec3 flashlight(in vec3 color, in float radius);
vec3 filter_combined (in vec3 color) ;

float getShadowing();
vec3 getClusteredLightsContribution(vec3 p, vec3 n, vec3 texel);

float luminance(vec3 color)
{
    return dot(vec3(0.212671, 0.715160, 0.072169), color);
}


float light_func (in float x, in float a, in float b, in float c, in float d, in float e)
{
x = x - 0.5;

// use the asymptotics to shorten computations
if (x > 30.0) {return e;}
if (x < -15.0) {return 0.0;}

return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}

// bloom effect on the display texture


vec4 find_max (in vec4 texel1, in vec4 texel2, in vec4 texel3, in vec4 texel4)
{

float r = max(texel1.r, texel2.r);
r = max(r, texel3.r);
r = max(r, texel4.r);

float g = max(texel1.g, texel2.g);
g = max(g, texel3.g);
g = max(g, texel4.g);

float b = max(texel1.b, texel2.b);
b = max(b, texel3.b);
b = max(b, texel4.b);

float a = max(texel1.a, texel2.a);
a = max(a, texel3.a);
a = max(a, texel4.a);

//float a = (texel1.a + texel2.a + texel3.a + texel4.a)/4.0;

return vec4 (r,g,b,a);
}

vec4 get_blurred_texel (in vec4 direct_light)
{



float fade0 = smoothstep(0.5, 1.0,contrast);
float fade1 = 0.25 * contrast * contrast;
float fade2 = 0.25 * contrast * contrast;

//fade0 = 1.0;
//fade1 = 1.0;
//fade2 = 1.0;

float desaturation_brightness = 1.0;

float sample_far = 2.0;
float curr_sample_res = sample_res * contrast;

vec4 texel = texture2D(texture, gl_TexCoord[0].st);

vec4 texel1 =  texture2D(texture, vec2 (gl_TexCoord[0].s + curr_sample_res, gl_TexCoord[0].t));
vec4 texel2 =  texture2D(texture, vec2 (gl_TexCoord[0].s - curr_sample_res, gl_TexCoord[0].t));
vec4 texel3 =  texture2D(texture, vec2 (gl_TexCoord[0].s, gl_TexCoord[0].t + curr_sample_res));
vec4 texel4 =  texture2D(texture, vec2 (gl_TexCoord[0].s, gl_TexCoord[0].t - curr_sample_res));

vec4 sample_texel = find_max (texel1, texel2, texel3, texel4);

texel.rgb += fade0 * sample_texel.rgb;


texel1 = texture2D(texture, vec2 (gl_TexCoord[0].s + sample_far * curr_sample_res, gl_TexCoord[0].t+ sample_far * curr_sample_res));
texel2 = texture2D(texture, vec2 (gl_TexCoord[0].s - sample_far * curr_sample_res, gl_TexCoord[0].t+ sample_far * curr_sample_res));
texel3 = texture2D(texture, vec2 (gl_TexCoord[0].s + sample_far * curr_sample_res, gl_TexCoord[0].t- sample_far * curr_sample_res));
texel4 = texture2D(texture, vec2 (gl_TexCoord[0].s - sample_far * curr_sample_res, gl_TexCoord[0].t- sample_far * curr_sample_res));

sample_texel = find_max (texel1, texel2, texel3, texel4);

texel.rgb += fade1 * sample_texel.rgb;



texel1 = texture2D(texture, vec2 (gl_TexCoord[0].s + 2.0 * sample_far * curr_sample_res, gl_TexCoord[0].t - curr_sample_res));
texel2 = texture2D(texture, vec2 (gl_TexCoord[0].s - 2.0 * sample_far * curr_sample_res, gl_TexCoord[0].t + curr_sample_res));
texel3 = texture2D(texture, vec2 (gl_TexCoord[0].s - curr_sample_res, gl_TexCoord[0].t + 2.0 * sample_far * curr_sample_res));
texel4 = texture2D(texture, vec2 (gl_TexCoord[0].s + curr_sample_res, gl_TexCoord[0].t - 2.0 * sample_far * curr_sample_res));

sample_texel = find_max (texel1, texel2, texel3, texel4);

texel.rgb += fade2 * sample_texel.rgb;


texel1 =  texture2D(texture, vec2 (gl_TexCoord[0].s + 2.5 * sample_far * curr_sample_res, gl_TexCoord[0].t + 2.5 * sample_far * curr_sample_res));
texel2 = texture2D(texture, vec2 (gl_TexCoord[0].s - 2.5 * sample_far * curr_sample_res, gl_TexCoord[0].t + 2.5 * sample_far * curr_sample_res));
texel3 = texture2D(texture, vec2 (gl_TexCoord[0].s + 2.5 * sample_far * curr_sample_res, gl_TexCoord[0].t - 2.5 * sample_far * curr_sample_res));
texel4 = texture2D(texture, vec2 (gl_TexCoord[0].s - 2.5 * sample_far * curr_sample_res, gl_TexCoord[0].t - 2.5 * sample_far * curr_sample_res));

sample_texel = find_max (texel1, texel2, texel3, texel4);

texel.rgb += fade2 * sample_texel.rgb;



texel.rgb/= (1.0 + 1.0 * fade0 + 1.0 * fade1 + 2.0 * fade2);
texel.a = smoothstep(0.0, 0.1, length(texel.rgb));

texel.a *= (1.0 - 0.9 * smoothstep(0.0, 1.0, length(direct_light.rgb)/1.73 * 4.0 *( 0.5 - contrast)) );

float threshold_high = max(desaturation_brightness, 0.05) * 1.0;
float threshold_mid = max(desaturation_brightness, 0.05) * 0.6;

float pixel_brightness = max(texel.r, texel.g);
pixel_brightness = max(pixel_brightness, texel.b);
pixel_brightness *= contrast;


texel.rgb = mix(texel.rgb, vec3 (1.0, 1.0, 1.0), 0.9 * smoothstep(threshold_mid, threshold_high, pixel_brightness));


return texel;
}


void main()
{

  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
// this is taken from default.frag
    vec3 n;
    float NdotL, NdotHV, fogFactor;
    vec4 color = gl_Color;
    vec3 lightDir = gl_LightSource[0].position.xyz;
    vec3 halfVector = gl_LightSource[0].halfVector.xyz;
    vec4 texel;
    vec4 fragColor;
    vec4 specular = vec4(0.0);
    float intensity;

    float effective_scattering = min(scattering, cloud_self_shading);

    eShade = 1.0 - 0.9 * smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt);
    vec4 light_specular = gl_LightSource[0].specular * (eShade - 0.1);

    // If gl_Color.a == 0, this is a back-facing polygon and the
    // normal should be reversed.
    n = (2.0 * gl_Color.a - 1.0) * normal;
    n = normalize(n);

    // lookup on the opacity map
    vec3 light_vec = normalize((gl_ModelViewMatrixInverse * gl_LightSource[0].position).xyz);
    //vec3 light_vec = vec3 (-1.0,0.0,0.0);

    vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
    vec3 scaled_pos = relPos + ep.xyz;

    //vec3 lookup_vec = normalize(- normalize(light_vec) + relPos);
    scaled_pos -= offset_vec; 
    float rangle = radians(angle);
    mat2 rotMat = mat2 (cos(rangle), -sin(rangle), sin(rangle), cos(rangle));   
    scaled_pos.xy *=rotMat;

    scaled_pos /= scale_vec;
    
    //vec3 lookup_pos = dot(base1,scaled_pos) * base1 + dot(base2,scaled_pos) * base2;
    vec3 lookup_pos = scaled_pos - light_vec * dot(light_vec, scaled_pos);

    vec3 lookup_vec = normalize(normalize(light_vec) + lookup_pos);
    vec4 opacity = textureCube(cube_texture, lookup_vec);
   

    vec4 diffuse = diffuse_term;
    NdotL = dot(n, lightDir);
    //NdotL = dot(n, (gl_ModelViewMatrix * vec4 (light_vec,0.0)).xyz);
    if (NdotL > 0.0) {
        float shadowmap = 1.0;
        if (shadow_mapping_enabled) {
            shadowmap = getShadowing();
        }
	diffuse.rgb += 2.0 * diffuse.rgb * (1.0 - opacity.a);
        color += diffuse * NdotL * opacity * shadowmap;
        NdotHV = max(dot(n, halfVector), 0.0);
        if (gl_FrontMaterial.shininess > 0.0)
            specular.rgb = (gl_FrontMaterial.specular.rgb
                            * light_specular.rgb
                            * pow(NdotHV, gl_FrontMaterial.shininess)
                            * shadowmap);
    }
    color.a = diffuse.a;
    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    //color = clamp(color, 0.0, 1.0);

    vec3 secondary_light = vec3 (0.0,0.0,0.0);

    if (use_flashlight == 1)
 	{
 	secondary_light.rgb += flashlight(light_filter_one, light_radius);
 	}
    if (use_flashlight == 2)
 	{
 	secondary_light.rgb += flashlight(light_filter_two, light_radius);
 	}
 	float dist = length(relPos);
 	color.rgb += secondary_light * light_distance_fading(dist);

    //texel = texture2D(texture, gl_TexCoord[0].st);

    texel = get_blurred_texel(diffuse * max(0.0, NdotL) * opacity);

    if (grain_texture_enabled ==1)
        {
        vec4 grainTexel = texture2D(grain_texture, gl_TexCoord[0].st * grain_magnification);
        texel.rgb = mix(texel.rgb, grainTexel.rgb,  grainTexel.a );
        }



    fragColor = color * texel + specular;
    fragColor.rgb += getClusteredLightsContribution(ecPosition.xyz, n, texel.rgb);

   // explicit lightmap

    vec3 lightmapcolor = vec3(0.0, 0.0, 0.0);


    if (lightmap_enabled == 1)
	{
        vec4 lightmapTexel = texture2D(lightmap_texture, gl_TexCoord[0].st);
        vec4 lightmapFactor = vec4(lightmap_r_factor, lightmap_g_factor, lightmap_b_factor, lightmap_a_factor);


        if (lightmap_multi > 0 )
		{
        lightmapFactor = lightmapFactor * lightmapTexel;


		lightmapcolor = lightmap_r_color * lightmapFactor.r;
		lightmapcolor = addLights(lightmapcolor, lightmap_g_color * lightmapFactor.g);
		lightmapcolor = addLights(lightmapcolor, lightmap_b_color * lightmapFactor.b);
		lightmapcolor = addLights(lightmapcolor, lightmap_a_color * lightmapFactor.a);

            	}
	 else 
		{
                lightmapcolor = lightmapTexel.rgb * lightmap_r_color * lightmapFactor.r;
            	}


   // implicit lightmap - the user gets to select a color which is then made emissive

   if (implicit_lightmap_enabled == 1)
	{
	float cdiff = (length(texel.rgb - tag_color));
	float enhance = 1.0 - smoothstep(threshold_low, threshold_high, cdiff); 
	enhance *= (1.0 - length(lightmapcolor.rgb)/1.73);
	fragColor.rgb = fragColor.rgb + enhance * emit_color * emit_intensity;
	}


       fragColor.rgb = max(fragColor.rgb, lightmapcolor.rgb * gl_FrontMaterial.diffuse.rgb * smoothstep(0.0, 1.0, texel.rgb*.5 + lightmapcolor.rgb*.5));
	}

   // add visible dust for glancing sun angle

    vec4 dustTexel = texture2D(dust_texture, gl_TexCoord[0].st);
    dustTexel.rgb *= diffuse.rgb;
    dustTexel.a = clamp(dustTexel.a * dirt_factor * (1.0 - 0.4 * max(0.0,NdotL)) * (length(opacity.rgb)/1.76),0.0,1.0); 
    fragColor.rgb =  mix(fragColor.rgb, dustTexel.rgb,  dustTexel.a );
    fragColor.a = max(fragColor.a, dustTexel.a);


fragColor.rgb = filter_combined(fragColor.rgb);

gl_FragColor = fragColor;



}

