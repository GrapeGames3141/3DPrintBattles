shader_type canvas_item;

// The printer's solid pass uses the same seat-facing silhouette as the awakened
// miniature.  This material supplies the warm unfinished-filament read without
// substituting a side-view raw asset or changing its orientation during deploy.
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 filament = vec3(1.12, 0.57, 0.19);
	float value = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(filament * 0.50, filament * 1.18, value), source.a) * COLOR;
}
