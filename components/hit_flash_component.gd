class_name HitFlashComponent
extends Node
## Hace "parpadear en blanco" a un sprite cuando recibe un golpe.
## Ejemplo de componente mínimo: hace UNA cosa y se reutiliza en cualquier entidad.

## El nodo visual a iluminar (Sprite2D, AnimatedSprite2D...). Asignar en el Inspector.
@export var target: CanvasItem
@export var flash_color: Color = Color(4.0, 4.0, 4.0)
@export var duration: float = 0.12


func flash() -> void:
	if target == null:
		return
	target.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(target, "modulate", Color.WHITE, duration)
