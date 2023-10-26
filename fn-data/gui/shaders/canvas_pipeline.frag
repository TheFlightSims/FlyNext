// -*-C++-*-
#version 330 core

#define PAINT_TYPE_COLOR            0x1B00
#define PAINT_TYPE_LINEAR_GRADIENT  0x1B01
#define PAINT_TYPE_RADIAL_GRADIENT  0x1B02
#define PAINT_TYPE_PATTERN          0x1B03

#define DRAW_IMAGE_NORMAL           0x1F00
#define DRAW_IMAGE_MULTIPLY         0x1F01

#define DRAW_MODE_PATH              0
#define DRAW_MODE_IMAGE             1

out vec4 fragColor;

in vec2 texImageCoord;
in vec2 paintCoord;

uniform int drawMode;
uniform int imageMode;
uniform int paintType;
uniform vec4 paintColor;
uniform vec2 paintParams[3];
uniform vec4 scaleFactorBias[2];
uniform sampler2D imageSampler;
uniform sampler2D rampSampler;
uniform sampler2D patternSampler;

float linear_gradient(vec2 fragCoord, vec2 p0, vec2 p1){

    float x  = fragCoord.x;
    float y  = fragCoord.y;
    float x0 = p0.x;
    float y0 = p0.y;
    float x1 = p1.x;
    float y1 = p1.y;
    float dx = x1 - x0;
    float dy = y1 - y0;

    return
        ( dx * (x - x0) + dy * (y - y0) )
     /  ( dx*dx + dy*dy );
}

float radial_gradient(vec2 fragCoord, vec2 centerCoord, vec2 focalCoord, float r){

    float x   = fragCoord.x;
    float y   = fragCoord.y;
    float cx  = centerCoord.x;
    float cy  = centerCoord.y;
    float fx  = focalCoord.x;
    float fy  = focalCoord.y;
    float dx  = x - fx;
    float dy  = y - fy;
    float dfx = fx - cx;
    float dfy = fy - cy;

    return
        ( (dx * dfx + dy * dfy) + sqrt(r*r*(dx*dx + dy*dy) - pow(dx*dfy - dy*dfx, 2.0)) )
     /  ( r*r - (dfx*dfx + dfy*dfy) );
}

void main()
{
    vec4 col;

    switch(paintType){
    case PAINT_TYPE_LINEAR_GRADIENT:
        {
            vec2  x0 = paintParams[0];
            vec2  x1 = paintParams[1];
            float factor = linear_gradient(paintCoord, x0, x1);
            col = texture(rampSampler, vec2(factor, 0.5));
        }
        break;
    case PAINT_TYPE_RADIAL_GRADIENT:
        {
            vec2  center = paintParams[0];
            vec2  focal  = paintParams[1];
            float radius = paintParams[2].x;
            float factor = radial_gradient(paintCoord, center, focal, radius);
            col = texture(rampSampler, vec2(factor, 0.5));
        }
        break;
    case PAINT_TYPE_PATTERN:
        {
            float width  = paintParams[0].x;
            float height = paintParams[0].y;
            vec2  texCoord = vec2(paintCoord.x / width, paintCoord.y / height);
            col = texture(patternSampler, texCoord);
        }
        break;
    default:
    case PAINT_TYPE_COLOR:
        col = paintColor;
        break;
    }

    if(drawMode == DRAW_MODE_IMAGE) {
        col = texture(imageSampler, texImageCoord)
                  * (imageMode == DRAW_IMAGE_MULTIPLY ? col : vec4(1.0, 1.0, 1.0, 1.0));
    }

    fragColor = col * scaleFactorBias[0] + scaleFactorBias[1];
}
