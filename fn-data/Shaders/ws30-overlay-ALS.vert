// -*-C++-*-
#version 120

//Copied from grass-ALS.vert

// The UV scale controls the grass thickness. Lower numbers thicken the blades
// while higher numbers make them thinner.
#define UV_SCALE 10.0

varying vec3 v_normal;

void main()
{

    gl_Position = gl_Vertex;
		
    // WS2: gl_TexCoord[0] = gl_MultiTexCoord0 * UV_SCALE;
    gl_TexCoord[0] = gl_MultiTexCoord0 * UV_SCALE;

    v_normal = gl_Normal;
}
