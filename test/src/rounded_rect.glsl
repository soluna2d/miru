@vs vs
layout(binding=0) uniform vs_params {
	vec2 framesize;
};

struct sr_mat {
	mat2 m;
};

layout(binding=0) readonly buffer sr_lut {
	sr_mat sr[];
};

in vec3 position;
in vec4 shape;
in vec4 color;

out vec2 local_pos;
out flat vec2 rect_size;
out flat float radius;
out vec4 frag_color;

void main() {
	vec2 corner = vec2(float(gl_VertexIndex & 1), float(gl_VertexIndex >> 1));
	vec2 local = corner * shape.xy;
	vec2 pos = local * sr[int(position.z)].m + position.xy;
	vec2 clip = pos * framesize;
	gl_Position = vec4(clip.x - 1.0, clip.y + 1.0, 0.0, 1.0);
	local_pos = local;
	rect_size = shape.xy;
	radius = shape.z;
	frag_color = color;
}
@end

@fs fs
in vec2 local_pos;
in flat vec2 rect_size;
in flat float radius;
in vec4 frag_color;

out vec4 out_color;

float rounded_box_distance(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
	vec2 half_size = rect_size * 0.5;
	vec2 p = local_pos - half_size;
	float outer_radius = min(radius, min(half_size.x, half_size.y));
	float outer = rounded_box_distance(p, half_size, outer_radius);
	float outer_alpha = 1.0 - smoothstep(-0.5, 0.5, outer);
	out_color = vec4(frag_color.rgb, frag_color.a * outer_alpha);
}
@end

@program rounded_rect vs fs
