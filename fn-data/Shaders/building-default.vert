// -*-C++-*-

// Shader that uses OpenGL state values to do per-pixel lighting
//
// The only light used is gl_LightSource[0], which is assumed to be
// directional.
//
// Diffuse colors come from the gl_Color, ambient from the material. This is
// equivalent to osg::Material::DIFFUSE.
#version 120
#extension GL_EXT_draw_instanced : enable
#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2

attribute vec3 instancePosition; // (x,y,z)
attribute vec3 instanceScale ;   // (width, depth, height)
attribute vec3 attrib1;          // Generic packed attributes
attribute vec3 attrib2;

// The constant term of the lighting equation that doesn't depend on
// the surface normal is passed in gl_{Front,Back}Color. The alpha
// component is set to 1 for front, 0 for back in order to work around
// bugs with gl_FrontFacing in the fragment shader.
varying vec4 diffuse_term;
varying vec3 normal;
varying vec4 ecPosition;

uniform int colorMode;

////fog "include"////////
//uniform int fogType;
//
//void fog_Func(int type);
/////////////////////////

void setupShadows(vec4 eyeSpacePos);

const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;

vec3 float2vec(float value) {
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

    vec3 position = gl_Vertex.xyz;
    // Adjust the very top of the roof to match the rooftop scaling.  This shapes
    // the rooftop - gambled, gabled etc.  These vertices are identified by gl_Color.z
    position.x = (1.0 - gl_Color.z) * position.x + gl_Color.z * ((position.x + 0.5) * attr3.z - 0.5);
    position.y = (1.0 - gl_Color.z) * position.y + gl_Color.z * (position.y * attrib2.y );

    // Adjust pitch of roof to the correct height. These vertices are identified by gl_Color.z
    // Scale down by the building height (instanceScale.z) because
    // immediately afterwards we will scale UP the vertex to the correct scale.
    position.z = position.z + gl_Color.z * attrib1.y / instanceScale.z;
    position = position * instanceScale.xyz;

    // Rotation of the building and movement into position
    position.xy = vec2(dot(position.xy, vec2(cr, sr)), dot(position.xy, vec2(-sr, cr)));
    position = position + instancePosition.xyz;

    gl_Position = gl_ModelViewProjectionMatrix * vec4(position,1.0);

    // Texture coordinates are stored as:
    // - a separate offset (x0, y0) for the wall (wtex0x, wtex0y), and roof (rtex0x, rtex0y)
    // - a semi-shared (x1, y1) so that the front and side of the building can have
    //   different texture mappings
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
    vec2 tex0 = vec2(sign(gl_MultiTexCoord0.x) * (gl_Color.x*wtex0x + gl_Color.y*rtex0x + gl_Color.a*wtex0x),
                     gl_Color.x*wtex0y + gl_Color.y*rtex0y + gl_Color.a*wtex0y);

    vec2 tex1 = vec2(gl_Color.x*wtex1x + gl_Color.y*wtex1x + gl_Color.a*stex1x,
                     wtex1y);

    gl_TexCoord[0].x = tex0.x + gl_MultiTexCoord0.x * tex1.x;
    gl_TexCoord[0].y = tex0.y + gl_MultiTexCoord0.y * tex1.y;

    // Rotate the normal.
    normal = gl_Normal;
    normal.xy = vec2(dot(normal.xy, vec2(cr, sr)), dot(normal.xy, vec2(-sr, cr)));
    normal = gl_NormalMatrix * normal;

    vec4 ambient_color, diffuse_color;
    if (colorMode == MODE_DIFFUSE) {
        diffuse_color = vec4(1.0,1.0,1.0,1.0);
        ambient_color = gl_FrontMaterial.ambient;
    } else if (colorMode == MODE_AMBIENT_AND_DIFFUSE) {
        diffuse_color = vec4(1.0,1.0,1.0,1.0);
        ambient_color = vec4(1.0,1.0,1.0,1.0);
    } else {
        diffuse_color = gl_FrontMaterial.diffuse;
        ambient_color = gl_FrontMaterial.ambient;
    }

    diffuse_term = diffuse_color * gl_LightSource[0].diffuse;
    vec4 constant_term = gl_FrontMaterial.emission + ambient_color *
        (gl_LightModel.ambient +  gl_LightSource[0].ambient);
    // Super hack: if diffuse material alpha is less than 1, assume a
    // transparency animation is at work
    if (gl_FrontMaterial.diffuse.a < 1.0)
        diffuse_term.a = gl_FrontMaterial.diffuse.a;
    else
        diffuse_term.a = 1.0;
    // Another hack for supporting two-sided lighting without using
    // gl_FrontFacing in the fragment shader.
    gl_FrontColor.rgb = constant_term.rgb;  gl_FrontColor.a = 1.0;
    gl_BackColor.rgb = constant_term.rgb; gl_BackColor.a = 0.0;
    //fogCoord = abs(ecPosition.z / ecPosition.w);
		//fog_Func(fogType);
    ecPosition = gl_ModelViewMatrix * vec4(position, 1.0);
    setupShadows(ecPosition);
}
