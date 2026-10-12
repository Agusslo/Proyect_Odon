class_name HealthCore
extends Area2D
## Fragmento de Núcleo: suma una celda de vida máxima. Se agarra una sola vez.

@export var pickup_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if pickup_id != "" and GameState.get_flag(pickup_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", -3.0, 0.9).as_relative()
	tween.tween_property(sprite, "position:y", 3.0, 0.9).as_relative()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.add_max_health(1)
	if pickup_id != "":
		GameState.set_flag(pickup_id)
	GameState.save_game()
	EventBus.message_requested.emit("Fragmento de Núcleo\nTu vida máxima aumenta en una celda.", 3.5)
	GameFeel.shake(2.0, 0.2)
	queue_free()
