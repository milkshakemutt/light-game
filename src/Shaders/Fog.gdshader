shader_type canvas_item;

// Velocity to scroll through the fog's noise texture
uniform vec2 velocity = vec2(1.0, 1.0);

// Color of the fog
uniform vec4 fog_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Noise texture to generate fog from
uniform sampler2D noise;

void fragment() {
	COLOR = mix(vec4(0.0), fog_color, texture(noise, UV + velocity * TIME));
}