#version 120

varying vec4 diffuse_term;
varying vec3 normal;
varying vec4 ecPosition;

void main()
{
    gl_Position = ftransform();
    ecPosition = gl_ModelViewMatrix * gl_Vertex;
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    normal = gl_NormalMatrix * gl_Normal;
    diffuse_term = gl_FrontMaterial.diffuse * gl_LightSource[0].diffuse;
    gl_FrontColor = gl_FrontMaterial.emission + gl_FrontMaterial.ambient *
        (gl_LightModel.ambient + gl_LightSource[0].ambient);
}
