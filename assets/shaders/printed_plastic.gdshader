shader_type spatial;
// FDM-printed plastic: stacked layer lines on the walls, diagonal raster on
// top faces. Used by tools/render_art.gd to render the tool card art.

uniform vec3 color : source_color = vec3(1.0, 0.45, 0.1);
uniform float layer_h = 0.03;
uniform vec3 layer_axis = vec3(0.0, 1.0, 0.0);
uniform float rough = 0.36;
uniform float depth = 0.6;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 axis = normalize(layer_axis);
	float t = fract(dot(wpos, axis) / layer_h);
	float bead = smoothstep(0.0, 0.2, t) * smoothstep(1.0, 0.8, t);
	float facing = abs(dot(wnorm, axis));
	float wall = 1.0 - smoothstep(0.8, 0.98, facing);

	// Top and bottom faces show the nozzle's back-and-forth raster instead.
	vec3 side = normalize(cross(axis, vec3(0.37, 0.21, 0.9)));
	float d = fract(dot(wpos, side) / (layer_h * 1.5));
	float raster = smoothstep(0.0, 0.22, d) * smoothstep(1.0, 0.78, d);

	float g = mix(raster, bead, wall);
	ALBEDO = color * mix(1.0 - depth * 0.55, 1.0, g);

	vec3 axis_view = normalize((VIEW_MATRIX * vec4(axis, 0.0)).xyz);
	vec3 side_view = normalize((VIEW_MATRIX * vec4(side, 0.0)).xyz);
	vec3 bump = axis_view * (t - 0.5) * 1.1 * wall + side_view * (d - 0.5) * 0.7 * (1.0 - wall);
	NORMAL = normalize(NORMAL + bump * depth);
	ROUGHNESS = rough;
	SPECULAR = 0.55;
}
