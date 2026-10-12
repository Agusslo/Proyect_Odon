@tool
class_name NeonSign
extends Node2D
## Cartel de neón decorativo: una imagen + un halo de luz del mismo color.
## Es @tool para que el cambio de imagen o color se vea en el editor al instante.

@export var sign_texture: Texture2D:
	set(value):
		sign_texture = value
		_apply()
@export var glow_color: Color = Color(1.0, 0.25, 0.28, 0.6):
	set(value):
		glow_color = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var sign_sprite := $Sign as Sprite2D
	var glow := $Glow as Sprite2D
	sign_sprite.texture = sign_texture
	glow.modulate = glow_color
	if sign_texture:
		# El halo es un poco más grande que el cartel (la textura del halo mide 64 px).
		glow.scale = (sign_texture.get_size() + Vector2(36, 36)) / 64.0
