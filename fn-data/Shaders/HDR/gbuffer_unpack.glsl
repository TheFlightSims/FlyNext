#version 330 core

uniform sampler2D gbuffer0_tex;
uniform sampler2D gbuffer1_tex;
uniform sampler2D gbuffer2_tex;
uniform sampler2D gbuffer3_tex;

// normal_encoding.glsl
vec3 decode_normal(vec2 f);

/*
 * Read the given surface properties from the G-Buffer.
 * See the HDR pipeline definition in $FG_ROOT/Compositor/HDR/hdr.xml for the
 * G-buffer layout.
 */
void gbuffer_unpack(in vec2 texcoord,
                    out vec3 normal, out vec3 base_color, out float metallic,
                    out float roughness, out float occlusion, out vec3 emissive,
                    out uint mat_id)
{
    vec4 gbuffer0 = texture(gbuffer0_tex, texcoord);
    vec4 gbuffer1 = texture(gbuffer1_tex, texcoord);
    vec4 gbuffer2 = texture(gbuffer2_tex, texcoord);
    vec3 gbuffer3 = texture(gbuffer3_tex, texcoord).rgb;

    normal     = decode_normal(gbuffer0.rg);
    roughness  = gbuffer0.b;
    mat_id     = uint(gbuffer0.a * 3.0);
    base_color = gbuffer1.rgb;
    metallic   = gbuffer1.a;
    //           gbuffer2.rgb unused
    occlusion  = gbuffer2.a;
    emissive   = gbuffer3.rgb;
}
