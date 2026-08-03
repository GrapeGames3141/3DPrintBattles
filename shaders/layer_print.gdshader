shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;

uniform bool use_albedo_texture = false;
uniform bool use_normal_texture = false;
uniform bool use_metallic_texture = false;
uniform bool use_roughness_texture = false;
uniform bool use_emission_texture = false;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec4 source_emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 filament_color : source_color = vec4(0.10, 0.88, 1.0, 1.0);
uniform float metallic_value : hint_range(0.0, 1.0) = 0.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.65;
uniform float reveal_height = 100.0;
uniform float print_band_width : hint_range(0.01, 0.30) = 0.09;
uniform float layer_frequency : hint_range(10.0, 400.0) = 150.0;
uniform float band_energy : hint_range(0.0, 12.0) = 5.0;

varying float world_height;

void vertex() {
	world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	if (world_height > reveal_height) {
		discard;
	}

	vec4 base = albedo_color;
	if (use_albedo_texture) {
		base *= texture(albedo_texture, UV);
	}
	ALBEDO = base.rgb;

	ROUGHNESS = roughness_value;
	if (use_roughness_texture) {
		ROUGHNESS *= texture(roughness_texture, UV).g;
	}

	METALLIC = metallic_value;
	if (use_metallic_texture) {
		METALLIC *= texture(metallic_texture, UV).b;
	}

	if (use_normal_texture) {
		NORMAL_MAP = texture(normal_texture, UV).rgb;
	}

	vec3 inherited_emission = source_emission.rgb;
	if (use_emission_texture) {
		inherited_emission *= texture(emission_texture, UV).rgb;
	}

	float behind_head = reveal_height - world_height;
	float hot_band = 1.0 - smoothstep(0.0, print_band_width, behind_head);
	float layer_line = pow(0.5 + 0.5 * sin(world_height * layer_frequency), 22.0);
	float cooling_layers = layer_line * smoothstep(print_band_width * 4.0, 0.0, behind_head) * 0.38;
	EMISSION = inherited_emission + filament_color.rgb * (hot_band * band_energy + cooling_layers);
}

