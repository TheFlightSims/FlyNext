// -*-C++-*-

// Shader that uses OpenGL state values to do per-pixel lighting
//
// The only light used is gl_LightSource[0], which is assumed to be
// directional.
//
// Diffuse colors come from the gl_Color, ambient from the material. This is
// equivalent to osg::Material::DIFFUSE.
#version 120

void main()
{
    gl_Position = ftransform();
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    gl_FrontColor = gl_Color;
    gl_BackColor = gl_Color;
}
