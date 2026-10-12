class_name Moth
extends Enemy
## Polilla de Señal: flota en su lugar hasta que detecta al jugador,
## y entonces lo persigue volando (atraviesa el aire, no las paredes).

@export var detect_radius: float = 130.0
@export var lose_radius: float = 220.0
@export var chase_speed: float = 62.0
@export var acceleration: float = 160.0

@onready var wing_front: Node2D = $Visual/WingFront
@onready var wing_back: Node2D = $Visual/WingBack

var _home: Vector2
var _time: float = 0.0
var _chasing: bool = false


func _setup() -> void:
	_home = global_position
	_time = randf() * TAU


func _ai(delta: float) -> void:
	_time += delta
	var player := get_player()
	var target_velocity := Vector2.ZERO
	if player and not player.state == Player.State.DEAD:
		var dist := global_position.distance_to(player.global_position)
		if _chasing and dist > lose_radius:
			_chasing = false
		elif not _chasing and dist < detect_radius:
			_chasing = true
		if _chasing:
			var to := (player.global_position + Vector2(0, -6) - global_position).normalized()
			target_velocity = to * chase_speed + Vector2(0, sin(_time * 5.0) * 20.0)
	if not _chasing:
		# Flotar alrededor de su lugar de origen
		var hover := _home + Vector2(sin(_time * 0.9) * 14.0, sin(_time * 2.1) * 6.0)
		target_velocity = (hover - global_position) * 2.0

	velocity = velocity.move_toward(target_velocity, acceleration * delta) + knockback * 0.2
	move_and_slide()

	# Aleteo y mirar hacia donde va
	var flap := 0.55 + 0.45 * sin(_time * 22.0)
	wing_front.scale.y = flap
	wing_back.scale.y = 0.5 + 0.45 * sin(_time * 22.0 + 0.6)
	if absf(velocity.x) > 4.0:
		visual.scale.x = absf(visual.scale.x) * signf(velocity.x)
