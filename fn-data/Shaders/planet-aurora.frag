// -*-C++-*-

// Ambient term comes in gl_Color.rgb.
#version 120

varying vec3 vertex;
varying vec3 relVec;
varying vec3 normal;


uniform float strength;
uniform float ray_factor;
uniform float upper_alt_factor;
uniform float penetration_factor;
uniform float patchiness;
uniform float afterglow;
uniform float arc_id;
uniform float osg_SimulationTime;

float Noise2D(in vec2 coord, in float wavelength);
vec3 filter_combined (in vec3 color) ;

void main()
{



float vCoord = abs(vertex.z) - 0.02 * arc_id;



float aurora_time = 0.001 * osg_SimulationTime + arc_id;  

float noise_01 = Noise2D( vec2(vertex.x +aurora_time, vertex.y), 0.05);
float blend_factor = smoothstep(0.935, 0.955, vCoord - 0.001 * noise_01 - 0.02 * (1.0-upper_alt_factor));

float blend_low = smoothstep(0.915, 0.925, vCoord - 0.001 * noise_01-0.00250 * penetration_factor);

noise_01 = smoothstep(0.0 + 0.25 * patchiness, 1.0 - 0.25 *patchiness, noise_01 - 0.5 * (1.0-strength) * patchiness);

float noise_02 = 0.7  + 0.3 *  Noise2D( vec2 (vertex.x +vertex.y, aurora_time), 0.002);
noise_02 = mix(0.85, noise_02 , min((1.0-blend_factor) * ray_factor, 1.0));

float smoothness = 0.01 + 0.02 * (1.0 - ray_factor);

float noise_03 = 0.05 * (0.5 -  Noise2D ( vec2 (vertex.x + vertex.y, 2.0 *  aurora_time), smoothness));
noise_03 = mix(0.0, noise_03, upper_alt_factor);
 

vCoord += 0.00250 * penetration_factor;

float vStrength = smoothstep(0.92, 0.94, vCoord) * (1.0 - smoothstep(0.94, 0.95 + 0.1 * upper_alt_factor, vCoord+noise_03));

vec3 auroraColor1 = vec3 (0.0, 0.2, 0.1);
vec3 auroraColor2 = vec3 (0.2, 0.0, 0.05);
vec3 auroraColor3 = vec3 (0.8, 0.3, 0.4);



vec3 auroraColor = mix(auroraColor1, auroraColor2, blend_factor);
auroraColor = mix(auroraColor3, auroraColor, blend_low);

float fade_factor = smoothstep(0.94, 0.97, vCoord - 0.001 * noise_01 - 0.02 * (1.0-upper_alt_factor));
fade_factor = mix(1.0, fade_factor, afterglow);

float view_angle = abs(dot(normalize(relVec), normalize(normal)));

float angStrength = smoothstep(0.2, 0.6, view_angle);


float auroraStrength = vStrength * angStrength * noise_01 * noise_02 * strength * fade_factor;

vec3 finalColor = vec3 (auroraColor.x, auroraColor.y, auroraColor.z);
finalColor.rgb = filter_combined(finalColor.rgb);

gl_FragColor = vec4(finalColor.r, finalColor.g, finalColor.b, auroraStrength);
}
