#version 330 core

layout(location = 0) out vec4 fragColor;

in VS_OUT {
    vec2 texcoord;
    vec2 orthophoto_texcoord;
    vec3 vertex_normal;
    vec3 world_vector;
} fs_in;

uniform sampler2D color_tex;
uniform sampler2D orthophoto_tex;

uniform bool orthophotoAvailable;
uniform vec3 fg_SunDirectionWorld;
uniform vec4 fg_Viewport;

// math.glsl
float M_1_PI();
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);
// sun.glsl
vec3 get_sun_radiance_sea_level();
// aerial_perspective_envmap.glsl
vec4 get_aerial_perspective(vec3 pos);
vec3 mix_aerial_perspective(vec3 color, vec4 ap);

void main()
{
    vec3 texel = texture(color_tex, fs_in.texcoord).rgb;
    if (orthophotoAvailable) {
        vec4 sat_texel = texture(orthophoto_tex, fs_in.orthophoto_texcoord);
        if (sat_texel.a > 0.0) {
            texel.rgb = sat_texel.rgb;
        }
    }

    vec3 color = eotf_inverse_sRGB(texel);
    vec3 sun_radiance = get_sun_radiance_sea_level();

    vec3 N = normalize(fs_in.vertex_normal);
    float NdotL = max(dot(N, fg_SunDirectionWorld), 1e-4);

    // Assume a perfectly diffuse Lambertian surface
    color = M_1_PI() * color * sun_radiance * NdotL;

    vec4 ap = get_aerial_perspective(fs_in.world_vector);
    color = mix_aerial_perspective(color, ap);

    fragColor = vec4(color, 1.0);
}
