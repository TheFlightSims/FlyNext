// -*-C++-*-
#version 120

// Shader that takes a list of GL_POINTS and draws a light (point-sprite like
// texture, more accurately a light halo) at the given point. This shader
// provides support for light animations like blinking, time period handling
// for lights on only during night time or in low visiblity and directional
// lighting.
//
// The actual rendering code is inspired from an existing implementation
// found at:
//   FGData commit 9355d464c175bd5d51ba32527180ed4e94e86fbb
//   Shaders/surface-lights-ALS.vert
// with major changes.
//
// Licence: GPL v2+
// Written by Fahim Dalvi, January 2021

attribute vec3 lightParams;
attribute vec4 animationParams;
attribute vec3 directionParams1;
attribute vec2 directionParams2;
uniform float osg_SimulationTime;

uniform float avisibility;
uniform float sun_angle;
uniform float fov;

varying vec3 relativePosition;
varying vec2 rawPosition;

varying float apparentSize;
varying float haloSize;
varying float lightSize;
varying float lightIntensity;

const float epsilon = 1e-7;

// rand2D sourced from noise.frag, since *.vert files
// cannot access functions defined in *.frag files
// Git commit: b8ddf517f4495219da7675d81bed59a378e2d78a
// File: fgdata/Shaders/noise.frag
float rand2D(in vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
    /***************************** Initialization ****************************/
    float random = rand2D(vec2(gl_Vertex.x, gl_Vertex.yz)) * 10;
    float random_1 = floor(random); // random_1 can take 10 values
    float random_2 = fract(random); // random_2 takes the remaining random bits

    /*************** Night and low visibility lights handling ****************/
    int on_period = int(lightParams.z + 0.5); // round() not supported by glsl 1.2
    const float sun_angle_min = 1.57;
    const float sun_angle_max = 1.61;
    float target_sun_angle = sun_angle_min + random_1/10 * (sun_angle_max - sun_angle_min);
    if (on_period == 1 && sun_angle < sun_angle_min) {
        // Lights will switch on exactly at ~89 degree sun angle
        gl_Position = vec4(0.0,0.0,10.0,1.0);
        gl_FrontColor.a = 0.0;
        return;
    } else if (on_period == 2 && sun_angle < target_sun_angle) {
        // Lights will switch on randomly between 90 and 92 degree sun angle
        // corresponding to a ~10 minute period around sunset
        gl_Position = vec4(0.0,0.0,10.0,1.0);
        gl_FrontColor.a = 0.0;
        return;
    } else if (on_period == 3 && (sun_angle < sun_angle_min && avisibility > 5000)) {
        // Lights will switch on exactly at ~89 degree sun angle or when visibility
        // is less than 5000m
        gl_Position = vec4(0.0,0.0,10.0,1.0);
        gl_FrontColor.a = 0.0;
        return;
    }

    /****************************** Animations *******************************/
    float interval = animationParams.x;
    if (interval > 0) {
        float on_portion = animationParams.y;
        float strobe_rate = animationParams.z;
        float offset = animationParams.w;

        // Randomize offset if its less than 0
        if (offset < 0) {
            // rand2D returns a value from 0 to 1, multiplying it with
            // the interval chooses an offset within the entire animation
            // window
            offset = random_2 * interval;
        }

        float strobe_interval = interval/strobe_rate;
        float interval_fraction = mod(osg_SimulationTime + offset, interval)/interval;
        float strobe_fraction = mod(osg_SimulationTime + offset, strobe_interval)/strobe_interval;

        if (interval_fraction > on_portion || (strobe_fraction < 0.5 && strobe_rate > 0.0000001)) {
            gl_Position = vec4(0.0,0.0,10.0,1.0);
            gl_FrontColor.a = 0.0;
            return;
        }
    }

    /***************************** Light visuals *****************************/
    gl_FrontColor = gl_Color;
    gl_Position = ftransform();

    vec4 eyePosition = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
    relativePosition = gl_Vertex.xyz - eyePosition.xyz;
    rawPosition = gl_Vertex.xy;
    float dist = length(relativePosition);
    float angularAttenuationFactor = 1.0;

    /************************** Direction handling ***************************/
    if (directionParams2.x < 359.999999 || directionParams2.y < 359.999999) {
        vec3 eyeVector = normalize(-relativePosition);
        vec3 lightNormal = normalize(directionParams1);
        vec3 upVec = normalize(vec3(0,0,1));

        vec3 horizontalVector, verticalVector;

        if (abs(dot(lightNormal, upVec)) > (1 - epsilon)) {
            // Light direction is directly up or down
            horizontalVector = normalize(vec3(1, 0, 0));
            verticalVector = normalize(vec3(0, 1, 0));
        } else {
            horizontalVector = normalize(cross(lightNormal, upVec));
            verticalVector = normalize(cross(lightNormal, horizontalVector));
        }

        vec3 projectionOnHorizontal = lightNormal;
        vec3 projectionOnVertical = lightNormal;

        if (dot(lightNormal, eyeVector) < (-1 + epsilon)) {
            // If the view direction is directly opposite to the light normal
            projectionOnHorizontal = eyeVector;
            projectionOnVertical =  eyeVector;
        } else {
            // If the view vector is not perpendicular to the horizontal axis
            if (abs(dot(horizontalVector, eyeVector)) > (0 + epsilon)) {
                projectionOnHorizontal = normalize(eyeVector - dot(verticalVector, eyeVector) * verticalVector);
            }

            // If the view vector is not perpendicular to the vertical axis
            if (abs(dot(verticalVector, eyeVector)) > (0 + epsilon)) {
                projectionOnVertical = normalize(eyeVector - dot(horizontalVector, eyeVector) * horizontalVector);
            }
        }

        float horizontalAngle = dot(projectionOnHorizontal, lightNormal);
        float verticalAngle = dot(projectionOnVertical, lightNormal);

        float minHoriz = cos(radians(directionParams2.x * 0.5));
        float minVert = cos(radians(directionParams2.y * 0.5));

        // Light is 0 intensity below [specified angle]
        // Increases softmax-ly between [specified angle] and [1/2 of difference of specified angle and 0] (head on viewing)
        // Light is 1 intensity after [1/2 of difference of specified angle and 0] to [0 degrees]
        // Note: difference of angles is computed linearly after applying the cosine function, but it works well enough as an approximation
        horizontalAngle = smoothstep(minHoriz, minHoriz + (1 - minHoriz)/2.0, horizontalAngle);
        verticalAngle = smoothstep(minVert, minVert + (1 - minVert)/2.0, verticalAngle);
        angularAttenuationFactor = horizontalAngle*verticalAngle;

        // Debug animation code
        // float ra = mod(osg_SimulationTime*30, 20);
        // gl_FrontColor = vec4(verticalAngle, 0, 0, 1);
        // if (ra < 10) {
        //     gl_Position = gl_ModelViewProjectionMatrix * (gl_Vertex + (ra)/2 * normalize(vec4(directionParams1, 0)));
        //     gl_FrontColor = vec4(1.0, 0.0, 0.0, 1.0);
        // } else if (ra < 20) {
        //     // gl_Position = gl_ModelViewProjectionMatrix * (gl_Vertex + (ra-15) * normalize(vec4(proj_on_horizontal, 0)));
        //     // gl_FrontColor = vec4(0.0, 0.0, 1.0, 1.0);
        // } else if (ra < 30) {
        //     // gl_Position = gl_ModelViewProjectionMatrix * (gl_Vertex + (ra-25) * normalize(vec4(vertical_vec, 0)));
        //     gl_FrontColor = vec4(0.0, 1.0, 0.0, 1.0);
        // } else if (ra < 40) {
        //     gl_Position = gl_ModelViewProjectionMatrix * (gl_Vertex + (ra-35) * normalize(vec4(horizontal_vec, 0)));
        //     gl_FrontColor = vec4(0.0, 1.0, 1.0, 1.0);
        // } else {
        //     gl_Position = gl_ModelViewProjectionMatrix * (gl_Vertex + (ra-45) * normalize(vec4(proj_on_vertical, 0)));
        //     gl_FrontColor = vec4(0.0, 0.0, 1.0, 1.0);
        // }
    }

    lightSize = lightParams.x;
    lightIntensity = lightParams.y;

    /********
     * Each light is made up of a base circle, a circular-ish halo around the base and a bunch of
     *  star-like rays
     *  baseLightSize is tuned using reference objects of sizes 10cm, 50cm, 100cm, 500cm and 1000cm
     *   under the assumption that the "bright center" part of the light will be the approximately the
     *   same size as the light itself
     */
    float baseLightSize = lightSize / (dist/80) * 60/fov;


    /********
     *  Decide how big the halo + star like structure can get relative to the actual light size
     *  This has been done by fitting various curve (using random parameter search to fit the
     *  following data):

         dist/intensity -> haloSize
         0/2070 -> 2
         0/15000 -> 2
         1900/2070 -> 10
         33250/15000 -> 30

     * The real world distance to dist mapping is around the following:
         1nm = 1930
         2nm = 3780
         3nm = 5630
         4nm = 7480
         5nm = 9330
    */

    // Various fits that are better at different "zones" of intensity/distance combinations
    // haloSize = 1 + log(1 + 8.207628166987313e-05 + pow(0.00935009645108105 * dist, 0.7229519420159332)) * log(1 + 0.008611494896181404 + pow(9.987873482714503e-08 * lightIntensity, 0.5460367551326879)) * 188.78730222257022;
    // haloSize = 1 + log(1  + pow(0.00344640493737296 * dist, 43.666719413543746)) * log(1 + pow(6.174965900415324e-07 * lightIntensity, 0.1915282228627938)) * log(1 + pow(48.81816078788492 * dist * lightIntensity, 0.39087987152530046)) * 0.03982200390091456;
    // haloSize = 1 + 1 + log(1  + pow(0.003022850828231838 * dist, 81.88510919372303)) * log(1 + pow(2.8538041872684384e-05 * lightIntensity, 0.2798979878622515)) * log(1 + pow(6.125105317094489 * dist * lightIntensity, 9.486990540357818e-06)) * 0.17726981739920522;
    // haloSize = 1 + (log(1 + 0.0009319617220954881 * dist) * log(1 + 0.3853503865089568 * lightIntensity)) * 0.8677850896527736;
    haloSize = 1 + (log(1 + 0.0030356535475020265 * dist) * log(1 + 0.00964994652970935 * lightIntensity)) * 1.1927528593388748;
    apparentSize =  baseLightSize * haloSize * angularAttenuationFactor;

    gl_PointSize = apparentSize;
}
