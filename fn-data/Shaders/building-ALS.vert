// -*-C++-*-
#version 120
#extension GL_EXT_draw_instanced : enable

// Shader that uses OpenGL state values to do per-pixel lighting
//
// The only light used is gl_LightSource[0], which is assumed to be
// directional.
//
// Diffuse colors come from the gl_Color, ambient from the material. This is
// equivalent to osg::Material::DIFFUSE.
// Haze part added by Thorsten Renk, Oct. 2011


#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2

attribute vec3 instancePosition; // (x,y,z)
attribute vec3 instanceScale; // (width, depth, height)
attribute vec3 attrib1;          // Generic packed attributes
attribute vec3 attrib2;

// The constant term of the lighting equation that doesn't depend on
// the surface normal is passed in gl_{Front,Back}Color. The alpha
// component is set to 1 for front, 0 for back in order to work around
// bugs with gl_FrontFacing in the fragment shader.
varying vec4 diffuse_term;
varying vec3 normal;
varying vec3 relPos;
varying vec4 ecPosition;

//varying float earthShade;
//varying float yprime;
//varying float vertex_alt;
varying float yprime_alt;
varying float mie_angle;

uniform int colorMode;
uniform float hazeLayerAltitude;
uniform float terminator;
uniform float terrain_alt;
uniform float avisibility;
uniform float visibility;
uniform float overcast;
//uniform float scattering;
uniform float ground_scattering;

uniform bool use_IR_vision;

// This is the value used in the skydome scattering shader - use the same here for consistency?
const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;


float earthShade;
//float mie_angle;

void setupShadows(vec4 eyeSpacePos);

float light_func (in float x, in float a, in float b, in float c, in float d, in float e)
{
//x = x - 0.5;

// use the asymptotics to shorten computations
if (x < -15.0) {return 0.0;}

return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}

const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;

vec3 float2vec(float value) {
	vec3 val;
	val.x = mod(value, c_precisionp1) / c_precision;
	val.y = mod(floor(value / c_precisionp1), c_precisionp1) / c_precision;
	val.z = floor(value / (c_precisionp1 * c_precisionp1)) / c_precision;
	return val;
}

void main()
{

  vec4 light_diffuse;
  vec4 light_ambient;

  float yprime;
  float lightArg;
  float intensity;
  float vertex_alt;
  float scattering;
  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);

  // Unpack generic attributes
  vec3 attr1 = float2vec(attrib1.x);
  vec3 attr2 = float2vec(attrib1.z);
  vec3 attr3 = float2vec(attrib2.x);

  // Determine the rotation for the building.
  float sr = sin(6.28 * attr1.x);
  float cr = cos(6.28 * attr1.x);

  vec3 position = gl_Vertex.xyz;
  // Adjust the very top of the roof to match the rooftop scaling.  This shapes
  // the rooftop - gambled, gabled etc.  These vertices are identified by gl_Color.z
  position.x = (1.0 - gl_Color.z) * position.x + gl_Color.z * ((position.x + 0.5) * attr3.z - 0.5);
  position.y = (1.0 - gl_Color.z) * position.y + gl_Color.z * (position.y * attrib2.y );

  // Adjust pitch of roof to the correct height. These vertices are identified by gl_Color.z
  // Scale down by the building height (instanceScale.z) because
  // immediately afterwards we will scale UP the vertex to the correct scale.
  position.z = position.z + gl_Color.z * attrib1.y / instanceScale.z;
  position = position * instanceScale.xyz;

  // Rotation of the building and movement into position
  position.xy = vec2(dot(position.xy, vec2(cr, sr)), dot(position.xy, vec2(-sr, cr)));
  position = position + instancePosition.xyz;

  gl_Position = gl_ModelViewProjectionMatrix * vec4(position,1.0);

  // Texture coordinates are stored as:
  // - a separate offset (x0, y0) for the wall (wtex0x, wtex0y), and roof (rtex0x, rtex0y)
  // - a semi-shared (x1, y1) so that the front and side of the building can have
  //   different texture mappings
  //
  // The vertex color value selects between them:
  // gl_Color.x=1 indicates front/back walls
  // gl_Color.y=1 indicates roof
  // gl_Color.z=1 indicates top roof vertexs (used above)
  // gl_Color.a=1 indicates sides
  // Finally, the roof texture is on the right of the texture sheet
  float wtex0x = attr1.y; // Front/Side texture X0
  float wtex0y = attr1.z; // Front/Side texture Y0
  float rtex0x = attr2.z; // Roof texture X0
  float rtex0y = attr3.x; // Roof texture Y0
  float wtex1x = attr2.x; // Front/Roof texture X1
  float stex1x = attr3.y; // Side texture X1
  float wtex1y = attr2.y; // Front/Roof/Side texture Y1
  vec2 tex0 = vec2(sign(gl_MultiTexCoord0.x) * (gl_Color.x*wtex0x + gl_Color.y*rtex0x + gl_Color.a*wtex0x),
                   gl_Color.x*wtex0y + gl_Color.y*rtex0y + gl_Color.a*wtex0y);

  vec2 tex1 = vec2(gl_Color.x*wtex1x + gl_Color.y*wtex1x + gl_Color.a*stex1x,
                   wtex1y);

  gl_TexCoord[0].x = tex0.x + gl_MultiTexCoord0.x * tex1.x;
  gl_TexCoord[0].y = tex0.y + gl_MultiTexCoord0.y * tex1.y;

  // Rotate the normal.
  normal = gl_Normal;
  normal.xy = vec2(dot(normal.xy, vec2(cr, sr)), dot(normal.xy, vec2(-sr, cr)));
  normal = gl_NormalMatrix * normal;


    vec4 ambient_color, diffuse_color;
    if (colorMode == MODE_DIFFUSE) {
        diffuse_color = vec4(1.0,1.0,1.0,1.0);
        ambient_color = gl_FrontMaterial.ambient;
    } else if (colorMode == MODE_AMBIENT_AND_DIFFUSE) {
        diffuse_color = vec4(1.0,1.0,1.0,1.0);
        ambient_color = vec4(1.0,1.0,1.0,1.0);
    } else {
        diffuse_color = gl_FrontMaterial.diffuse;
        ambient_color = gl_FrontMaterial.ambient;
    }

    // here start computations for the haze layer
    // we need several geometrical quantities

    // first current altitude of eye position in model space
    vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);

    // and relative position to vector
    relPos = gl_Vertex.xyz + gl_Color.xyz - ep.xyz;

    // unfortunately, we need the distance in the vertex shader, although the more accurate version
    // is later computed in the fragment shader again
    float dist = length(relPos);

    // altitude of the vertex in question, somehow zero leads to artefacts, so ensure it is at least 100m
    vertex_alt = max(gl_Vertex.z + gl_Color.z,100.0);
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

   light_ambient.r = light_func(lightArg, 0.236, 0.253, 1.073, 0.572, 0.33);
   light_ambient.g = light_ambient.r * 0.4/0.33;
   light_ambient.b = light_ambient.r * 0.5/0.33;
   light_ambient.a = 1.0;

