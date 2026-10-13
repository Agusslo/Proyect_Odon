class_name Player
extends CharacterBody2D
## NINFA, el Caballito del Diablo: la última libélula de Odón, con un brazo
## demoníaco prestado por Zébul.
##
## Este script mueve el cuerpo y coordina a sus componentes:
##   - HealthComponent   -> la vida
##   - HurtboxComponent  -> recibir golpes
##   - SwordComponent    -> katana y zarpazo (combo de 3 golpes)
## y maneja los sistemas del pacto (ver docs/LORE en el README):
##   - BRASAS: se ganan pegando y devorando; pagan la Garra Infernal; se apagan si dejás de pelear.
##   - DEVORAR: la única forma de curarse en combate. Los enemigos con poca vida
##     quedan aturdidos (brillan en rojo); acercate y apretá Devorar (L).
##   - HAMBRE: si pasa mucho tiempo sin devorar, el brazo pega más fuerte pero te va comiendo la vida.
##   - GALOPE DEL DIABLO (dash): te volvés sombra, sos invulnerable y quemás a lo que atravesás.
## Las habilidades se consultan a GameState: si no están desbloqueadas, no existen.
##
## GAME FEEL (lo que hace que no se sienta "dura"):
##   - Buffer de entradas: salto, ataque, galope, garra y devorar se recuerdan unos
##     cuadros. Si los apretás un poquito antes de poder, salen solos en el primer cuadro válido.
##   - Coyote time: podés saltar un instante después de dejar el borde.
##   - Salto variable + "flote" en la cima (si mantenés saltar) + caída rápida (abajo en el aire).
##   - Corrección de esquinas: si la cabeza roza el borde de un techo, te desliza y no te frena.
##   - Moverse y pegar son independientes: el ataque nunca toca velocity.x.
##   - Cancelaciones: saltar o galopar corta la recuperación de un ataque, de la Garra
##     (después de lanzarla) o de Devorar (después del mordisco). Galopar también te saca
##     de un golpe recibido (después de un instante).
##
## MOVILIDAD DE LIBÉLULA (lo que la hace distinta):
##   - Galope en 8 direcciones (dardo): sale disparada hacia donde apuntes y FRENA EN SECO
##     con un aleteo en el aire, como una libélula de verdad.
##   - Salto galopado: si saltás durante el galope en el piso, conservás la velocidad.
##   - Suspensión: pegar en el aire te deja flotando un instante (hasta 3 veces por salto),
##     así podés encadenar el combo sin caerte.
##
## Orden de cada frame de física (_physics_process):
##   timers/buffers -> (galope | acción en curso | gravedad, movimiento, salto, dash, ataque, poderes)
##   -> corrección de esquinas -> move_and_slide -> estado -> visuales

signal state_changed(new_state: State)

enum State { IDLE, RUN, JUMP, FALL, DASH, GLIDE, HURT, DEVOUR, CAST, REST, DEAD }

const SAFE_CONFIRM_FRAMES := 10
const DUST := preload("res://fx/dust_puff.tscn")
const GARRA := preload("res://entities/player/powers/garra_infernal.tscn")
## Duración de cada animación de acción (cuadros / fps de ninfa_frames.tres).
const COMBO_ANIMS := {"slash": &"attack", "slash2": &"attack2", "zarpazo": &"zarpazo"}
## Acciones que se recuerdan si se aprietan antes de tiempo (input buffer).
const BUFFERED := ["jump", "attack", "dash", "garra", "devour"]

@export_group("Movimiento horizontal")
@export var max_speed: float = 150.0          # px/s
@export var acceleration: float = 1500.0      # px/s² en el piso
@export var turn_acceleration: float = 3000.0 # px/s² al darse vuelta (giro rápido, nada de patinar)
@export var friction: float = 1800.0          # px/s² al soltar en el piso
@export var air_acceleration: float = 1100.0  # px/s² en el aire
@export var air_friction: float = 700.0       # px/s² al soltar en el aire
@export var momentum_drag: float = 220.0      # cómo se pierde la velocidad extra (salto galopado)

