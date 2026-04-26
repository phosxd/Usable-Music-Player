shader_type canvas_item;

uniform vec4 topleft:source_color;
uniform vec4 topright:source_color;
uniform vec4 bottomleft:source_color;
uniform vec4 bottomright:source_color;
uniform float period = 1.0;

void fragment() {
	float t = ((sin(cos(TIME))+1.0)/2.0);

	vec4[8] corners = {
		topleft, topright, bottomleft, bottomright,
		topleft, topright, bottomleft, bottomright
	};
	for (int i=0;i<4;++i) {
		vec4 corner = corners[i];
		float v = t;
		if (i % 2 == 0) {v = -v;}
		corner = mix(corner, corners[i+1], -v);
		//corner = mix(corner, corners[i+2], v*0.5);
		//corner = mix(corner, corners[i+3], v);
		corners[i] = corner;
	}

	vec4 top = mix(corners[0], corners[1], UV.x);
	vec4 bottom = mix(corners[2], corners[3], UV.x);
	COLOR = mix(top, bottom, UV.y);
}
