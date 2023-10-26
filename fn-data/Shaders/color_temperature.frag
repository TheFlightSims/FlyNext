// -*-C++-*-
#version 120


vec4 color_temperature (in float T)
{
T *=0.01;

float red;
float green;
float blue;
float alpha;

red = 1.0;

if (T<66.0)
	{
	red = 255.0;
	green = T;
	green = 99.4708025 * log(green) - 161.11956;

	if (T <=19) 
		{blue = 0.0;}
	else
		{
		blue = T-10;
		blue = 138.517731 * log(blue) - 305.044792;
		}

	
	}
else
	{
	red = T - 60.0;
	red = 329.6987 * pow(red, -0.1332047);
	
	green = T - 60.0;
	green = 288.122169 * pow(green, -0.075514);	

	blue = 255.0;
	}

alpha = 0.8 * smoothstep(5.0, 15.0, T);

vec3 color = vec3 (red, green, blue);
color /= 255.0;

color = clamp(color, 0.0, 1.0);

return vec4 (color, alpha);
}
