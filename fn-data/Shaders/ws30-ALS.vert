// WS30 VERTEX SHADER
// -*-C++-*-
#version 120

// Shader that uses OpenGL state values to do per-pixel lighting
//
// The only light used is gl_LightSource[0], which is assumed to be
// directional.
//
// Colors are not assigned in this shader, as they will come from
// the landclass lookup in the fragment shader.
// Haze part added by Thorsten Renk, Oct. 2011


#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2

// From VPBTechnique.cxx
uniform mat4 fg_zUpTransform;
uniform vec3 fg_modelOffset;

// The constant term of the lighting equation that doesn't depend on
// the surface normal is passed in gl_{Front,Back}Color. The alpha
// component is set to 1 for front, 0 for back in order to work around
// bugs with gl_FrontFacing in the fragment shader.
varying vec4 light_diffuse_comp;
varying vec3 normal;
varying vec3 relPos;
varying vec2 ground_tex_coord;
varying vec4 ecPosition;

varying float yprime_alt;
varying float mie_angle;

// For water calculations
varying float earthShade;
varying vec3 lightdir;
varying vec4 waterTex1;
varying vec4 waterTex2;
varying vec4 waterTex4;
varying vec3 specular_light;

uniform float osg_SimulationTime;
uniform float WindN;
uniform float WindE;

uniform int colorMode;
uniform float hazeLayerAltitude;
uniform float terminator;
uniform float terrain_alt; 
uniform float avisibility;
uniform float visibility;
uniform float overcast;
uniform float ground_scattering;
uniform float moonlight;
uniform float eye_alt;

void setupShadows(vec4 eyeSpacePos);

// This is the value used in the skydome scattering shader - use the same here for consistency?
const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;

float light_func (in float x, in float a, in float b, in float c, in float d, in float e)
{
  // use the asymptotics to shorten computations
  if (x < -15.0) {return 0.0;}
  return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}

void rotationmatrix(in float angle, out mat4 rotmat)
{
  rotmat = mat4( cos( angle ), -sin( angle ), 0.0, 0.0,
      sin( angle ),  cos( angle ), 0.0, 0.0,
      0.0         ,  0.0         , 1.0, 0.0,
      0.0         ,  0.0         , 0.0, 1.0 );
}