@export_group("Salto y gravedad")
@export var jump_velocity: float = -320.0         # px/s (negativo = hacia arriba)
@export var double_jump_velocity: float = -280.0  # px/s
@export var gravity: float = 900.0                # px/s²
@export var fall_multiplier: float = 1.4          # cae más rápido de lo que sube
@export var max_fall_speed: float = 400.0         # velocidad terminal
@export var jump_cut: float = 0.5                 # recorte al soltar el botón
@export var apex_threshold: float = 50.0          # cerca de la cima del salto...
@export var apex_gravity_mult: float = 0.5        # ...la gravedad baja a la mitad si mantenés saltar (flota)
@export var fast_fall_multiplier: float = 1.7     # mantener abajo en el aire: cae más rápido
@export var fast_fall_max: float = 540.0
@export var corner_correction: int = 5            # px que te puede correr para no chocar con una esquina

@export_group("Tolerancias (game feel)")
@export var coyote_time: float = 0.1       # puede saltar un instante después de dejar el borde
@export var jump_buffer_time: float = 0.12   # recuerda el salto si se apretó justo antes de aterrizar
@export var action_buffer_time: float = 0.15 # galope, garra y devorar

@export_group("Galope del Diablo (dash)")
@export var dash_speed: float = 380.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.35
@export var dash_end_hover: float = 0.09       # el "freno en seco" de libélula al terminar en el aire
@export var dash_jump_momentum: float = 0.8    # parte de la velocidad del galope que conserva el salto galopado
@export var hurt_dash_cancel: float = 0.1      # tras un golpe, a los cuántos segundos podés escapar galopando

@export_group("Planeo")
@export var glide_fall_speed: float = 45.0

@export_group("Combate")
@export var combo_window: float = 0.45           # segundos para encadenar el siguiente golpe
@export var pogo_velocity: float = -300.0        # rebote al pegar hacia abajo
@export var attack_recoil: float = 0.0           # retroceso al pegar de costado (0 = Ninfa no se mueve al pegar)
@export var attack_buffer_time: float = 0.18     # recuerda el ataque si se apretó un poco antes de poder pegar
@export var camera_lookahead: float = 26.0       # la cámara mira hacia donde vas
@export var air_attack_hang_fall: float = 25.0   # al pegar en el aire, la caída se frena a esta velocidad
@export var max_air_hangs: int = 3               # cuántas veces por salto podés quedar suspendida pegando
@export var hurt_knockback: Vector2 = Vector2(170.0, -170.0)
@export var hurt_control_lock: float = 0.25      # segundos sin control tras un golpe

@export_group("Brasas")
@export var brasas_max: int = 99
@export var brasas_per_hit: int = 8
@export var brasas_per_zarpazo: int = 16
@export var brasas_per_devour: int = 33
@export var garra_cost: int = 33
@export var brasas_decay_delay: float = 6.0     # segundos sin pelear antes de que se apaguen
@export var brasas_decay_rate: float = 5.0      # brasas por segundo

@export_group("Devorar")
@export var devour_range: float = 36.0
@export var devour_time: float = 0.58

@export_group("Hambre")
@export var hunger_time: float = 120.0  # segundos sin devorar hasta que el brazo tiene Hambre
@export var hunger_tick: float = 25.0   # con Hambre, cada cuánto te saca 1 de vida (nunca la última)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var sword: SwordComponent = $Sword
@onready var camera: Camera2D = $Camera2D
@onready var dash_trail: CPUParticles2D = $DashTrail
@onready var dash_hitbox: HitboxComponent = $DashHitbox
@onready var dash_shape: CollisionShape2D = $DashHitbox/CollisionShape2D
@onready var devour_particles: CPUParticles2D = $DevourParticles

var state: State = State.IDLE
var facing: int = 1  # 1 = derecha, -1 = izquierda
## Main lo apaga durante las transiciones entre salas.
var controls_enabled: bool = true
## Brasas actuales (la barra de fuego del HUD).
var energy: int = 0
var hungry: bool = false