// correct ambient light intensity and hue before sunrise
if (earthShade < 0.5)
	{
	//light_ambient = light_ambient * (0.4 + 0.6 * smoothstep(0.2, 0.5, earthShade));
	intensity = length(light_ambient.rgb);
	light_ambient.rgb = intensity * normalize(mix(light_ambient.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.8,earthShade) ));

	intensity = length(light_diffuse.rgb);
	light_diffuse.rgb = intensity * normalize(mix(light_diffuse.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.7,earthShade) ));
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

}
else // the faster, full-day version without lightfields
{
    //vertex_alt = max(gl_Vertex.z,100.0);

    earthShade = 1.0;
    mie_angle = 1.0;

    if (terminator > 3000000.0)
    	{light_diffuse = vec4 (1.0, 1.0, 1.0, 1.0);
	light_ambient = vec4 (0.33, 0.4, 0.5, 1.0); }
    else
	{

	lightArg = (terminator/100000.0 - 10.0)/20.0;
	light_diffuse.b = 0.78  + lightArg * 0.21;
	light_diffuse.g = 0.907 + lightArg * 0.091;
	light_diffuse.r = 0.904 + lightArg * 0.092;
	light_diffuse.a = 1.0;

	light_ambient.r = 0.316 + lightArg * 0.016;
	light_ambient.g = light_ambient.r * 0.4/0.33;
   	light_ambient.b = light_ambient.r * 0.5/0.33;
	light_ambient.a = 1.0;
	}

    light_diffuse = light_diffuse * scattering;
    yprime_alt = -sqrt(2.0 * EarthRadius * hazeLayerAltitude);
}

if (use_IR_vision)
	{
	light_ambient.rgb = max(light_ambient.rgb, vec3 (0.5, 0.5, 0.5));
	}


// default lighting based on texture and material using the light we have just computed

 diffuse_term = diffuse_color* light_diffuse;
    vec4 constant_term = gl_FrontMaterial.emission + ambient_color *
        (gl_LightModel.ambient +  light_ambient);
    // Super hack: if diffuse material alpha is less than 1, assume a
    // transparency animation is at work
    if (gl_FrontMaterial.diffuse.a < 1.0)
        diffuse_term.a = gl_FrontMaterial.diffuse.a;
    else
        diffuse_term.a = 1.0;
    // Another hack for supporting two-sided lighting without using
    // gl_FrontFacing in the fragment shader.
    gl_FrontColor.rgb = constant_term.rgb;
    gl_BackColor.rgb = constant_term.rgb;
    //gl_FrontColor.a = mie_angle; gl_BackColor.a = mie_angle;

    ecPosition = gl_ModelViewMatrix * vec4(position, 1.0);
    setupShadows(ecPosition);
}
