class_name BossRecolectora
extends Enemy
## LA RECOLECTORA — escarabajo rinoceronte fusionado con un compactador de basura.
##
## Máquina de estados (cada estado dura `_timer` segundos):
##   WAIT → INTRO (rugido) → IDLE → elige un ataque:
##     · EMBESTIDA: carga (aviso) → corre hasta chocar la pared → queda ATURDIDA (¡pegale!)
##     · SALTO: se agacha (aviso) → salta hacia el jugador → al caer lanza ondas de choque
##     · LLUVIA: levanta la cabeza → caen pedazos de chatarra del techo (con aviso en el piso)
##   FASE 2 (mitad de vida): más rápida, más ondas y más chatarra.
##
## La arena (boss_arena.gd) la crea, le pasa los límites y escucha `defeated`.

signal defeated

enum S { WAIT, INTRO, IDLE, CHARGE_WINDUP, CHARGE, STUNNED, LEAP_WINDUP, LEAP, SLAM_RECOVER, RAIN, DYING }

const SHOCKWAVE := preload("res://entities/bosses/recolectora/shockwave.tscn")
const SCRAP := preload("res://entities/bosses/recolectora/falling_scrap.tscn")
const SPARK := preload("res://fx/hit_spark.tscn")
const DUST := preload("res://fx/dust_puff.tscn")

@export var boss_name: String = "La Recolectora"
@export var gravity: float = 900.0
@export var charge_speed: float = 240.0
@export var leap_velocity: float = -430.0

## Límites que pone la arena.
var arena_left: float = 0.0
var arena_right: float = 480.0
var ceiling_y: float = 0.0
var floor_y: float = 0.0

var state: S = S.WAIT
var phase: int = 1
var facing: int = -1

var _timer: float = 0.0
var _last_attack: String = ""
var _airborne: bool = false
var _rain_left: int = 0
var _rain_tick: float = 0.0
var _anim_time: float = 0.0
var _charge_start_x: float = 0.0

@onready var head: Node2D = $Visual/Head
@onready var body: Node2D = $Visual/Body
## Altura del cuerpo en la escena: la respiración oscila alrededor de este valor.
@onready var _body_base_y: float = body.position.y
@onready var legs_near: Array[Node2D] = [$Visual/LegNear1, $Visual/LegNear2, $Visual/LegNear3]
@onready var legs_far: Array[Node2D] = [$Visual/LegFar1, $Visual/LegFar2, $Visual/LegFar3]
@onready var contact: HitboxComponent = $HitboxComponent


func _setup() -> void:
	knockback_resist = 1.0
	health.health_changed.connect(_on_health_changed)


## La arena llama a esto cuando el jugador entra.
func start() -> void:
	_set_state(S.INTRO, 1.6)
	EventBus.boss_started.emit(boss_name, health.max_health)
	GameFeel.shake(5.0, 1.2)
	var tween := create_tween()
	tween.tween_property(head, "rotation", -0.45, 0.35)
	tween.tween_interval(0.8)
	tween.tween_property(head, "rotation", 0.0, 0.3)


func _ai(delta: float) -> void:
	_timer -= delta
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 650.0)

	match state:
		S.WAIT, S.INTRO:
			velocity.x = 0.0
			if state == S.INTRO and _timer <= 0.0:
				_set_state(S.IDLE, 0.6)
		S.IDLE:
			_face_player()
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_choose_attack()
		S.CHARGE_WINDUP:
			velocity.x = 0.0
			body.position.x = randf_range(-1.5, 1.5)
			if _timer <= 0.0:
				body.position.x = 0.0
				_charge_start_x = global_position.x
				_set_state(S.CHARGE, 3.0)
		S.CHARGE:
			velocity.x = facing * charge_speed * (1.3 if phase == 2 else 1.0)
			var hit_wall := is_on_wall() and absf(global_position.x - _charge_start_x) > 20.0
			var out := global_position.x < arena_left + 30.0 or global_position.x > arena_right - 30.0
			if hit_wall or out or _timer <= 0.0:
				_impact()
		S.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_set_state(S.IDLE, 0.4 if phase == 2 else 0.6)
		S.LEAP_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_leap()
		S.LEAP:
			if _airborne and is_on_floor() and velocity.y >= 0.0:
				_slam()
			elif not is_on_floor():
				_airborne = true
		S.SLAM_RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set_state(S.IDLE, 0.45 if phase == 2 else 0.7)
		S.RAIN:
			velocity.x = 0.0
			_rain_tick -= delta
			if _rain_left > 0 and _rain_tick <= 0.0 and _timer < 1.4:
				_drop_scrap()
			if _timer <= 0.0:
				head.rotation = 0.0
				_set_state(S.IDLE, 0.5)
		S.DYING:
			velocity.x = 0.0
			if randf() < 0.25:
				GameFeel.spawn_fx(SPARK, global_position + Vector2(randf_range(-45, 45), randf_range(-60, -10)))
			if _timer <= 0.0:
				_finish_death()

	move_and_slide()
	_animate(delta)


