class_name CutoutRig
extends Node2D
## Personaje armado por partes ("cutout"): cada parte del cuerpo es un Sprite2D
## colgado de un "hueso" (un Node2D que gira sobre su articulación).
## Las animaciones del AnimationPlayer solo rotan esos huesos.
##
## Imita lo básico de AnimatedSprite2D (play, animation, flip_h) para que
## player.gd lo use igual que antes: el jugador no sabe cómo se dibuja.

## Segundos de mezcla entre una animación y la siguiente (más suave).
@export var blend_time: float = 0.08

@onready var anim: AnimationPlayer = $AnimationPlayer

## Nombre de la animación actual.
var animation: StringName:
	get:
		return anim.assigned_animation

## true = mirando a la izquierda (espejamos todo el personaje).
var flip_h: bool = false:
	set(value):
		flip_h = value
		scale.x = -absf(scale.x) if value else absf(scale.x)


func play(anim_name: StringName) -> void:
	if anim.assigned_animation != anim_name or not anim.is_playing():
		# Los ataques arrancan al instante (sin mezcla) para que el golpe se sienta inmediato.
		var blend := 0.0 if String(anim_name).begins_with("attack") else blend_time
		anim.play(anim_name, blend)
