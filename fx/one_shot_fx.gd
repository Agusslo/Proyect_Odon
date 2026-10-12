extends Node2D
## Efecto de un solo uso: dispara todas sus partículas, hace un destello y se borra.

@export var lifetime: float = 0.6
## Sprite que hace un "flash" (crece y se desvanece). Opcional.
@export var flash_sprite: Sprite2D


func _ready() -> void:
	for child in get_children():
		if child is CPUParticles2D:
			child.emitting = true
	if flash_sprite:
		var start := flash_sprite.scale
		var tween := create_tween().set_parallel()
		tween.tween_property(flash_sprite, "scale", start * 1.6, 0.18)
		tween.tween_property(flash_sprite, "modulate:a", 0.0, 0.18)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