# --- Ataques -----------------------------------------------------------------

func _choose_attack() -> void:
	var options := ["charge", "leap", "rain"]
	options.erase(_last_attack)
	var attack: String = options[randi() % options.size()]
	_last_attack = attack
	_face_player()
	match attack:
		"charge":
			head.rotation = 0.25
			_set_state(S.CHARGE_WINDUP, 0.45 if phase == 2 else 0.7)
		"leap":
			visual.scale.y = 0.88
			_set_state(S.LEAP_WINDUP, 0.35 if phase == 2 else 0.55)
		"rain":
			head.rotation = -0.4
			_rain_left = 8 if phase == 2 else 5
			_rain_tick = 0.0
			_set_state(S.RAIN, 2.4)


func _impact() -> void:
	velocity.x = 0.0
	head.rotation = 0.35
	GameFeel.shake(7.0, 0.45)
	GameFeel.spawn_fx(DUST, global_position + Vector2(facing * 50, 0))
	for i in (3 if phase == 2 else 2):
		_drop_scrap()
	_set_state(S.STUNNED, 0.9 if phase == 2 else 1.3)


func _leap() -> void:
	visual.scale.y = 1.0
	var player := get_player()
	var target_x := player.global_position.x if player else global_position.x
	var air_time := 2.0 * absf(leap_velocity) / gravity
	velocity.y = leap_velocity
	velocity.x = clampf((target_x - global_position.x) / air_time, -280.0, 280.0)
	_airborne = false
	_set_state(S.LEAP, 3.0)


func _slam() -> void:
	velocity.x = 0.0
	GameFeel.shake(9.0, 0.5)
	GameFeel.spawn_fx(DUST, global_position + Vector2(-30, 0))
	GameFeel.spawn_fx(DUST, global_position + Vector2(30, 0))
	_spawn_wave(-1, 0.0)
	_spawn_wave(1, 0.0)
	if phase == 2:
		_spawn_wave(-1, 0.45)
		_spawn_wave(1, 0.45)
	_set_state(S.SLAM_RECOVER, 0.7)


func _spawn_wave(dir: int, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
		if not is_instance_valid(self) or state == S.DYING:
			return
	var wave := SHOCKWAVE.instantiate()
	wave.direction = dir
	get_parent().add_child(wave)
	wave.global_position = Vector2(global_position.x + dir * 40.0, floor_y)


func _drop_scrap() -> void:
	_rain_left -= 1
	_rain_tick = 0.2 if phase == 2 else 0.26
	var scrap := SCRAP.instantiate()
	get_parent().add_child(scrap)
	var x := randf_range(arena_left + 24.0, arena_right - 24.0)
	var player := get_player()
	if player and randf() < 0.45:
		x = clampf(player.global_position.x + randf_range(-12, 12), arena_left + 24.0, arena_right - 24.0)
	scrap.setup(Vector2(x, ceiling_y), floor_y)


# --- Vida, fases y muerte ----------------------------------------------------

func _on_health_changed(current: int, max_value: int) -> void:
	EventBus.boss_health_changed.emit(current, max_value)
	if phase == 1 and current <= max_value / 2 and current > 0:
		phase = 2
		body.modulate = Color(1.2, 0.85, 0.8)
		GameFeel.shake(6.0, 0.8)
		EventBus.message_requested.emit("¡La Recolectora se enfurece!", 2.0)


func die() -> void:
	if state == S.DYING:
		return
	state = S.DYING
	_timer = 1.8
	contact.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	GameFeel.shake(6.0, 1.8)


func _finish_death() -> void:
	is_dead = true
	for i in 3:
		GameFeel.spawn_fx(DEATH_FX, global_position + Vector2(randf_range(-40, 40), randf_range(-50, -10)))
	GameFeel.shake(10.0, 0.6)
	GameFeel.hit_stop(0.2, 0.05)
	EventBus.boss_ended.emit(true)
	defeated.emit()
	queue_free()


# --- Utilidades --------------------------------------------------------------

func _set_state(new_state: S, duration: float) -> void:
	state = new_state
	_timer = duration


func _face_player() -> void:
	var player := get_player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	visual.scale.x = absf(visual.scale.x) * facing


func _animate(delta: float) -> void:
	var speed := absf(velocity.x)
	_anim_time += delta * (4.0 + speed * 0.06)
	var swing := 0.35 if speed > 20.0 else 0.06
	for i in 3:
		legs_near[i].rotation = sin(_anim_time + i * 2.1) * swing
		legs_far[i].rotation = sin(_anim_time + i * 2.1 + PI) * swing
	if state in [S.IDLE, S.WAIT]:
		body.position.y = _body_base_y + sin(_anim_time * 0.8) * 1.2
