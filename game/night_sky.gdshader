shader_type sky;

void sky() {
	float horizon = pow(1.0 - abs(EYEDIR.y), 3.0);
	vec3 midnight = mix(vec3(0.008, 0.016, 0.04), vec3(0.045, 0.10, 0.15), horizon);
	float wave = 0.22 + 0.06 * sin(EYEDIR.x * 9.0 + TIME * 0.045) + 0.025 * sin(EYEDIR.z * 18.0 - TIME * 0.07);
	float ribbon = exp(-pow((EYEDIR.y - wave) * 22.0, 2.0));
	float folds = 0.5 + 0.5 * sin(EYEDIR.x * 65.0 + EYEDIR.z * 42.0 + TIME * 0.09);
	vec3 aurora = mix(vec3(0.09, 0.34, 0.28), vec3(0.22, 0.15, 0.38), folds);
	COLOR = midnight + aurora * ribbon * (0.25 + folds * 0.32);
}
