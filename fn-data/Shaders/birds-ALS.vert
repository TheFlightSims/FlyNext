// -*-C++-*-

#version 120




varying vec3 vertex;
varying vec3 relPos;
varying vec3 normal;

uniform float osg_SimulationTime;

void main()
{

vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);

  vec4 l  = gl_ModelViewMatrixInverse * vec4(0.0,0.0,1.0,1.0);
  vec3 u = normalize(ep.xyz - l.xyz);

  vec3 absu = abs(u);
  vec3 r = normalize(vec3(-u.y, u.x, 0.0));
  vec3 w = cross(u, r);

vertex = gl_Vertex.xyz;
relPos = vertex - ep.xyz;
normal = gl_NormalMatrix * gl_Normal;

  gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
  gl_Position.xyz = gl_Vertex.x * u;
  gl_Position.xyz += gl_Vertex.y * r;
  gl_Position.xyz += gl_Vertex.z * w;

  gl_Position = gl_ModelViewProjectionMatrix * gl_Position;

//vec4 offset =  gl_ModelViewProjectionMatrix * vec4 (0.05* osg_SimulationTime, 0.0, 0.0, 1.0);

//gl_Position +=offset; 

//gl_Position = ftransform();
gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;

gl_FrontColor = vec4 (1.0,1.0,1.0,1.0);
gl_BackColor = gl_FrontColor;
}


