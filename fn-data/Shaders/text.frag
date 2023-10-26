#version 120

uniform sampler2D glyphTexture;

varying vec4 diffuse_term;
varying vec3 normal;
varying vec4 ecPosition;

////fog "include" /////
vec3 fog_Func(vec3 color, int type);
//////////////////////

void main()
{
    float alpha = texture2D(glyphTexture, gl_TexCoord[0].st).a;
    if (alpha == 0.0) discard;

    float NdotL, NdotHV, fogFactor;
    vec4 color = gl_Color;
    vec3 lightDir = gl_LightSource[0].position.xyz;
    vec3 halfVector = gl_LightSource[0].halfVector.xyz;
    vec4 fragColor;
    vec4 specular = vec4(0.0);

    NdotL = dot(normal, lightDir);
    if (NdotL > 0.0) {
        color += diffuse_term * NdotL;
        NdotHV = max(dot(normal, halfVector), 0.0);
        if (gl_FrontMaterial.shininess > 0.0)
            specular.rgb = (gl_FrontMaterial.specular.rgb
                            * gl_LightSource[0].specular.rgb
                            * pow(NdotHV, gl_FrontMaterial.shininess));
    }
    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    color = clamp(color, 0.0, 1.0);

    fragColor = color + specular;
    fragColor = vec4(fragColor.rgb, fragColor.a * alpha);

    fragColor.rgb = fog_Func(fragColor.rgb, 0);
    gl_FragColor = fragColor;
}
