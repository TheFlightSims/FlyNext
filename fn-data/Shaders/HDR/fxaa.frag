#version 330 core

layout(location = 0) out vec4 fragColor;

in vec2 texcoord;
in vec4 pos_pos;

uniform sampler2D color_tex;

const float FXAA_SPAN_MAX = 8.0;
const float FXAA_REDUCE_MUL = 1.0/8.0;
const float FXAA_REDUCE_MIN = 1.0/128.0;

void main()
{
    vec2 rcpFrame = 1.0 / textureSize(color_tex, 0);

    vec3 rgbNW = textureLod(color_tex, pos_pos.zw, 0.0).xyz;
    vec3 rgbNE = textureLodOffset(color_tex, pos_pos.zw, 0.0, ivec2(1,0)).xyz;
    vec3 rgbSW = textureLodOffset(color_tex, pos_pos.zw, 0.0, ivec2(0,1)).xyz;
    vec3 rgbSE = textureLodOffset(color_tex, pos_pos.zw, 0.0, ivec2(1,1)).xyz;
    vec3 rgbM  = textureLod(color_tex, pos_pos.xy, 0.0).xyz;

    const vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                          (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
              max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
                  dir * rcpDirMin)) * rcpFrame.xy;

    vec3 rgbA = 0.5 * (
        textureLod(color_tex, pos_pos.xy + dir * (1.0/3.0 - 0.5), 0.0).xyz +
        textureLod(color_tex, pos_pos.xy + dir * (2.0/3.0 - 0.5), 0.0).xyz);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        textureLod(color_tex, pos_pos.xy + dir * (0.0/3.0 - 0.5), 0.0).xyz +
        textureLod(color_tex, pos_pos.xy + dir * (3.0/3.0 - 0.5), 0.0).xyz);

    float lumaB = dot(rgbB, luma);
    if((lumaB < lumaMin) || (lumaB > lumaMax))
        fragColor = vec4(rgbA, 1.0);
    else
        fragColor = vec4(rgbB, 1.0);
}