var _coyote_timer: float = 0.0
var _buffers: Dictionary = {}           # acción -> segundos que le quedan al buffer
var _has_double_jumped: bool = false
var _can_dash: bool = true
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _ghost_timer: float = 0.0
var _control_lock_timer: float = 0.0
var _last_safe_position: Vector2
var _safe_candidate: Vector2
var _safe_frames: int = 0
var _was_on_floor: bool = true
var _fall_speed: float = 0.0
var _combo_step: int = 0
var _combo_timer: float = 0.0
var _action_timer: float = 0.0          # devorar / lanzar garra / sumergirse
var _action_state: State = State.IDLE
var _action_anim: StringName = &""      # animación de ataque que se está mostrando
var _action_anim_timer: float = 0.0
var _garra_pending: float = -1.0
var _devour_target: Node2D = null
var _devour_fed: bool = false
var _brasas_idle: float = 0.0
var _brasas_decay_acc: float = 0.0
var _hunger: float = 0.0
var _hunger_tick_timer: float = 0.0
var _squash_tween: Tween
var _last_facing: int = 1
var _dash_dir: Vector2 = Vector2.RIGHT
var _dash_from_floor: bool = false
var _hover_timer: float = 0.0
var _air_hangs: int = 0
var _hang_timer: float = 0.0


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
	dash_hitbox.hit_landed.connect(func(_h: HurtboxComponent) -> void: GameFeel.hit_stop(0.03))

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
	_update_brasas(delta)
	_update_hunger(delta)

	if _dash_timer > 0.0:
		_process_dash(delta)
	else:
		# Cancelar: el final de la Garra o de Devorar se corta si querés saltar, galopar o pegar.
		if _action_timer > 0.0 and _action_cancelable() and _wants_to_move():
			_action_timer = 0.0
			_devour_target = null
		if _action_timer > 0.0:
			_process_action(delta)
		else:
			_apply_gravity(delta)
			_handle_horizontal(delta)
			_handle_jump()
			_handle_dash_input()
			_handle_attack_input()
			_handle_devour_input()
			_handle_garra_input()

	_fall_speed = velocity.y
	_correct_corners(delta)
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
	_end_dash()
	camera.reset_smoothing()


## Vuelve a la vida después de morir. El brazo se queda con tus Brasas.
func revive() -> void:
	health.reset_health()
	_action_timer = 0.0
	_set_energy(0)
	_control_lock_timer = 0.0
	sprite.visible = true
	_set_state(State.IDLE)


## Lo llama la charca al sumergirse: animación de descanso y el Hambre se calma.
func rest() -> void:
	_start_action(State.REST, 0.9)
	feed()


## Calma el Hambre del brazo (devorar o descansar en una charca).
func feed() -> void:
	_hunger = 0.0
	_hunger_tick_timer = 0.0
	if hungry:
		hungry = false
		sword.bonus_damage = 0
		sprite.self_modulate = Color.WHITE
	EventBus.player_hunger_changed.emit(false, 0.0)


# --- Movimiento --------------------------------------------------------------

func _can_control() -> bool:
	return controls_enabled and _control_lock_timer <= 0.0


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_has_double_jumped = false
		_can_dash = true
		_air_hangs = 0
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	# Input buffer: se anota aunque en este momento no se pueda (en medio de un golpe,
	# de una acción, de un empujón). Se consume en el primer cuadro en que sí se pueda.
	for action in BUFFERED:
		if controls_enabled and Input.is_action_just_pressed(action):
			_buffers[action] = _buffer_window(action)
		elif _buffers.has(action):
			_buffers[action] = maxf(_buffers[action] - delta, 0.0)

	_hover_timer = maxf(_hover_timer - delta, 0.0)
	_hang_timer = maxf(_hang_timer - delta, 0.0)

	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_control_lock_timer = maxf(_control_lock_timer - delta, 0.0)
	_combo_timer = maxf(_combo_timer - delta, 0.0)
	_action_anim_timer = maxf(_action_anim_timer - delta, 0.0)


