#version 330 core

in vec2 texcoord;
in vec4 cloud_color;
in vec4 ap_color;

uniform sampler2D base_tex;

uniform mat4 osg_ProjectionMatrix;
uniform vec4 fg_Viewport;
uniform vec3 fg_SunDirection;

uniform float density = 30.0;
uniform float max_sample_dist = 0.05;

const int STEPS = 8;

// aerial_perspective.glsl
vec3 mix_aerial_perspective(vec3 color, vec4 ap);

vec4 cloud_common_frag()
{
    vec4 base = texture(base_tex, texcoord);

    // Directly discard fragments below a threshold
    if (base.a < 0.02)
        discard;

    // Pixel position in screen space [-1, 1]
    vec2 screen_uv = ((gl_FragCoord.xy - fg_Viewport.xy) / fg_Viewport.zw) * 2.0 - 1.0;

    // XXX: Sun's screen-space position. This should be passed as an uniform
    vec4 sun_dir_screen = osg_ProjectionMatrix * vec4(fg_SunDirection, 0.0);
    sun_dir_screen.xyz /= sun_dir_screen.w;
    sun_dir_screen.xyz = normalize(sun_dir_screen.xyz);

    // Direction from pixel to Sun in screen space
    vec2 sun_dir = screen_uv - sun_dir_screen.xy;
    // Flip the x axis
    sun_dir.x = -sun_dir.x;

    float dt = max_sample_dist / STEPS;

    // 2D ray march along the Sun's direction to estimate the transmittance
    float T = 1.0;
    for (int i = 0; i < STEPS; ++i) {
        float t = (float(i) + 0.5) * dt;
        vec2 uv_t = texcoord - sun_dir * t;
        vec4 texel = texture(base_tex, uv_t);
        // Beer-Lambert's law
        T *= exp(-texel.a * dt * density);
    }

    // When the camera is facing perpendicularly to the Sun, the Sun's
    // screen-space location can tend toward infinity. Fade the effect toward
    // the perpendicular.
    float fade = smoothstep(0.1, 0.5, dot(vec3(0.0, 0.0, -1.0), fg_SunDirection));

    vec4 color = base * cloud_color;
    color.rgb *= base.a * mix(0.5, T, fade);

    color.rgb = mix_aerial_perspective(color.rgb, ap_color);

    return color;
}
