// -*-C++-*-
// 
// Chris Ringeval (Novermber 2021)
//

#version 120


uniform vec3 fg_CameraWorldUp;
uniform mat4 osg_ViewMatrix;

varying vec3 eye2VertInEyeSpace;
varying vec3 eye2ZenithInEyeSpace;
varying vec3 eye2MoonInEyeSpace;

uniform vec3 fg_MoonDirection;


void main()
{

  eye2VertInEyeSpace = (gl_ModelViewMatrix * gl_Vertex - vec4(0.0,0.0,0.0,1.0)).xyz;
  eye2ZenithInEyeSpace = (osg_ViewMatrix * vec4(fg_CameraWorldUp,0.0)).xyz;
  eye2MoonInEyeSpace = fg_MoonDirection;  
  
  gl_Position = ftransform();
  gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}

