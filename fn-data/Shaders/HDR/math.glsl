#version 330 core

/*
 * Due to how GLSL shader linking works, we cannot share #defines or constants
 * across multiple shaders. As a workaround, we create functions that return
 * the constants. There should be no performance impact due to this because the
 * compiler inlines the function calls.
 */
float M_PI()    { return 3.14159265358979323846; }  // pi
float M_2PI()   { return 6.28318530717958647692; }  // 2*pi
float M_4PI()   { return 12.5663706143591729539; }  // 4*pi
float M_PI_2()  { return 1.57079632679489661923; }  // pi/2
float M_PI_4()  { return 0.78539816339744830962; }  // pi/4
float M_1_PI()  { return 0.31830988618379067154; }  // 1/pi
float M_1_4PI() { return 0.07957747154594766788; }  // 1/(4*pi)

float sqr(float x) {
    return x * x;
}

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

float safe_sqrt(float x) {
    return sqrt(max(x, 0.0));
}

float safe_acos(float x) {
    return acos(clamp(x, -1.0, 1.0));
}

float pow5(float x) {
    float x2 = x*x;
    return x2 * x2 * x;
}

/*
 * Random number between 0 and 1, using interleaved gradient noise.
 * uv must not be normalized.
 */
float interleaved_gradient_noise(vec2 uv) {
    const vec3 m = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(m.z * fract(dot(uv, m.xy)));
}
