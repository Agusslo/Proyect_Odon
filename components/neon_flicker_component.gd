class_name NeonFlickerComponent
extends Node
## Hace titilar una luz de neón cada tanto, como un cartel viejo que falla.
## Se engancha a cualquier nodo visual (cartel, farol, pantalla).

## El nodo que titila. Asignar en el Inspector.
@export var target: CanvasItem
## Probabilidad por frame de empezar a fallar (0.004 ≈ una vez cada 4 segundos).
@export_range(0.0, 0.1, 0.001) var flicker_chance: float = 0.004

var _flicker_time: float = 0.0


func _process(delta: float) -> void:
	if target == null:
		return
	if _flicker_time > 0.0:
		_flicker_time -= delta
		target.modulate.a = 0.25 if randf() < 0.5 else 0.85
	else:
		target.modulate.a = 1.0
		if randf() < flicker_chance:
			_flicker_time = randf_range(0.08, 0.4)
