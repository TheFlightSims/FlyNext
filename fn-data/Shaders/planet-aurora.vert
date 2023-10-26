#version 120

varying vec3 vertex;
varying vec3 normal;
varying vec3 relVec;

uniform float osg_SimulationTime;
uniform float arc_id;


void main()
{
	
    normal = gl_Normal;
    vertex = gl_Vertex.xyz;
    vec3 ep = (gl_ModelViewMatrixInverse * vec4 (0.0, 0.0, 0.0, 1.0)).xyz;
    relVec = vertex - ep;
	
	vec4 vert_out = gl_Vertex;
	
	float ang = dot(vert_out.xy, vec2 (0.0, 1.0));
	
	vert_out.x *= (1.0 + 0.05 * sin(ang + 0.1 * osg_SimulationTime + arc_id));
	vert_out.y *= (1.0 + 0.05 * sin(ang + 0.12 * osg_SimulationTime + arc_id));

	
	gl_Position = gl_ModelViewProjectionMatrix * vert_out;
}
