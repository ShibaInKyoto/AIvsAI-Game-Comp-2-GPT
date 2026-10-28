shader_type sky;
uniform float dawn : hint_range(0.0, 1.0) = 0.0;

void sky() {
	float horizon = pow(1.0 - abs(EYEDIR.y), 3.0);
	vec3 midnight = mix(vec3(0.008, 0.016, 0.04), vec3(0.045, 0.10, 0.15), horizon);
	float wave = 0.22 + 0.06 * sin(EYEDIR.x * 9.0 + TIME * 0.045) + 0.025 * sin(EYEDIR.z * 18.0 - TIME * 0.07);
	float ribbon = exp(-pow((EYEDIR.y - wave) * 22.0, 2.0));
	float folds = 0.5 + 0.5 * sin(EYEDIR.x * 65.0 + EYEDIR.z * 42.0 + TIME * 0.09);
	vec3 aurora = mix(vec3(0.09, 0.34, 0.28), vec3(0.22, 0.15, 0.38), folds);
	vec3 night = midnight + aurora * ribbon * (0.25 + folds * 0.32);
	vec3 morning = mix(vec3(0.33, 0.49, 0.57), vec3(0.95, 0.62, 0.42), horizon);
	float sun = exp(-pow(length(EYEDIR.xz - vec2(-0.12, -0.98)) * 22.0, 2.0));
	COLOR = mix(night, morning + vec3(0.8, 0.6, 0.3) * sun, dawn);
}
