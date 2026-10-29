shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 tint : source_color = vec4(0.5, 0.8, 0.8, 1.0);
uniform int relic_kind = 0;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float pulse = 0.82 + 0.18 * sin(TIME * 1.6 + local_position.y * 9.0);
	vec3 color = tint.rgb * pulse;
	if (relic_kind == 2) {
		// A shifting night sky seen through a doorway too small to enter.
		float folds = sin(UV.y * 35.0 + TIME * 0.8 + sin(UV.x * 19.0 - TIME));
		color *= 0.22 + 0.15 * folds;
		vec2 cell = floor(UV * 50.0);
		float star = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
		color += smoothstep(0.994, 1.0, star) * pulse * vec3(0.7, 0.8, 1.0);
	} else if (relic_kind == 3) {
		float wave = 0.5 + 0.5 * sin(local_position.y * 19.0 - TIME * 2.0);
		color = mix(vec3(0.10, 0.36, 0.7), tint.rgb, wave) * pulse;
	}
	ALBEDO = color;
}
