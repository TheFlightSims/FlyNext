// WS30 VERTEX SHADER.  Very basic
// -*-C++-*-
#version 120

// Shader that uses OpenGL state values to do per-pixel lighting
//
// The only light used is gl_LightSource[0], which is assumed to be
// directional.
//
// Colors are not assigned in this shader, as they will come from
// the landclass lookup in the fragment shader.


#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2


// The constant term of the lighting equation that doesn't depend on
// the surface normal is passed in gl_{Front,Back}Color. The alpha
// component is set to 1 for front, 0 for back in order to work around
// bugs with gl_FrontFacing in the fragment shader.
varying vec3 normal;
varying vec4 ecPosition;

// See Shaders/shadows-include.vert
void setupShadows(vec4 eyeSpacePos);

void main()
{
    gl_Position = ftransform();
    ecPosition = gl_ModelViewMatrix * gl_Vertex;

    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    normal = gl_NormalMatrix * gl_Normal;

    // Another hack for supporting two-sided lighting without using
    // gl_FrontFacing in the fragment shader.
    gl_FrontColor.a = 1.0;
    gl_BackColor.a = 0.0;
    setupShadows(ecPosition);
}




