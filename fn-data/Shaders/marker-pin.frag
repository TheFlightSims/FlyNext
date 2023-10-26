// -*-C++-*-

#version 120

uniform sampler2D texture;

void main()
{
    vec4 color = gl_Color;
    // vec4 color = vec4(1.0, 0.0, 0.0, 1.0);
    vec4 texel;
    vec4 fragColor;

    texel = texture2D(texture, gl_TexCoord[0].st);

    fragColor.rgb = color.rgb;
    fragColor.a = texel.a * color.a;

    gl_FragColor = fragColor;
}