func _buffer_window(action: String) -> float:
	match action:
		"jump": return jump_buffer_time
		"attack": return attack_buffer_time
		_: return action_buffer_time


## ¿Está anotada esta acción en el buffer?
func _buffered(action: String) -> bool:
	return _buffers.get(action, 0.0) > 0.0


## La usa y la borra del buffer (para que no se ejecute dos veces).
func _consume(action: String) -> void:
	_buffers[action] = 0.0


func _wants_to_move() -> bool:
	return _buffered("jump") or _buffered("dash") or _buffered("attack")


## ¿Hay suelo justo debajo? (para no gastar el doble salto un cuadro antes de aterrizar)
func _near_ground() -> bool:
	return velocity.y > 0.0 and test_move(global_transform, Vector2(0, 10))


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	if _hover_timer > 0.0:
		# Freno en seco del galope: un aleteo quieto en el aire.
		velocity.y = move_toward(velocity.y, 0.0, 1800.0 * delta)
		return
	if _is_gliding():
		velocity.y = minf(velocity.y + gravity * delta, glide_fall_speed)
		return
	var g: float = gravity
	var max_fall: float = max_fall_speed
	if velocity.y > 0.0:
		g *= fall_multiplier
	if Input.is_action_pressed("jump") and absf(velocity.y) < apex_threshold:
		g *= apex_gravity_mult  # flota un instante en la cima: más control en el aire
	if _can_control() and Input.is_action_pressed("move_down") and velocity.y > 0.0:
		g *= fast_fall_multiplier
		max_fall = fast_fall_max
	if _hang_timer > 0.0:
		g *= 0.3  # suspendida mientras pega en el aire
	velocity.y = minf(velocity.y + g * delta, max_fall)


func _handle_horizontal(delta: float) -> void:
	var dir: float = Input.get_axis("move_left", "move_right") if _can_control() else 0.0
	var on_floor := is_on_floor()

	if not is_zero_approx(dir):
		var accel: float = acceleration if on_floor else air_acceleration
		var turning := not is_zero_approx(velocity.x) and signf(velocity.x) != signf(dir)
		if turning:
			accel = turn_acceleration
		if not on_floor and not turning and absf(velocity.x) > max_speed:
			# Velocidad extra del salto galopado: se pierde de a poco, no de golpe.
			velocity.x = move_toward(velocity.x, dir * max_speed, momentum_drag * delta)
		else:
			velocity.x = move_toward(velocity.x, dir * max_speed, accel * delta)
		if not sword.is_attacking:  # no darse vuelta mientras el filo está activo
			facing = 1 if dir > 0.0 else -1
	elif _control_lock_timer <= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, (friction if on_floor else air_friction) * delta)


func _handle_jump() -> void:
	if not _can_control():
		return

	if _buffered("jump") and _coyote_timer > 0.0:
		# Salto normal desde el suelo (o justo después de dejarlo: coyote time).
		_jump(jump_velocity)
		_squash(Vector2(0.84, 1.16))
		_coyote_timer = 0.0
	elif _buffered("jump") and _coyote_timer <= 0.0 and _can_double_jump() and not _near_ground():
		# Alas de Ceniza: las alas rotas arden un instante.
		# (Si estás por tocar el piso, no se gasta: el buffer hace un salto normal al aterrizar.)
		_jump(double_jump_velocity)
		_squash(Vector2(0.9, 1.1))
		_has_double_jumped = true
		_burst_embers(8)

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut


func _jump(speed: float) -> void:
	velocity.y = speed
	_consume("jump")
	_hover_timer = 0.0
	_hang_timer = 0.0
	if not sword.is_attacking:
		_action_anim_timer = 0.0  # cancela la recuperación del ataque: se ve el salto


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


# --- Galope del Diablo (dash) ------------------------------------------------

