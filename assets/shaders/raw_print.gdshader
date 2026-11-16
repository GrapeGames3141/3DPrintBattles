shader_type canvas_item;
// Shows a painted creature as a raw, unpainted print: one pale filament colour
// with layer lines. Used for cards you do not own yet, the picture on a Basic
// pack and profile pictures, so no separate "raw" image is shipped.

uniform float lines = 120.0;   // layer lines down the whole texture

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float band = 0.9 + 0.1 * step(0.5, fract(UV.y * lines));
	COLOR = vec4(vec3(0.97, 0.98, 1.0) * (0.35 + lum * 0.7) * band, c.a);
}
