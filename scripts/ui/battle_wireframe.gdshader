shader_type canvas_item;
// Battle-only raw wireframe. Unlike Forge's shared blueprint shader, transparent
// gaps remain transparent so the raw silhouette meets at the scan plane.
uniform vec4 ink_color : source_color = vec4(0.30, 0.93, 1.0, 1.0);
uniform float ink_gain = 1.0;
uniform float alpha_edge_gain = 0.0;
float luminance(vec3 value) { return dot(value, vec3(0.299, 0.587, 0.114)); }
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 float center = luminance(source.rgb);
 float right = luminance(texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb);
 float down = luminance(texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb);
 float alpha_right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;
 float alpha_down = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
 float ink = clamp(abs(center-right)+abs(center-down)*1.8+center*.10,0.0,1.0);
 float alpha_edge = max(abs(source.a - alpha_right), abs(source.a - alpha_down));
 float outlined = max(ink, alpha_edge * alpha_edge_gain);
 float alpha = source.a * smoothstep(0.18, 0.62, outlined * ink_gain);
 COLOR = vec4(ink_color.rgb, alpha);
}
