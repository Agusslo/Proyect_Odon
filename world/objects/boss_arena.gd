class_name BossArena
extends Node2D
## Arena de jefe: cuando el jugador entra, cierra las barreras y despierta al jefe.
## Al ganar: guarda el flag, abre las barreras y aparece la recompensa.
## Si el jefe ya fue derrotado (flag guardado), no pasa nada.

const ABILITY_PICKUP := preload("res://world/objects/ability_pickup.tscn")

@export var boss_scene: PackedScene
@export var boss_flag: String = "boss_recolectora"
@export_enum("double_jump", "dash", "glide", "garra") var reward_ability: String = "glide"
@export var reward_pickup_id: String = "pickup_planeo"
## Límites para los ataques del jefe (en coordenadas de la sala).
@export var arena_left: float = 32.0
@export var arena_right: float = 448.0
@export var ceiling_y: float = 24.0
@export var floor_y: float = 240.0

@onready var trigger: Area2D = $Trigger
@onready var gates: Node2D = $Gates
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var reward_spawn: Marker2D = $RewardSpawn

var _started: bool = false


func _ready() -> void:
	if GameState.get_flag(boss_flag):
		if not GameState.get_flag(reward_pickup_id):
			_spawn_reward.call_deferred()
		return
	trigger.body_entered.connect(_on_trigger)


func _on_trigger(body: Node2D) -> void:
	if _started or not body.is_in_group("player"):
		return
	_started = true
	# Diferido: no se pueden crear áreas de física dentro de una señal de física.
	_start_fight.call_deferred()


func _start_fight() -> void:
	for gate in gates.get_children():
		gate.close()
	var boss := boss_scene.instantiate() as BossRecolectora
	boss.arena_left = global_position.x + arena_left
	boss.arena_right = global_position.x + arena_right
	boss.ceiling_y = global_position.y + ceiling_y
	boss.floor_y = global_position.y + floor_y
	add_child(boss)
	boss.global_position = boss_spawn.global_position
	boss.defeated.connect(_on_boss_defeated)
	await get_tree().create_timer(0.6, false).timeout
	if is_instance_valid(boss):
		boss.start()


func _on_boss_defeated() -> void:
	GameState.set_flag(boss_flag)
	GameState.save_game()
	EventBus.message_requested.emit("LA RECOLECTORA HA CAÍDO", 3.0)
	for gate in gates.get_children():
		gate.open()
	_spawn_reward.call_deferred()


func _spawn_reward() -> void:
	var pickup := ABILITY_PICKUP.instantiate()
	pickup.ability = reward_ability
	pickup.pickup_id = reward_pickup_id
	add_child(pickup)
	pickup.global_position = reward_spawn.global_position