func _handle_dash_input() -> void:
	if not GameState.has_ability(Abilities.DASH) or not _buffered("dash"):
		return
	if not controls_enabled or _control_lock_timer > hurt_control_lock - hurt_dash_cancel:
		return
	if not _can_dash or _dash_cooldown_timer > 0.0:
		return
	_consume("dash")

	# Dardo de libélula: 8 direcciones. Sin dirección, hacia adelante.
	var aim := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if is_on_floor() and aim.y > 0.0:
		aim.y = 0.0  # en el piso no se galopa hacia abajo
	if aim.length() < 0.3:
		aim = Vector2(facing, 0)
	_dash_dir = Vector2(signf(aim.x), signf(aim.y)).normalized()
	if _dash_dir.x != 0.0:
		facing = int(signf(_dash_dir.x))
	_dash_from_floor = is_on_floor()

	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_can_dash = false  # en el aire: un solo galope hasta volver a tocar el suelo (o rebotar con un pogo)
	_ghost_timer = 0.0
	_control_lock_timer = 0.0      # escapar de un golpe
	_action_anim_timer = 0.0       # cancela la recuperación del ataque
	_hover_timer = 0.0
	sword.cancel()
	dash_trail.emitting = true
	# Sombra: invulnerable y quema a los enemigos que atraviesa.
	hurtbox.start_invincibility(dash_duration + 0.05)
	dash_shape.set_deferred("disabled", false)
	GameFeel.spawn_fx(DUST, global_position + Vector2(0, 12))
	GameFeel.shake(1.2, 0.08)
	_squash(Vector2(1.25, 0.82))


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_dir * dash_speed  # sin gravedad durante el galope
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = 0.03
		Afterimage.spawn(sprite)

	# Salto galopado: saltar durante un galope en el piso conserva la velocidad.
	if _buffered("jump") and _dash_from_floor and _dash_dir.y == 0.0 and _coyote_timer > 0.0:
		_end_dash()
		velocity.x = _dash_dir.x * dash_speed * dash_jump_momentum
		_jump(jump_velocity)
		_coyote_timer = 0.0
		_squash(Vector2(0.8, 1.2))
		return
	# Pegar en la segunda mitad del galope: sale el golpe sin esperar.
	if _buffered("attack") and _dash_timer < dash_duration * 0.5:
		_finish_dash()
		_handle_attack_input()
		return
	if _dash_timer <= 0.0:
		_finish_dash()


## Final del galope: en el piso sigue corriendo; en el aire FRENA EN SECO y aletea.
func _finish_dash() -> void:
	_end_dash()
	if is_on_floor():
		velocity.x = _dash_dir.x * max_speed
	else:
		velocity = _dash_dir * dash_speed * 0.18
		_hover_timer = dash_end_hover
		_squash(Vector2(0.88, 1.12), 0.18)


func _end_dash() -> void:
	_dash_timer = 0.0
	dash_trail.emitting = false
	dash_shape.set_deferred("disabled", true)


# --- Ataque: katana, katana, zarpazo ----------------------------------------

