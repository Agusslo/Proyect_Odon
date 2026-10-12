shader_type canvas_item;
// Luz de borde (rim light) + destello de daño.
// Pinta un borde claro del lado de donde viene la luz, para que el personaje
// se despegue de los fondos oscuros. Se aplica al nodo raíz del personaje y
// cada parte lo hereda (use_parent_material).

uniform vec4 rim_color : source_color = vec4(0.62, 0.82, 1.0, 0.9);
uniform float rim_width = 40.0;       // en píxeles de la textura (las piezas HD se dibujan muy reducidas)
uniform vec2 light_dir = vec2(0.6, -1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;  // 1 = todo blanco (daño)

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 off = normalize(light_dir) * TEXTURE_PIXEL_SIZE * rim_width;
	float a_out = texture(TEXTURE, UV + off).a;
	float rim = clamp(c.a - a_out, 0.0, 1.0);
	vec3 col = mix(c.rgb, rim_color.rgb, rim * rim_color.a);
	col = mix(col, vec3(1.0), flash);
	COLOR = vec4(col, c.a) * COLOR;
}
