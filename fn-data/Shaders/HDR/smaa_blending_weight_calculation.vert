/**
 * Adaptation of SMAA (Enhanced Subpixel Morphological Antialiasing)
 * for FlightGear.
 * See http://www.iryoku.com/smaa/ for details.
 * Licensed under the MIT license, see below.
 */

/**
 * Copyright (C) 2013 Jorge Jimenez (jorge@iryoku.com)
 * Copyright (C) 2013 Jose I. Echevarria (joseignacioechevarria@gmail.com)
 * Copyright (C) 2013 Belen Masia (bmasia@unizar.es)
 * Copyright (C) 2013 Fernando Navarro (fernandn@microsoft.com)
 * Copyright (C) 2013 Diego Gutierrez (diegog@unizar.es)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. As clarification, there
 * is no requirement that the copyright notice and permission be included in
 * binary distributions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#version 330 core

out vec2 texcoord;
out vec2 pixcoord;
out vec4 v_offset[3];

uniform vec4 fg_Viewport;

#define mad(a, b, c) (a * b + c)
#define SMAA_RT_METRICS vec4(1.0 / fg_Viewport.z, 1.0 / fg_Viewport.w, fg_Viewport.z, fg_Viewport.w)
#define SMAA_MAX_SEARCH_STEPS 16

void main()
{
    vec2 pos = vec2(gl_VertexID % 2, gl_VertexID / 2) * 4.0 - 1.0;
    texcoord = pos * 0.5 + 0.5;
    gl_Position = vec4(pos, 0.0, 1.0);

    pixcoord = texcoord * SMAA_RT_METRICS.zw;

    // We will use these offsets for the searches later on (see @PSEUDO_GATHER4):
    v_offset[0] = mad(SMAA_RT_METRICS.xyxy, vec4(-0.25, -0.125, 1.25, -0.125), texcoord.xyxy);
    v_offset[1] = mad(SMAA_RT_METRICS.xyxy, vec4(-0.125,-0.25, -0.125, 1.25 ), texcoord.xyxy);

    // And these for the searches, they indicate the ends of the loops:
    v_offset[2] = mad(SMAA_RT_METRICS.xxyy,
                     vec4(-2.0, 2.0, -2.0, 2.0) * float(SMAA_MAX_SEARCH_STEPS),
                     vec4(v_offset[0].xz, v_offset[1].yw));
}