func _handle_attack_input() -> void:
	# Buffer: si apretás un poquito antes de que termine el golpe anterior, el siguiente
	# sale apenas se pueda. Así el combo se encadena solo, sin "comerse" botones.
	if not _buffered("attack") or not _can_control() or not sword.can_attack():
		return
	_consume("attack")

	var direction := Vector2(facing, 0)
	if Input.is_action_pressed("move_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		direction = Vector2.DOWN

	var kind := "slash"
	if direction.y == 0.0:
		if _combo_timer <= 0.0:
			_combo_step = 0
		kind = ["slash", "slash2", "zarpazo"][_combo_step]
		_combo_step = (_combo_step + 1) % 3
		_combo_timer = combo_window + sword.cooldown

	if sword.attack(direction, kind):
		var anim: StringName = COMBO_ANIMS[kind]
		if direction == Vector2.UP:
			anim = &"attack_up"
		elif direction == Vector2.DOWN:
			anim = &"attack_down"
		_play_action_anim(anim)
		if kind == "zarpazo":
			_burst_embers(6)
		# Suspensión de libélula: pegar de costado en el aire frena la caída un instante.
		if not is_on_floor() and direction.y == 0.0 and _air_hangs < max_air_hangs:
			_air_hangs += 1
			velocity.y = minf(velocity.y, air_attack_hang_fall)
			_hang_timer = sword.windup + sword.active_time + 0.06


func _on_sword_hit_landed(direction: Vector2, target: Node2D, kind: String) -> void:
	# Solo los enemigos dan Brasas (no los proyectiles).
	if target and target.is_in_group("enemies"):
		_add_brasas(brasas_per_zarpazo if kind == "zarpazo" else brasas_per_hit)
	GameFeel.hit_stop(0.07 if kind == "zarpazo" else 0.045)
	GameFeel.shake(3.0 if kind == "zarpazo" else 1.5, 0.12)
	GameFeel.kick(direction, 3.0 if kind == "zarpazo" else 1.5)  # la cámara empuja hacia el golpe
	if direction == Vector2.DOWN:
		# Pogo: rebotar sobre lo que golpeamos y recuperar las habilidades aéreas.
		velocity.y = pogo_velocity
		_has_double_jumped = false
		_can_dash = true
		_air_hangs = 0
	elif direction.x != 0.0 and attack_recoil > 0.0:
		velocity.x = -direction.x * attack_recoil


# --- Devorar -----------------------------------------------------------------

func _handle_devour_input() -> void:
	if not (_can_control() and _buffered("devour")):
		return
	var target := _find_devourable()
	if target == null:
		return
	_consume("devour")
	sword.cancel()
	_devour_target = target
	_devour_fed = false
	if absf(target.global_position.x - global_position.x) > 2.0:
		facing = 1 if target.global_position.x > global_position.x else -1
	velocity = Vector2.ZERO
	hurtbox.start_invincibility(devour_time + 0.2)
	_start_action(State.DEVOUR, devour_time)


## El enemigo aturdido (o trozo) más cercano al alcance del brazo.
func _find_devourable() -> Node2D:
	var best: Node2D = null
	var best_d := devour_range
	for node in get_tree().get_nodes_in_group("devourable"):
		var n := node as Node2D
		if n == null:
			continue
		var d := n.global_position.distance_to(global_position + Vector2(0, -4))
		if d < best_d:
			best_d = d
			best = n
	return best


func _devour_bite() -> void:
	_devour_fed = true
	if is_instance_valid(_devour_target) and _devour_target.has_method("devour"):
		_devour_target.devour(self)
	health.heal(1)
	_add_brasas(brasas_per_devour)
	feed()
	devour_particles.restart()
	GameFeel.hit_stop(0.09, 0.03)
	GameFeel.shake(3.5, 0.2)


# --- Garra Infernal ----------------------------------------------------------

## La Garra Infernal es el poder propio del brazo: está desde el principio.
## Solo pide Brasas (una de las 3 cargas de la barra).
func _handle_garra_input() -> void:
	if not (_can_control() and _buffered("garra")):
		return
	_consume("garra")
	if energy < garra_cost:
		EventBus.brasas_insufficient.emit()
		EventBus.message_requested.emit("Te faltan Brasas: pegá o devorá para cargar el brazo.", 1.2)
		return
	_set_energy(energy - garra_cost)
	sword.cancel()
	_garra_pending = 0.09
	velocity.x = 0.0
	_start_action(State.CAST, 0.3)


## Después del momento importante (lanzar la Garra / el mordisco), la acción se puede cortar.
func _action_cancelable() -> bool:
	match _action_state:
		State.CAST:
			return _garra_pending < 0.0
		State.DEVOUR:
			return _devour_fed and _action_timer < devour_time * 0.4
	return false


func _throw_garra() -> void:
	var garra := GARRA.instantiate() as GarraInfernal
	garra.direction = facing
	var layer := get_tree().get_first_node_in_group("fx_layer")
	(layer if layer else get_parent()).add_child(garra)
	garra.global_position = global_position + Vector2(facing * 16, -6)
	velocity.x = -facing * 70.0  # retroceso del lanzamiento
	GameFeel.shake(2.0, 0.1)


# --- Acciones con duración (devorar, garra, charca) -------------------------

func _start_action(action: State, duration: float) -> void:
	_action_state = action
	_action_timer = duration
	_action_anim_timer = 0.0
	_set_state(action)
	sprite.play({State.DEVOUR: &"devour", State.CAST: &"cast", State.REST: &"rest"}[action])


func _process_action(delta: float) -> void:
	_action_timer -= delta
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	match _action_state:
		State.DEVOUR:
			if not _devour_fed and _action_timer <= devour_time * 0.55:
				_devour_bite()
		State.CAST:
			if _garra_pending >= 0.0:
				_garra_pending -= delta
				if _garra_pending < 0.0:
					_throw_garra()
	if _action_timer <= 0.0:
		_action_timer = 0.0
		_devour_target = null


# --- Brasas y Hambre ---------------------------------------------------------

func _add_brasas(amount: int) -> void:
	_brasas_idle = 0.0
	_set_energy(energy + amount)


func _set_energy(value: int) -> void:
	energy = clampi(value, 0, brasas_max)
	EventBus.player_energy_changed.emit(energy, brasas_max)


func _update_brasas(delta: float) -> void:
	if energy <= 0:
		return
	_brasas_idle += delta
	if _brasas_idle < brasas_decay_delay:
		return
	_brasas_decay_acc += brasas_decay_rate * delta
	if _brasas_decay_acc >= 1.0:
		var n := int(_brasas_decay_acc)
		_brasas_decay_acc -= n
		_set_energy(energy - n)


func _update_hunger(delta: float) -> void:
	if not controls_enabled:
		return
	_hunger += delta
	if not hungry:
		if _hunger >= hunger_time:
			hungry = true
			sword.bonus_damage = 1
			_hunger_tick_timer = 0.0
			EventBus.message_requested.emit("El brazo tiene Hambre...\nPega más fuerte, pero te consume. Devorá algo.", 3.5)
		EventBus.player_hunger_changed.emit(hungry, clampf(_hunger / hunger_time, 0.0, 1.0))
		return
	# Con Hambre: pulso rojo y una mordida a tu propia vida cada tanto.
	var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
	sprite.self_modulate = Color(1.0 + p * 0.5, 1.0 - p * 0.35, 1.0 - p * 0.35)
	_hunger_tick_timer += delta
	if _hunger_tick_timer >= hunger_tick:
		_hunger_tick_timer = 0.0
		if health.current_health > 1:
			health.take_damage(1)
			_flash_white()
			EventBus.player_hurt.emit()
			GameFeel.shake(2.0, 0.2)


func _burst_embers(amount: int) -> void:
	devour_particles.amount = maxi(amount, 1)
	devour_particles.restart()


func _on_max_health_changed(new_max: int) -> void:
	health.max_health = new_max
	health.reset_health()


## Corrección de esquinas: si al subir la cabeza apenas roza el borde de un techo,
## te corre unos píxeles para que pases en vez de frenarte en seco.
func _correct_corners(delta: float) -> void:
	if velocity.y >= 0.0 or _dash_timer > 0.0 and _dash_dir.y == 0.0:
		return
	var up := Vector2(0, velocity.y * delta)
	if not test_move(global_transform, up):
		return
	for i in range(1, corner_correction + 1):
		for side in [1, -1]:
			var nudge := Vector2(i * side, 0)
			if not test_move(global_transform, nudge) and not test_move(global_transform.translated(nudge), up):
				global_position.x += nudge.x
				return


func _check_landing() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _fall_speed > 120.0:
		# aterrizaje: se aplasta más cuanto más rápido venía
		var k := clampf((_fall_speed - 120.0) / 280.0, 0.0, 1.0)
		_squash(Vector2(1.0 + 0.22 * k, 1.0 - 0.2 * k))
	if on_floor and not _was_on_floor and _fall_speed > 220.0:
		GameFeel.spawn_fx(DUST, global_position + Vector2(0, 12))
	_was_on_floor = on_floor


# --- Daño y muerte -----------------------------------------------------------

func _on_hit_received(hitbox: HitboxComponent) -> void:
	if health.is_dead():
		return

	var away: float = signf(global_position.x - hitbox.global_position.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * hurt_knockback.x, hurt_knockback.y)
	_control_lock_timer = hurt_control_lock
	_end_dash()
	_action_timer = 0.0
	_action_anim_timer = 0.0
	sword.cancel()
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
	_end_dash()
	sprite.play(&"death")
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
	elif _action_timer > 0.0:
		new_state = _action_state
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


## Las animaciones de ataque se ven enteras aunque el golpe ya haya terminado.
func _play_action_anim(anim: StringName) -> void:
	_action_anim = anim
	var frames := sprite.sprite_frames
	_action_anim_timer = frames.get_frame_count(anim) / frames.get_animation_speed(anim)
	sprite.play(anim)
	sprite.frame = 0


## Estira o aplasta el sprite y lo devuelve elástico a su forma (salto, aterrizaje, galope, giro).
## El sprite tiene su origen en los pies, así que se aplasta contra el piso.
func _squash(amount: Vector2, duration: float = 0.22) -> void:
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	sprite.scale = amount
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_visuals() -> void:
	if facing != _last_facing:
		_last_facing = facing
		if is_on_floor():
			_squash(Vector2(0.82, 1.04), 0.14)
	sprite.flip_h = facing < 0
	# se inclina hacia donde corre
	var lean := 0.0
	if state == State.DASH:
		# el dardo se inclina hacia donde va (arriba/abajo en diagonal)
		lean = clampf(atan2(_dash_dir.y, absf(_dash_dir.x) + 0.001) * 0.6, -0.75, 0.75) * facing
	elif state == State.RUN:
		lean = clampf(velocity.x / max_speed, -1.0, 1.0) * 0.06
	elif state in [State.JUMP, State.FALL, State.GLIDE]:
		lean = clampf(velocity.x / max_speed, -1.0, 1.0) * 0.04
	sprite.rotation = lerpf(sprite.rotation, lean, 0.25)
	sword.scale.x = facing
	dash_hitbox.scale.x = facing
	dash_hitbox.rotation = atan2(_dash_dir.y, absf(_dash_dir.x) + 0.001) * facing

	# Parpadeo durante la invencibilidad (pero no en el galope ni al devorar: ahí es a propósito).
	if hurtbox.is_invincible and state != State.DASH and state != State.DEVOUR:
		sprite.visible = int(Time.get_ticks_msec() / 80.0) % 2 == 0
	else:
		sprite.visible = true

	var animation: StringName
	match state:
		State.DASH: animation = &"dash"
		State.HURT: animation = &"hurt"
		State.DEVOUR: animation = &"devour"
		State.CAST: animation = &"cast"
		State.REST: animation = &"rest"
		State.GLIDE: animation = &"glide"
		State.JUMP: animation = &"jump"
		State.FALL: animation = &"fall"
		State.RUN: animation = &"run"
		_: animation = &"idle"

	if _action_anim_timer > 0.0 and state in [State.IDLE, State.RUN, State.JUMP, State.FALL, State.GLIDE]:
		animation = _action_anim
		# corriendo: el torso ataca y las piernas siguen corriendo
		var running_variant := StringName(String(_action_anim) + "_run")
		if state == State.RUN and sprite.sprite_frames.has_animation(running_variant):
			animation = running_variant

	if sprite.animation != animation:
		var same_move := String(sprite.animation).trim_suffix("_run") == String(animation).trim_suffix("_run")
		var keep_frame := sprite.frame
		sprite.play(animation)
		if same_move:  # cambia entre la versión quieta y la corriendo sin reiniciar el golpe
			sprite.frame = keep_frame

	# la cámara mira un poco hacia adelante
	var look := facing * camera_lookahead * (1.0 if absf(velocity.x) > 10.0 else 0.5)
	camera.position.x = lerpf(camera.position.x, look, 0.06)
