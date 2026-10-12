class_name Player
extends CharacterBody2D
## El Caballero Libélula: yelmo con cuernos, alas de libélula, capa, brazo robótico y katana.
##
## Este script SOLO mueve el cuerpo y coordina a sus componentes:
##   - HealthComponent   -> la vida
##   - HurtboxComponent  -> recibir golpes
##   - SwordComponent    -> atacar
## Además lleva la CARGA del brazo de bronce: cada golpe que conecta la llena,
## y manteniendo "Curar" (L) se gasta para recuperar una celda de vida.
## Las habilidades se consultan a GameState: si no están desbloqueadas, no existen.
##
## Orden de cada frame de física (_physics_process):
##   timers -> gravedad -> input horizontal -> salto -> dash -> ataque
##   -> move_and_slide -> estado -> visuales

signal state_changed(new_state: State)

enum State { IDLE, RUN, JUMP, FALL, DASH, GLIDE, HURT, HEAL, DEAD }

const SAFE_CONFIRM_FRAMES := 10
const DUST := preload("res://fx/dust_puff.tscn")

@export_group("Movimiento horizontal")
@export var max_speed: float = 150.0      # px/s
@export var acceleration: float = 1200.0  # px/s²
@export var friction: float = 1400.0      # px/s²

@export_group("Salto y gravedad")
@export var jump_velocity: float = -320.0         # px/s (negativo = hacia arriba)
@export var double_jump_velocity: float = -280.0  # px/s
@export var gravity: float = 900.0                # px/s²
@export var fall_multiplier: float = 1.4          # cae más rápido de lo que sube
@export var max_fall_speed: float = 400.0         # velocidad terminal
@export var jump_cut: float = 0.5                 # recorte al soltar el botón

@export_group("Tolerancias (game feel)")
@export var coyote_time: float = 0.1       # puede saltar un instante después de dejar el borde
@export var jump_buffer_time: float = 0.1  # recuerda el salto si se apretó justo antes de aterrizar

@export_group("Dash")
@export var dash_speed: float = 360.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.4

@export_group("Planeo")
@export var glide_fall_speed: float = 45.0

@export_group("Combate")
@export var pogo_velocity: float = -300.0        # rebote al pegar hacia abajo
@export var attack_recoil: float = 90.0          # retroceso al pegar de costado
@export var hurt_knockback: Vector2 = Vector2(170.0, -170.0)
@export var hurt_control_lock: float = 0.25      # segundos sin control tras un golpe

@export_group("Carga y curación")
@export var energy_max: int = 99
@export var energy_per_hit: int = 11     # 3 golpes = 1 curación
@export var heal_cost: int = 33
@export var heal_time: float = 0.85      # segundos manteniendo el botón

## El dibujo del personaje (partes + huesos). Ver cutout_rig.gd.
@onready var sprite: CutoutRig = $KnightRig
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var sword: SwordComponent = $Sword
@onready var camera: Camera2D = $Camera2D
@onready var heal_particles: CPUParticles2D = $HealParticles
@onready var dash_trail: CPUParticles2D = $DashTrail

var state: State = State.IDLE
var facing: int = 1  # 1 = derecha, -1 = izquierda
## Main lo apaga durante las transiciones entre salas.
var controls_enabled: bool = true

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _has_double_jumped: bool = false
var _can_dash: bool = true
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _control_lock_timer: float = 0.0
var _last_safe_position: Vector2
var _safe_candidate: Vector2
var _safe_frames: int = 0
var energy: int = 0
var _heal_timer: float = 0.0
var _was_on_floor: bool = true
var _fall_speed: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_last_safe_position = global_position
	GameFeel.register_camera(camera)
	health.max_health = GameState.get_max_health()
	health.reset_health()
	GameState.max_health_changed.connect(_on_max_health_changed)

	health.health_changed.connect(_on_health_changed)
	health.health_depleted.connect(_on_health_depleted)
	hurtbox.hit_received.connect(_on_hit_received)
	sword.hit_landed.connect(_on_sword_hit_landed)

	# Avisamos la vida inicial al HUD (diferido: el HUD puede no estar listo aún).
	_on_health_changed.call_deferred(health.current_health, health.max_health)
	_set_energy.call_deferred(0)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		move_and_slide()
		return

	_update_timers(delta)

	if _dash_timer > 0.0:
		_process_dash(delta)
	elif _handle_heal(delta):
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		_apply_gravity(delta)
		_handle_horizontal(delta)
		_handle_jump()
		_handle_dash_input()
		_handle_attack_input()

	_fall_speed = velocity.y
	move_and_slide()
	_check_landing()
	_update_safe_position()
	_update_state()
	_update_visuals()


