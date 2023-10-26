// -*-C++-*-
#version 120

uniform sampler2D texture;

uniform float color_base_r;
uniform float color_base_g;
uniform float color_base_b;

uniform float color_alt_r;
uniform float color_alt_g;
uniform float color_alt_b;

uniform float visibility;
uniform float avisibility;
uniform float hazeLayerAltitude;
uniform float eye_alt;
uniform float terminator;
uniform float scattering;

uniform float osg_SimulationTime;


varying vec3 vertex;
varying vec3 relPos;
varying vec3 normal;

const float terminator_width = 200000.0;

float Noise2D(in vec2 coord, in float wavelength);
float VoronoiNoise2D(in vec2 coord, in float wavelength, in float xrand, in float yrand);
float fog_func (in float targ, in float alt);

float light_func (in float x, in float a, in float b, in float c, in float d, in float e)
{
//x = x - 0.5;

// use the asymptotics to shorten computations
if (x < -15.0) {return 0.0;}

return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}


void main()
{

float noise = 0.0;


vec3 color_base = vec3 (color_base_r, color_base_g, color_base_b);    
vec3 color_alt = vec3 (color_alt_r, color_alt_g, color_alt_b);    
vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);


vec3 viewDir = normalize(relPos);


vec2 lookup_coords = vertex.yz;
lookup_coords.x += 0.03* osg_SimulationTime;

float domain_size = 0.05;
float r = length(vertex);

float domain_noise = VoronoiNoise2D(lookup_coords, domain_size, 0.0, 0.0);
domain_noise = domain_noise * (1.0- smoothstep(0.5, 1.0, r));

if (domain_noise < 0.9) {discard;}



// fogging

float dist = length(relPos);
float delta_z = hazeLayerAltitude - eye_alt;
float transmission;
float vAltitude;
float delta_zv;
float H;
float distance_in_layer;
float transmission_arg;

 // angle with horizon
    float ct = dot(vec3(0.0, 0.0, 1.0), relPos)/dist;


    if (delta_z > 0.0) // we're inside the layer
	{
	if (ct < 0.0) // we look down
		{
		distance_in_layer = dist;
		vAltitude = min(distance_in_layer,min(visibility, avisibility)) * ct;
  		delta_zv = delta_z - vAltitude;
		}
	else 	// we may look through upper layer edge
		{
		H = dist * ct;
		if (H > delta_z) {distance_in_layer = dist/H * delta_z;}
		else {distance_in_layer = dist;}
		vAltitude = min(distance_in_layer,visibility) * ct;
  		delta_zv = delta_z - vAltitude;
		}
	}
   else // we see the layer from above, delta_z < 0.0
	{
	H = dist * -ct;
	if (H  < (-delta_z)) 
		{
		distance_in_layer = 0.0;
		delta_zv = 0.0;
		}
	else
		{
		vAltitude = H + delta_z;
		distance_in_layer = vAltitude/H * dist;
		vAltitude = min(distance_in_layer,visibility) * (-ct);
		delta_zv = vAltitude;
		}
	}



    transmission_arg = (dist-distance_in_layer)/avisibility;
    if (visibility < avisibility)
	{
	transmission_arg = transmission_arg + (distance_in_layer/visibility);
	}
   else
	{
	transmission_arg = transmission_arg + (distance_in_layer/avisibility);
	}



    transmission =  fog_func(transmission_arg, 0.0);
    float lightArg = terminator/100000.0;
    float earthShade = 0.6 * (1.0 - smoothstep(-terminator_width+ terminator, terminator_width + terminator, 0.0)) + 0.4;

 vec4 light_diffuse;
    

    light_diffuse.b = light_func(lightArg , 1.330e-05, 0.264, 2.227, 1.08e-05, 1.0);
    light_diffuse.g = light_func(lightArg , 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
    light_diffuse.r = light_func(lightArg, 8.305e-06, 0.161, 3.827, 3.04e-05, 1.0);
    light_diffuse.a = 1.0;

    light_diffuse *=scattering;


    float intensity = length(light_diffuse.rgb); 
    light_diffuse.rgb = intensity * normalize(mix(light_diffuse.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.7,earthShade) ));


vec4 domainTexel;


if (domain_noise > 0.9) {domainTexel = vec4 (1.0, 1.0, 1.0, 1.0);} 
else {domainTexel = vec4 (0.0, 0.0, 0.0, 0.0);}



vec2 coords_raw = lookup_coords/domain_size;
coords_raw += vec2(0.5,0.5);
float coord_int_x = coords_raw.x - fract(coords_raw.x) ;
float coord_int_y = coords_raw.y - fract(coords_raw.y) ;

vec2 domain_coords = vec2 (coords_raw.x - coord_int_x, coords_raw.y - coord_int_y);

float domain_x = coords_raw.x - coord_int_x;

domain_coords.y = clamp(domain_coords.y, 0.05, 0.95);

domain_coords.x *=0.25;

float shape_select = 0.0;

if (domain_noise > 0.975) {shape_select = 0.25;}
else if (domain_noise > 0.95) {shape_select = 0.5;}
else if (domain_noise > 0.925) {shape_select = 0.75;}

float t_fact =  fract(osg_SimulationTime);

if (t_fact > 0.75) {shape_select +=0.75;}
else if (t_fact > 0.5) {shape_select +=0.5;}
else if (t_fact > 0.25) {shape_select +=0.25;}


domain_coords.x += shape_select;

vec4 shapeTexel = texture2D(texture, domain_coords);

color_base.rgb = mix(color_alt.rgb, color_base.rgb, length(shapeTexel.rgb)/1.73);

if ((domain_coords.y < 0.1) || (domain_coords.y > 0.9)) {shapeTexel.a = 0.0;}
if ((domain_x < 0.1) || (domain_x > 0.9)) {shapeTexel.a = 0.0;}

domainTexel.rgb *=  color_base.rgb;

vec4 birdTexel;
birdTexel.rgb = domainTexel.rgb * light_diffuse.rgb;
birdTexel.a = domainTexel.a * shapeTexel.a * transmission;


gl_FragColor =  birdTexel;


}
