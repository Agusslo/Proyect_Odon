class_name Barrier
extends StaticBody2D
## Barrera de energía que cierra la arena del jefe.

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var beam: Node2D = $Beam


func _ready() -> void:
	open(true)


func close() -> void:
	shape.set_deferred("disabled", false)
	beam.visible = true
	beam.modulate.a = 0.0
	create_tween().tween_property(beam, "modulate:a", 1.0, 0.25)
	GameFeel.shake(2.0, 0.2)


func open(instant: bool = false) -> void:
	shape.set_deferred("disabled", true)
	if instant:
		beam.visible = false
		return
	var tween := create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: beam.visible = false)
