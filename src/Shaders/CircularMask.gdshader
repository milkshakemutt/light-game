shader_type canvas_item;

// Pixel size of the circle's radius
uniform float radius = 100.0;

// Pixel size of feathering to apply to the circle
uniform float feathering = 1.0;

// Pixel coordinates for the center of the circle
uniform vec2 center = vec2(0.0, 0.0);

// Creates a circle where inner coordinates are 1.0 and outer are 0.0
float circle(vec2 position, vec2 texture_size) {
	if (radius < 0.1) {
		return 0.0;
	}
	
	float distance_from_center = length(position / texture_size - center);
	return 1.0 - smoothstep(radius, radius + feathering, distance_from_center);
}

void fragment() {
    COLOR = texture(TEXTURE, UV);
	COLOR.a *= circle(UV, TEXTURE_PIXEL_SIZE); // Mask the alpha channel
}