# --- API pública (la usan Main y otros objetos) ------------------------------

## Mueve al jugador sin físicas (cambio de sala, respawn).
func teleport_to(new_position: Vector2) -> void:
	global_position = new_position
	velocity = Vector2.ZERO
	_last_safe_position = new_position
	_safe_frames = 0
	_dash_timer = 0.0
	camera.reset_smoothing()


## Vuelve a la vida después de morir.
func revive() -> void:
	health.reset_health()
	_heal_timer = 0.0
	_set_energy(0)
	_control_lock_timer = 0.0
	sprite.visible = true
	_set_state(State.IDLE)


# --- Movimiento --------------------------------------------------------------

func _can_control() -> bool:
	return controls_enabled and _control_lock_timer <= 0.0


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_has_double_jumped = false
		_can_dash = true
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if _can_control() and Input.is_action_just_pressed("jump"):
		_buffer_timer = jump_buffer_time
	else:
		_buffer_timer = maxf(_buffer_timer - delta, 0.0)

	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_control_lock_timer = maxf(_control_lock_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	if _is_gliding():
		velocity.y = minf(velocity.y + gravity * delta, glide_fall_speed)
		return
	var current_gravity: float = gravity * (fall_multiplier if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + current_gravity * delta, max_fall_speed)


func _handle_horizontal(delta: float) -> void:
	var dir: float = Input.get_axis("move_left", "move_right") if _can_control() else 0.0

	if not is_zero_approx(dir):
		velocity.x = move_toward(velocity.x, dir * max_speed, acceleration * delta)
		if not sword.is_attacking:  # no darse vuelta en medio de un espadazo
			facing = 1 if dir > 0.0 else -1
	elif _control_lock_timer <= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_jump() -> void:
	if not _can_control():
		return

	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		# Salto normal desde el suelo (o justo después de dejarlo).
		velocity.y = jump_velocity
		_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif Input.is_action_just_pressed("jump") and _coyote_timer <= 0.0 and _can_double_jump():
		# Doble salto: aleteo de las alas.
		velocity.y = double_jump_velocity
		_has_double_jumped = true
		_buffer_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut


func _can_double_jump() -> bool:
	return GameState.has_ability(Abilities.DOUBLE_JUMP) and not _has_double_jumped


func _is_gliding() -> bool:
	return (
		GameState.has_ability(Abilities.GLIDE)
		and _can_control()
		and not is_on_floor()
		and velocity.y > 0.0
		and Input.is_action_pressed("jump")
	)


# --- Dash --------------------------------------------------------------------

func _handle_dash_input() -> void:
	if not GameState.has_ability(Abilities.DASH):
		return
	if not (_can_control() and Input.is_action_just_pressed("dash")):
		return
	if not _can_dash or _dash_cooldown_timer > 0.0:
		return

	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_can_dash = false  # en el aire: un solo dash hasta volver a tocar el suelo
	dash_trail.emitting = true
	GameFeel.spawn_fx(DUST, global_position + Vector2(0, 12))


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = Vector2(facing * dash_speed, 0.0)  # sin gravedad durante el dash
	if _dash_timer <= 0.0:
		velocity.x = facing * max_speed
		dash_trail.emitting = false


# --- Curación ----------------------------------------------------------------

## Devuelve true mientras el jugador está canalizando una curación.
func _handle_heal(delta: float) -> bool:
	var can_heal := (
		_can_control() and is_on_floor() and not sword.is_attacking
		and energy >= heal_cost and health.current_health < health.max_health
	)
	if not (can_heal and Input.is_action_pressed("heal")):
		if _heal_timer > 0.0:
			_heal_timer = 0.0
			heal_particles.emitting = false
		return false

	_heal_timer += delta
	heal_particles.emitting = true
	if _heal_timer >= heal_time:
		_heal_timer = 0.0
		heal_particles.emitting = false
		_set_energy(energy - heal_cost)
		health.heal(1)
		GameFeel.shake(1.5, 0.15)
	return true


func _set_energy(value: int) -> void:
	energy = clampi(value, 0, energy_max)
	EventBus.player_energy_changed.emit(energy, energy_max)


func _on_max_health_changed(new_max: int) -> void:
	health.max_health = new_max
	health.reset_health()


func _check_landing() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _fall_speed > 220.0:
		GameFeel.spawn_fx(DUST, global_position + Vector2(0, 12))
	_was_on_floor = on_floor


# --- Ataque ------------------------------------------------------------------

func _handle_attack_input() -> void:
	if not (_can_control() and Input.is_action_just_pressed("attack")):
		return

	var direction := Vector2(facing, 0)
	if Input.is_action_pressed("move_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		direction = Vector2.DOWN
	sword.attack(direction)


func _on_sword_hit_landed(direction: Vector2, target: Node2D) -> void:
	# Solo los enemigos dan carga (no las vasijas ni los proyectiles).
	if target and target.is_in_group("enemies"):
		_set_energy(energy + energy_per_hit)
	GameFeel.hit_stop(0.045)
	GameFeel.shake(1.5, 0.1)
	if direction == Vector2.DOWN:
		# Pogo: rebotar sobre lo que golpeamos y recuperar las habilidades aéreas.
		velocity.y = pogo_velocity
		_has_double_jumped = false
		_can_dash = true
	elif direction.x != 0.0:
		velocity.x = -direction.x * attack_recoil


# --- Daño y muerte -----------------------------------------------------------

func _on_hit_received(hitbox: HitboxComponent) -> void:
	if health.is_dead():
		return

	var away: float = signf(global_position.x - hitbox.global_position.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * hurt_knockback.x, hurt_knockback.y)
	_control_lock_timer = hurt_control_lock
	_dash_timer = 0.0
	_heal_timer = 0.0
	heal_particles.emitting = false
	dash_trail.emitting = false
	_flash_white()
	EventBus.player_hurt.emit()
	GameFeel.hit_stop(0.12, 0.02)
	GameFeel.shake(4.0, 0.3)

	if hitbox.is_hazard:
		# Trampa: volver al último suelo seguro (diferido, estamos en un callback de física).
		teleport_to.call_deferred(_last_safe_position)


func _flash_white() -> void:
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash", 1.0)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.2)


func _on_health_changed(current: int, max_value: int) -> void:
	EventBus.player_health_changed.emit(current, max_value)


func _on_health_depleted() -> void:
	_set_state(State.DEAD)
	sprite.play("hurt")
	sprite.visible = true
	EventBus.player_died.emit()


## Guarda la última posición en suelo firme (para volver ahí si caemos en pinches).
## Una posición recién se confirma como segura si el jugador sigue a salvo
## SAFE_CONFIRM_FRAMES frames después; así nunca guardamos el borde mismo de una trampa.
func _update_safe_position() -> void:
	if not is_on_floor() or _is_near_hazard():
		_safe_frames = 0
		return
	_safe_frames += 1
	if _safe_frames == 1:
		_safe_candidate = global_position
	elif _safe_frames >= SAFE_CONFIRM_FRAMES:
		_last_safe_position = _safe_candidate
		_safe_frames = 0


func _is_near_hazard() -> bool:
	# ¿Estamos parados sobre algo del grupo "hazard"?
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider() as Node
		if collider and collider.is_in_group("hazard"):
			return true
	# ¿Estamos tocando el área de daño de una trampa?
	for area in hurtbox.get_overlapping_areas():
		if area is HitboxComponent and area.is_hazard:
			return true
	return false


# --- Estado y animación ------------------------------------------------------

func _update_state() -> void:
	var new_state: State
	if _dash_timer > 0.0:
		new_state = State.DASH
	elif _heal_timer > 0.0:
		new_state = State.HEAL
	elif _control_lock_timer > 0.0:
		new_state = State.HURT
	elif not is_on_floor():
		if _is_gliding():
			new_state = State.GLIDE
		else:
			new_state = State.JUMP if velocity.y < 0.0 else State.FALL
	elif absf(velocity.x) > 5.0:
		new_state = State.RUN
	else:
		new_state = State.IDLE
	_set_state(new_state)


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_changed.emit(state)


func _update_visuals() -> void:
	sprite.flip_h = facing < 0
	sword.scale.x = facing

	# Parpadeo durante la invencibilidad.
	if hurtbox.is_invincible:
		sprite.visible = int(Time.get_ticks_msec() / 80.0) % 2 == 0
	else:
		sprite.visible = true

	var animation: StringName
	match state:
		State.DASH: animation = &"dash"
		State.HEAL: animation = &"heal"
		State.HURT: animation = &"hurt"
		State.GLIDE: animation = &"glide"
		State.JUMP: animation = &"jump"
		State.FALL: animation = &"fall"
		State.RUN: animation = &"run"
		_: animation = &"idle"

	if sword.is_attacking and state != State.DASH and state != State.HURT:
		match sword.attack_direction:
			Vector2.UP: animation = &"attack_up"
			Vector2.DOWN: animation = &"attack_down"
			_: animation = &"attack"

	if sprite.animation != animation:
		sprite.play(animation)
