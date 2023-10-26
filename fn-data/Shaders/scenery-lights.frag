// -*-C++-*-
#version 120

// Shader that takes a list of GL_POINTS and draws a light (point-sprite like
// texture, more accurately a light halo) at the given point. This shader
// provides support for light animations like blinking, time period handling
// for lights on only during night time or in low visiblity and directional
// lighting.
//
// The actual rendering code is heavily based on an existing implementation
// found at:
//   FGData commit 9355d464c175bd5d51ba32527180ed4e94e86fbb
//   Shaders/surface-lights-ALS.frag
// with minor modifications for readability and tuning.
//
// Licence: GPL v2+
// Written by Fahim Dalvi, January 2021

uniform sampler2D texture;

uniform float visibility;
uniform float avisibility;
uniform float hazeLayerAltitude;
uniform float eye_alt;
uniform float terminator;

uniform bool use_IR_vision;
uniform bool use_night_vision;

varying vec3 relativePosition;
varying vec2 rawPosition;
varying float apparentSize;
varying float haloSize;
varying float lightSize;
varying float lightIntensity;

float alt;

float Noise2D(in vec2 coord, in float wavelength);

float fog_func (in float targ)
{
    float fade_mix;

    // for large altitude > 30 km, we switch to some component of quadratic distance fading to
    // create the illusion of improved visibility range
    targ = 1.25 * targ * smoothstep(0.04,0.06,targ); // need to sync with the distance to which terrain is drawn
    if (alt < 30000.0) {
        return exp(-targ - targ * targ * targ * targ);
    } else if (alt < 50000.0) {
        fade_mix = (alt - 30000.0)/20000.0;
        return fade_mix * exp(-targ*targ - pow(targ,4.0)) + (1.0 - fade_mix) * exp(-targ - pow(targ,4.0));
    } else {
        return exp(- targ * targ - pow(targ,4.0));
    }
}


float light_sprite (in vec2 coord, in float transmission, in float noise)
{
    // Center the texture coordinates at (0,0)
    coord.s = coord.s - 0.5;
    coord.t = coord.t - 0.5;

    // Radius of the current pixel from the center of the light ranging from 0 to 1
    float r = length(coord) * 2;

    // If the light is too small, return constant intensity
    if (apparentSize<1.3) {return  0.08;}

    // Calculate the rays (star-shaped structure) around the light
    // These are randomized for every light based on `noise`
    float angle = noise * 6.2832;
    float sinphi = dot(vec2 (sin(angle),cos(angle)), normalize(coord));
    float sinterm = sin(mod((sinphi-3.0) * (sinphi-3.0),6.2832));
    float ray = 0.0;
    if (sinterm == 0.0) {
        ray = 0.0;
    } else {
        ray = sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm;
    }
    ray *= 0.2 * exp(-4 * pow(r, 2.5));

    float fogEffect =  (1.0-smoothstep(0.4, 0.8, transmission));
    float halo = 0.2 * exp(-4.0 * pow(r, 2.5));
    float base = exp(-4 * pow(r * haloSize, 2.5));

    // Combine:
    //  base: the central disc of the light
    //  halo: the faint discs around the light
    //  ray: star-like structures around the disk
    float intensity = clamp(ray + base + halo, 0.0, 1.0) + 0.1 * fogEffect * (1.0-smoothstep(0.3, 0.6, r));

    return intensity;
}


void main()
{
    float dist = length(relativePosition);
    float delta_z = hazeLayerAltitude - eye_alt;
    float transmission;
    float vAltitude;
    float delta_zv;
    float H;
    float distance_in_layer;
    float transmission_arg;

    if (use_IR_vision) {discard;}

    float noise = Noise2D(rawPosition.xy ,1.0);

    // angle with horizon
    float ct = dot(vec3(0.0, 0.0, 1.0), relativePosition)/dist;

    // we solve the geometry what part of the light path is attenuated normally and what is through the haze layer
    if (delta_z > 0.0) // we're inside the layer
	{
        if (ct < 0.0) {
            // we look down
    		distance_in_layer = dist;
	    	vAltitude = min(distance_in_layer,min(visibility, avisibility)) * ct;
  		    delta_zv = delta_z - vAltitude;
		} else {
            // we may look through upper layer edge
		    H = dist * ct;
    		if (H > delta_z) {
                distance_in_layer = dist/H * delta_z;
            } else {
                distance_in_layer = dist;
            }
		    vAltitude = min(distance_in_layer,visibility) * ct;
  		    delta_zv = delta_z - vAltitude;
		}
	} else {
        // we see the layer from above, delta_z < 0.0
    	H = dist * -ct;
        if (H  < (-delta_z)) {
            // we don't see into the layer at all, aloft visibility is the only fading
		    distance_in_layer = 0.0;
    		delta_zv = 0.0;
		} else {
            vAltitude = H + delta_z;
		    distance_in_layer = vAltitude/H * dist;
    		vAltitude = min(distance_in_layer,visibility) * (-ct);
    		delta_zv = vAltitude;
		}
	}

    // ground haze cannot be thinner than aloft visibility in the model,
    // so we need to use aloft visibility otherwise

    transmission_arg = (dist-distance_in_layer)/avisibility;
    if (visibility < avisibility) {
    	transmission_arg = transmission_arg + (distance_in_layer/visibility);
	} else {
        transmission_arg = transmission_arg + (distance_in_layer/avisibility);
	}

    transmission = fog_func(transmission_arg);
    float lightArg = terminator/100000.0;
    float attenuationScale = 1.0 + 20.0 * (1.0 -smoothstep(-15.0, 0.0, lightArg));
    float dist_att = exp(-dist/200.0/lightSize/attenuationScale);

    float intensity = light_sprite(gl_TexCoord[0].st, transmission, noise);
    vec3 light_color = gl_Color.rgb;

    if (use_night_vision) {
	    light_color.rgb = vec3 (0.0, 1.0, 0.0);
    }

    light_color = mix(light_color, vec3 (1.0, 1.0, 1.0), 0.5 * intensity * intensity);
    gl_FragColor =   vec4 (clamp(light_color.rgb, 0.0, 1.0), intensity * transmission * dist_att);
}
