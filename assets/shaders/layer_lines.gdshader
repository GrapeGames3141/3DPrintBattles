shader_type canvas_item;
// Faint horizontal seams so flat UI plastic reads as a printed part.

uniform float lines = 90.0;
uniform float strength = 0.10;

void fragment() {
	float t = fract(UV.y * lines);
	float seam = 1.0 - smoothstep(0.0, 0.3, t) * smoothstep(1.0, 0.7, t);
	COLOR = vec4(0.0, 0.0, 0.0, seam * strength);
}
