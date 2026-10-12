@tool
class_name NeonSign
extends Node2D
## Decoración con imagen + halo de luz opcional (carteles, puestos, farolitos, cajas).
## Es @tool para que el cambio de imagen o color se vea en el editor al instante.

## Las texturas son HD (4x): se dibujan a 1/4 de su tamaño.
const ART_SCALE := 0.25

@export var sign_texture: Texture2D:
	set(value):
		sign_texture = value
		_apply()
## Color del halo. Con alfa 0 no hay halo (para objetos que no brillan).
@export var glow_color: Color = Color(1.0, 0.25, 0.28, 0.6):
	set(value):
		glow_color = value
		_apply()
## Si titila de vez en cuando (carteles viejos).
@export var flicker: bool = true:
	set(value):
		flicker = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var sign_sprite := $Sign as Sprite2D
	var glow := $Glow as Sprite2D
	sign_sprite.texture = sign_texture
	sign_sprite.scale = Vector2.ONE * ART_SCALE
	glow.modulate = glow_color
	glow.visible = glow_color.a > 0.01
	if sign_texture:
		var size := sign_texture.get_size() * ART_SCALE
		glow.scale = (size + Vector2(30, 30)) / 256.0
	($NeonFlickerComponent as NeonFlickerComponent).flicker_chance = 0.004 if flicker else 0.0
