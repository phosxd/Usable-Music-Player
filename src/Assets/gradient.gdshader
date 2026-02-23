shader_type canvas_item;

uniform vec4 topleft:source_color;
uniform vec4 topright:source_color;
uniform vec4 bottomleft:source_color;
uniform vec4 bottomright:source_color;

void fragment() {
	float sin_time = sin(TIME)/4.0;
	vec4 topleft_ = mix(topleft, topright, -sin_time);
	vec4 topright_ = mix(topright, bottomright, sin_time);
	vec4 bottomleft_ = mix(bottomleft, bottomright, -sin_time);
	vec4 bottomright_ = mix(bottomright, bottomleft, sin_time);
	vec4 top = mix(topleft_, topright_, UV.x);
	vec4 bottom = mix(bottomleft_, bottomright_, UV.x);
	COLOR = mix(top, bottom, UV.y);
}
