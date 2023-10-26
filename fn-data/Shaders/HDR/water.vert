#version 330 core

layout(location = 0) in vec4 pos;
layout(location = 3) in vec4 multiTexCoord0;

out VS_OUT {
    vec2 water_texcoord;
    vec2 topo_texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
} vs_out;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewMatrixInverse;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat4 osg_ViewMatrixInverse;
uniform mat3 osg_NormalMatrix;

// constants for the cartesian to geodetic conversion.
const float a = 6378137.0;                  //float a = equRad;
const float squash = 0.9966471893352525192801545;
const float latAdjust = 0.9999074159800018; //geotiff source for the depth map
const float lonAdjust = 0.9999537058469516; //actual extents: +-180.008333333333326/+-90.008333333333340

void get_rotation_matrix(float angle, out mat4 rotmat)
{
    rotmat = mat4(cos(angle), -sin(angle), 0.0, 0.0,
                  sin(angle),  cos(angle), 0.0, 0.0,
                  0.0       ,  0.0       , 1.0, 0.0,
                  0.0       ,  0.0       , 0.0, 1.0);
}

vec2 get_topo_coords(vec3 rawPos)
{
    float e2 = abs(1.0 - squash * squash);
    float ra2 = 1.0/(a * a);
    float e4 = e2 * e2;
    float XXpYY = rawPos.x * rawPos.x + rawPos.y * rawPos.y;
    float Z = rawPos.z;
    float sqrtXXpYY = sqrt(XXpYY);
    float p = XXpYY * ra2;
    float q = Z*Z*(1.0-e2)*ra2;
    float r = 1.0/6.0*(p + q - e4);
    float s = e4 * p * q/(4.0*r*r*r);
    if ( s >= 2.0 && s <= 0.0)
        s = 0.0;
    float t = pow(1.0+s+sqrt(s*2.0+s*s), 1.0/3.0);
    float u = r + r*t + r/t;
    float v = sqrt(u*u + e4*q);
    float w = (e2*u+ e2*v-e2*q)/(2.0*v);
    float k = sqrt(u+v+w*w)-w;
    float D = k*sqrtXXpYY/(k+e2);

    vec2 NormPosXY = normalize(rawPos.xy);
    vec2 NormPosXZ = normalize(vec2(D, rawPos.z));
    float signS = sign(rawPos.y);
    if (-0.00015 <= rawPos.y && rawPos.y<=.00015)
        signS = 1.0;
    float signT = sign(rawPos.z);
    if (-0.0002 <= rawPos.z && rawPos.z<=.0002)
        signT = 1.0;
    float cosLon = dot(NormPosXY, vec2(1.0,0.0));
    float cosLat = dot(abs(NormPosXZ), vec2(1.0,0.0));

    vec2 coord;
    coord.s = signS * lonAdjust * degrees(acos(cosLon))/180.;
    coord.t = signT * latAdjust * degrees(acos(cosLat))/90.;
    return coord * 0.5 + 0.5;
}

void main()
{
    gl_Position = osg_ModelViewProjectionMatrix * pos;
    vs_out.water_texcoord = multiTexCoord0.st;
    vs_out.vertex_normal = osg_NormalMatrix * vec3(0.0, 0.0, 1.0);
    vs_out.view_vector = (osg_ModelViewMatrix * pos).xyz;
    vec3 raw_pos = (osg_ViewMatrixInverse * vec4(vs_out.view_vector, 1.0)).xyz;
    // Geodesy lookup for depth map
    vs_out.topo_texcoord = get_topo_coords(raw_pos);
}
