shader_type spatial;
render_mode world_vertex_coords;

uniform vec4 tint : source_color = vec4(1.0);
uniform float scroll = 0.0;

void vertex() {
	// Every vertex of an instance uses its original center, so wrapping never
	// splits a tree across the ends of the moving landscape.
	float origin_z = INSTANCE_CUSTOM.x;
	float wrapped_z = mod(origin_z + scroll + 170.0, 230.0) - 170.0;
	VERTEX.z += wrapped_z - origin_z;
}

void fragment() {
	ALBEDO = tint.rgb;
	ROUGHNESS = 0.6;
}
