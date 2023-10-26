#version 330 core

out vec4 ap_color;

// 3dcloud_common.vert
void cloud_common_vert(out vec4 vs_pos, out vec4 ws_pos);
// aerial_perspective.glsl
vec4 get_aerial_perspective(vec2 coord, float depth);

void main()
{
    vec4 vs_pos, ws_pos;
    cloud_common_vert(vs_pos, ws_pos);

    // Perspective division and scale to [0, 1] to get the screen position
    // of the vertex.
    vec2 coord = (gl_Position.xy / gl_Position.w) * 0.5 + 0.5;
    ap_color = get_aerial_perspective(coord, length(vs_pos.xyz));
}