void main()
{

  vec4 light_diffuse;
  vec4 light_ambient;
  vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
  vec3 moonLightColor = vec3 (0.095, 0.095, 0.15) * moonlight;


  //float yprime_alt;
  float yprime;
  float lightArg;
  float intensity;
  float vertex_alt;
  float scattering;

// this code is copied from default.vert

    ecPosition = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = ftransform();
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    normal = gl_NormalMatrix * gl_Normal;

    // Required for water calculations
    lightdir = normalize(vec3(fg_zUpTransform * vec4(gl_ModelViewMatrixInverse * gl_LightSource[0].position)));
    waterTex4 = vec4( ecPosition.xzy, 0.0 );

    vec4 t1 = vec4(0.0, osg_SimulationTime * 0.005217, 0.0, 0.0);
    vec4 t2 = vec4(0.0, osg_SimulationTime * -0.0012, 0.0, 0.0);

    float Angle;

    float windFactor = sqrt(WindE * WindE + WindN * WindN) * 0.05;
    if (WindN == 0.0 && WindE == 0.0) {
        Angle = 0.0;
    } else {
        Angle = atan(-WindN, WindE) - atan(1.0);
    }

    mat4 RotationMatrix;
    rotationmatrix(Angle, RotationMatrix);
    waterTex1 = gl_MultiTexCoord0 * RotationMatrix - t1 * windFactor;
    rotationmatrix(Angle, RotationMatrix);
    waterTex2 = gl_MultiTexCoord0 * RotationMatrix - t2 * windFactor;

    // Temporary value:
    ground_tex_coord = gl_TexCoord[0].st;

    // here start computations for the haze layer
    // we need several geometrical quantities

    // first current altitude of eye position in model space
    vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
    
    // and relative position to vector
    relPos = (fg_zUpTransform * vec4(gl_Vertex - ep)).xyz;

    // unfortunately, we need the distance in the vertex shader, although the more accurate version
    // is later computed in the fragment shader again
    float dist = length(relPos);

    // altitude of the vertex in question, somehow zero leads to artefacts, so ensure it is at least 100m
    vertex_alt = max(relPos.z + eye_alt, 100.0);
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
        if (lightArg < 10.0) {
            mie_angle = (0.5 *  dot(normalize(relPos), normalize(lightFull)) ) + 0.5;
        } else { 
            mie_angle = 1.0;
        }

        light_diffuse.b = light_func(lightArg, 1.330e-05, 0.264, 3.827, 1.08e-05, 1.0);
        light_diffuse.g = light_func(lightArg, 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
        light_diffuse.r = light_func(lightArg, 8.305e-06, 0.161, 3.827, 3.04e-05, 1.0);
        light_diffuse.a = 1.0;
        light_diffuse = light_diffuse * scattering;


        light_ambient.r = light_func(lightArg, 0.236, 0.253, 1.073, 0.572, 0.33);
        light_ambient.g = light_ambient.r * 0.4/0.33; 
        light_ambient.b = light_ambient.r * 0.5/0.33; 
        light_ambient.a = 1.0;

        // Water specular calculations
        specular_light.b = light_func(lightArg, 1.330e-05, 0.264, 3.827, 1.08e-05, 1.0);
        specular_light.g = light_func(lightArg, 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
        specular_light.r = light_func(lightArg, 8.305e-06, 0.161, 3.827, 3.04e-05, 1.0);
        specular_light = max(specular_light * scattering, vec3 (0.05, 0.05, 0.05));
        intensity = length(specular_light.rgb);
        specular_light.rgb = intensity * normalize(mix(specular_light.rgb,  shadedFogColor, 1.0 -smoothstep(0.1, 0.6,ground_scattering) ));
        specular_light.rgb = intensity * normalize(mix(specular_light.rgb,  shadedFogColor, 1.0 -smoothstep(0.5, 0.7,earthShade)));

        // correct ambient light intensity and hue before sunrise
        if (earthShade < 0.5) {
            //light_ambient = light_ambient * (0.7 + 0.3 * smoothstep(0.2, 0.5, earthShade));
            intensity = length(light_ambient.xyz); 

            light_ambient.rgb = intensity * normalize(mix(light_ambient.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.8,earthShade) ));
            light_ambient.rgb = light_ambient.rgb +   moonLightColor *  (1.0 - smoothstep(0.4, 0.5, earthShade));

            intensity = length(light_diffuse.xyz); 
            light_diffuse.rgb = intensity * normalize(mix(light_diffuse.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.7,earthShade) ));
        }

        // directional scattering for low sun
        if (lightArg < 10.0) {
            mie_angle = (0.5 *  dot(normalize(relPos), lightdir) ) + 0.5;
        } else {
            mie_angle = 1.0;
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
        } else {
            vertex_alt = hazeLayerAltitude;
            yprime_alt = yprime -sqrt(2.0 * EarthRadius * vertex_alt);
        }
    }
    else // the faster, full-day version without lightfields
    {
        earthShade = 1.0;
        mie_angle = 1.0;

        if (terminator > 3000000.0) {
            light_diffuse = vec4 (1.0, 1.0, 1.0, 0.0);
            light_ambient = vec4 (0.33, 0.4, 0.5, 0.0); 
            specular_light = vec3 (1.0, 1.0, 1.0);

        } else {
            lightArg = (terminator/100000.0 - 10.0)/20.0;
            light_diffuse.b = 0.78  + lightArg * 0.21;
            light_diffuse.g = 0.907 + lightArg * 0.091;
            light_diffuse.r = 0.904 + lightArg * 0.092;
            light_diffuse.a = 1.0;

            light_ambient.r = 0.316 + lightArg * 0.016;
            light_ambient.g = light_ambient.r * 0.4/0.33; 
            light_ambient.b = light_ambient.r * 0.5/0.33;
            light_ambient.a = 1.0;

            specular_light.b = 0.78  + lightArg * 0.21;
            specular_light.g = 0.907 + lightArg * 0.091;
            specular_light.r = 0.904 + lightArg * 0.092;
        }  
        
        light_diffuse = light_diffuse * scattering;
        specular_light = specular_light * scattering;
        float shade_depth =  1.0 * smoothstep (0.6,0.95,ground_scattering) * (1.0-smoothstep(0.1,0.5,overcast)) * smoothstep(0.4,1.5,earthShade);
        specular_light.rgb *= (1.0 + 1.2 * shade_depth);

        yprime_alt = -sqrt(2.0 * EarthRadius * hazeLayerAltitude);
    }
 

    // default lighting based on texture and material using the light we have just computed

    light_diffuse_comp = light_diffuse;
    //Testing phase code: ambient colours are not sent to fragement shader yet. 
    //  They are all default except for water/ocean etc. currently
    //  Emission is all set to the default of vec4(0.0, 0.0, 0.0, 1.0)
    //To do: Fix this once ambient colour becomes available in the fragment shaders.
    //const vec4 ambient_color = vec4(0.2, 0.2, 0.2, 1.0);
    vec4 constant_term = gl_LightModel.ambient +  light_ambient;
    // Another hack for supporting two-sided lighting without using
    // gl_FrontFacing in the fragment shader.
    gl_FrontColor.rgb = constant_term.rgb;
    gl_BackColor.rgb = constant_term.rgb;
    gl_FrontColor.a = mie_angle;
    gl_BackColor.a = mie_angle;

    setupShadows(ecPosition);
}




