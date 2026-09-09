shader_type canvas_item;
// Battle-only raw wireframe. Unlike Forge's shared blueprint shader, transparent
// gaps remain transparent so the raw silhouette meets at the scan plane.
uniform vec4 ink_color : source_color = vec4(0.30, 0.93, 1.0, 1.0);
float luminance(vec3 value) { return dot(value, vec3(0.299, 0.587, 0.114)); }
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 float center = luminance(source.rgb);
 float right = luminance(texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb);
 float down = luminance(texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb);
 float ink = clamp(abs(center-right)+abs(center-down)*1.8+center*.10,0.0,1.0);
 float alpha = source.a * smoothstep(0.18, 0.62, ink);
 COLOR = vec4(ink_color.rgb, alpha);
}
