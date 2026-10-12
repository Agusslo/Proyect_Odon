class_name SavePoint
extends Area2D
## Terminal de recarga: el jugador se para enfrente, presiona Interactuar (E) y
## recupera toda la vida + guarda la partida + queda como punto de reaparición.

@export var save_id: String = ""

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var prompt: Label = $Prompt

var _player: Player = null


func _ready() -> void:
	add_to_group("spawn_points")
	prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player and _player.controls_enabled and Input.is_action_just_pressed("interact"):
		_rest()


func get_spawn_id() -> String:
	return save_id


func get_spawn_position() -> Vector2:
	return spawn_point.global_position


func _rest() -> void:
	_player.health.reset_health()
	GameState.set_respawn_point(GameState.current_room_path, save_id)
	if GameState.save_game():
		EventBus.message_requested.emit("Sistema restaurado. Partida guardada.", 2.0)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body
		prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		prompt.visible = false
