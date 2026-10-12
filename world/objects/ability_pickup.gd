class_name AbilityPickup
extends Area2D
## Objeto que desbloquea una habilidad al tocarlo.
## Una vez agarrado, no vuelve a aparecer (aunque se vuelva a la sala):
## eso es lo que hace funcionar el backtracking.

@export_enum("double_jump", "dash", "glide") var ability: String = "double_jump"
## ÚNICO en todo el juego. Ej: "pickup_alas". Si dos pickups comparten id, se pisan.
@export var pickup_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if pickup_id == "":
		push_warning("%s no tiene pickup_id: no se va a recordar." % get_path())
	elif GameState.get_flag(pickup_id):
		queue_free()  # ya lo agarró antes
		return

	body_entered.connect(_on_body_entered)

	# Flotar suavemente (Tween = animación por código).
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", -3.0, 0.8).as_relative()
	tween.tween_property(sprite, "position:y", 3.0, 0.8).as_relative()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	var ability_name := StringName(ability)
	GameState.unlock_ability(ability_name)
	if pickup_id != "":
		GameState.set_flag(pickup_id)
	GameState.save_game()  # las habilidades no se pierden aunque cierren el juego

	var text := "¡Obtuviste %s!\n%s" % [
		Abilities.get_display_name(ability_name), Abilities.get_hint(ability_name)
	]
	EventBus.message_requested.emit(text, 4.0)
	queue_free()
