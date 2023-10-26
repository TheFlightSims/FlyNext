#version 330 core
#extension GL_EXT_draw_instanced : enable

layout(location = 0)  in vec4 pos;
layout(location = 1)  in vec3 normal;
layout(location = 2)  in vec4 vertex_color;
layout(location = 3)  in vec4 multitexcoord0;
layout(location = 6)  in vec3 instancePosition; // (x,y,z)
layout(location = 7)  in vec3 instanceScale ;   // (width, depth, height)
layout(location = 10) in vec3 attrib1;          // Generic packed attributes
layout(location = 11) in vec3 attrib2;

out VS_OUT {
    vec2 texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
} vs_out;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;

const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;

vec3 float2vec(float value)
{
    vec3 val;
    val.x = mod(value, c_precisionp1) / c_precision;
    val.y = mod(floor(value / c_precisionp1), c_precisionp1) / c_precision;
    val.z = floor(value / (c_precisionp1 * c_precisionp1)) / c_precision;
    return val;
}

void main()
{
    // Unpack generic attributes
    vec3 attr1 = float2vec(attrib1.x);
    vec3 attr2 = float2vec(attrib1.z);
    vec3 attr3 = float2vec(attrib2.x);

    // Determine the rotation for the building.
    float sr = sin(6.28 * attr1.x);
    float cr = cos(6.28 * attr1.x);

    vec3 position = pos.xyz;
    // Adjust the very top of the roof to match the rooftop scaling. This shapes
    // the rooftop - gambled, gabled etc.  These vertices are identified by
    // vertex_color.z
    position.x = (1.0 - vertex_color.z) * position.x + vertex_color.z
        * ((position.x + 0.5) * attr3.z - 0.5);
    position.y = (1.0 - vertex_color.z) * position.y + vertex_color.z
        * (position.y * attrib2.y );

    // Adjust pitch of roof to the correct height. These vertices are identified by gl_Color.z
    // Scale down by the building height (instanceScale.z) because
    // immediately afterwards we will scale UP the vertex to the correct scale.
    position.z = position.z + vertex_color.z * attrib1.y / instanceScale.z;
    position = position * instanceScale.xyz;

    // Rotation of the building and movement into position
    position.xy = vec2(dot(position.xy, vec2(cr, sr)), dot(position.xy, vec2(-sr, cr)));
    position = position + instancePosition.xyz;

    gl_Position = osg_ModelViewProjectionMatrix * vec4(position, 1.0);

    // Texture coordinates are stored as:
    // - a separate offset (x0, y0) for the wall (wtex0x, wtex0y),
    //   and roof (rtex0x, rtex0y)
    // - a semi-shared (x1, y1) so that the front and side of the building can
    //   have different texture mappings
    //
    // The vertex color value selects between them:
    // gl_Color.x=1 indicates front/back walls
    // gl_Color.y=1 indicates roof
    // gl_Color.z=1 indicates top roof vertexs (used above)
    // gl_Color.a=1 indicates sides
    // Finally, the roof texture is on the right of the texture sheet
    float wtex0x = attr1.y; // Front/Side texture X0
    float wtex0y = attr1.z; // Front/Side texture Y0
    float rtex0x = attr2.z; // Roof texture X0
    float rtex0y = attr3.x; // Roof texture Y0
    float wtex1x = attr2.x; // Front/Roof texture X1
    float stex1x = attr3.y; // Side texture X1
    float wtex1y = attr2.y; // Front/Roof/Side texture Y1
    vec2 tex0 = vec2(sign(multitexcoord0.x) * (vertex_color.x*wtex0x + vertex_color.y*rtex0x + vertex_color.a*wtex0x),
                     vertex_color.x*wtex0y + vertex_color.y*rtex0y + vertex_color.a*wtex0y);

    vec2 tex1 = vec2(vertex_color.x*wtex1x + vertex_color.y*wtex1x + vertex_color.a*stex1x,
                     wtex1y);

    vs_out.texcoord.x = tex0.x + multitexcoord0.x * tex1.x;
    vs_out.texcoord.y = tex0.y + multitexcoord0.y * tex1.y;

    // Rotate the normal.
    vec3 N = normal;
    N.xy = vec2(dot(N.xy, vec2(cr, sr)), dot(N.xy, vec2(-sr, cr)));
    vs_out.vertex_normal = osg_NormalMatrix * N;

    vs_out.view_vector = (osg_ModelViewMatrix * vec4(position, 1.0)).xyz;
}
