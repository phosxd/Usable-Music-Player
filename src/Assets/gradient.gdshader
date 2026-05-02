shader_type canvas_item;

uniform vec4 topleft:source_color;
uniform vec4 topright:source_color;
uniform vec4 bottomleft:source_color;
uniform vec4 bottomright:source_color;


void fragment() {
	vec4[4] corners = {
		vec4(topleft.r*COLOR.r, topleft.g*COLOR.g, topleft.b*COLOR.b, topleft.a*COLOR.a),
		vec4(topright.r*COLOR.r, topright.g*COLOR.g, topright.b*COLOR.b, topright.a*COLOR.a),
		vec4(bottomleft.r*COLOR.r, bottomleft.g*COLOR.g, bottomleft.b*COLOR.b, bottomleft.a*COLOR.a),
		vec4(bottomright.r*COLOR.r, bottomright.g*COLOR.g, bottomright.b*COLOR.b, bottomright.a*COLOR.a)
	};
	vec4 top = mix(corners[0], corners[1], UV.x);
	vec4 bottom = mix(corners[2], corners[3], UV.x);
	COLOR = mix(top, bottom, UV.y);
}
