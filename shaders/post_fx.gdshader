shader_type canvas_item;
// Post-proceso de pantalla completa: el "look" oscuro cyberpunk.
//   - bloom: los neones y el fuego "sangran" luz (usa los mipmaps de la pantalla, es barato)
//   - aberración cromática suave en los bordes
//   - virado de color: sombras azul petróleo, luces cálidas
//   - viñeta y líneas de barrido (CRT) muy sutiles
// Todo se ajusta con los uniforms desde el Inspector (nodo PostFX en main.tscn).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_strength : hint_range(0.0, 2.0) = 0.65;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.42;
uniform float aberration : hint_range(0.0, 0.01) = 0.0022;
uniform float vignette : hint_range(0.0, 1.5) = 0.85;
uniform float scanlines : hint_range(0.0, 0.3) = 0.05;
uniform vec3 shadow_tint : source_color = vec3(0.05, 0.10, 0.16);
uniform vec3 light_tint : source_color = vec3(1.0, 0.93, 0.88);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - 0.5;
	float edge = dot(from_center, from_center);

	vec3 col;
	col.r = texture(screen_tex, uv + from_center * aberration * edge * 8.0).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - from_center * aberration * edge * 8.0).b;

	// bloom de dos tamaños
	vec3 b1 = textureLod(screen_tex, uv, 2.5).rgb;
	vec3 b2 = textureLod(screen_tex, uv, 4.5).rgb;
	vec3 bloom = max(b1 - bloom_threshold, 0.0) * 0.9 + max(b2 - bloom_threshold * 0.8, 0.0) * 1.2;
	col += bloom * bloom_strength;

	// virado: sombras frías, luces cálidas
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col + shadow_tint * (1.0 - lum) * 0.35, col * light_tint, smoothstep(0.35, 1.0, lum));

	// viñeta
	col *= 1.0 - smoothstep(0.18, 0.75, edge * vignette * 2.0) * 0.75;

	// líneas de barrido
	col *= 1.0 - scanlines * step(mod(FRAGCOORD.y, 3.0), 1.0);

	COLOR = vec4(col, 1.0);
}
