shader_type spatial;
render_mode blend_mix, unshaded;

uniform samplerCube cube_map : hint_albedo;

void fragment(){
	vec3 dir = (CAMERA_MATRIX * vec4(normalize(VERTEX), 0.0)).xyz;
	ALBEDO = texture(cube_map, dir).rgb;
}