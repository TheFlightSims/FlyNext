#version 330 core

out vec4 ap_color;

// 3dcloud_common.vert
void cloud_common_vert(out vec4 vs_pos, out vec4 ws_pos);
// aerial_perspective_envmap.glsl
vec4 get_aerial_perspective(vec3 pos);

void main()
{
    vec4 vs_pos, ws_pos;
    cloud_common_vert(vs_pos, ws_pos);

    ap_color = get_aerial_perspective(ws_pos.xyz);
}
