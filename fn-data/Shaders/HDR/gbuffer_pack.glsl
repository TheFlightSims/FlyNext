#version 330 core

layout(location = 0) out vec4 out_gbuffer0;
layout(location = 1) out vec4 out_gbuffer1;
layout(location = 2) out vec4 out_gbuffer2;
layout(location = 3) out vec3 out_gbuffer3;

// normal_encoding.glsl
vec2 encode_normal(vec3 n);

/*
 * Write the given surface properties to the G-buffer.
 * See the HDR pipeline definition in $FG_ROOT/Compositor/HDR/hdr.xml for the
 * G-buffer layout.
 */
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id)
{
    out_gbuffer0.rg  = encode_normal(normal);
    out_gbuffer0.b   = roughness;
    out_gbuffer0.a   = float(mat_id) * (1.0 / 3.0);
    out_gbuffer1.rgb = base_color;
    out_gbuffer1.a   = metallic;
    out_gbuffer2.rgb = vec3(0.0); // unused
    out_gbuffer2.a   = occlusion;
    out_gbuffer3.rgb = emissive;
}
