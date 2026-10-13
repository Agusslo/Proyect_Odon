class_name Enemy
extends CharacterBody2D
## Base de todos los enemigos.
##
## Conecta los componentes que todos comparten (vida, hurtbox, retroceso,
## destello, muerte con explosión). Cada enemigo concreto hereda de acá
## y solo escribe su comportamiento en _ai(delta).
##
## ATURDIDO Y DEVORAR: cuando a un enemigo le queda poca vida (stagger_health),
## queda aturdido unos segundos brillando en rojo y deja de hacer daño.
## En ese momento Ninfa lo puede Devorar para curarse. Si nadie lo devora,
## se recupera y sigue peleando.
##
## Estructura que espera:
##   Enemy (este script)
##   ├── Visual (Node2D)        -> todo lo que se dibuja (se voltea con scale.x)
##   ├── HealthComponent
##   ├── HurtboxComponent       -> capa 5 enemyHurtbox, máscara 6 playerHitbox
##   └── HitboxComponent        -> capa 7 enemyHitbox (daño por contacto)

const DEATH_FX := preload("res://fx/death_burst.tscn")
const DEVOUR_FX := preload("res://fx/devour_burst.tscn")

## 0 = el golpe lo empuja todo, 1 = no se mueve (jefes).
@export_range(0.0, 1.0) var knockback_resist: float = 0.0
## Si se lo puede devorar (los jefes no: sueltan trozos).
@export var can_be_devoured: bool = true
## Con esta vida (o menos) queda aturdido.
@export var stagger_health: int = 1
@export var stun_time: float = 3.0

@onready var visual: Node2D = $Visual
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var contact: HitboxComponent = get_node_or_null("HitboxComponent")

var knockback: Vector2 = Vector2.ZERO
var is_dead: bool = false
var is_stunned: bool = false
var _stun_timer: float = 0.0
var _stunned_once: bool = false


func _ready() -> void:
	add_to_group("enemies")
	health.health_depleted.connect(die)
	hurtbox.hit_received.connect(_on_hurt)
	_setup()
	# Un enemigo devorable nunca muere de un golpe sin antes quedar aturdido.
	health.survive_once = can_be_devoured


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	knockback = knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	if is_stunned:
		_process_stun(delta)
		return
	_ai(delta)


## Para inicializar cosas propias en las clases hijas.
func _setup() -> void:
	pass


## Comportamiento propio de cada enemigo (lo escriben las clases hijas).
func _ai(_delta: float) -> void:
	pass


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _on_hurt(hit: HitboxComponent) -> void:
	flash()
	var away := (global_position - hit.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	knockback = away * hit.knockback_force * (1.0 - knockback_resist)
	if can_be_devoured and not is_stunned and not _stunned_once and not is_dead \
			and health.current_health > 0 and health.current_health <= stagger_health:
		stun()


func flash() -> void:
	visual.modulate = Color(5, 5, 5)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.6, 0.4, 0.35) if is_stunned else Color.WHITE, 0.14)


# --- Aturdido y devorado ---------------------------------------------------

func stun() -> void:
	is_stunned = true
	_stunned_once = true  # una sola vez por vida: si no lo comés, se defiende
	_stun_timer = stun_time
	add_to_group("devourable")
	if contact:
		contact.set_deferred("monitorable", false)
	if not GameState.get_flag("tuto_devorar"):
		GameState.set_flag("tuto_devorar")
		EventBus.message_requested.emit("¡Quedó aturdido! Acercate y apretá L (Devorar)\npara comértelo: te cura y te da Brasas.", 4.0)


func _process_stun(delta: float) -> void:
	_stun_timer -= delta
	# pulso rojo: "comeme"
	var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 70.0)
	visual.modulate = Color(1.2 + p, 0.35, 0.3)
	velocity = knockback + Vector2(0, velocity.y + 900.0 * delta if not _is_flying() else 0.0)
	move_and_slide()
	if _stun_timer <= 0.0:
		_recover()


func _recover() -> void:
	is_stunned = false
	remove_from_group("devourable")
	visual.modulate = Color.WHITE
	if contact:
		contact.set_deferred("monitorable", true)


## Los voladores (motion_mode flotante) no caen mientras están aturdidos.
func _is_flying() -> bool:
	return motion_mode == CharacterBody2D.MOTION_MODE_FLOATING


## Lo llama el jugador al devorarlo: el cuerpo vuela hacia la mano y desaparece.
func devour(by: Node2D) -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("devourable")
	if contact:
		contact.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	var target := by.global_position + Vector2(signf(global_position.x - by.global_position.x) * 14.0, -10.0)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(visual, "scale", visual.scale * 0.6, 0.12)
	tween.tween_callback(func() -> void:
		GameFeel.spawn_fx(DEVOUR_FX, global_position)
		queue_free())


func die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("devourable")
	GameFeel.spawn_fx(DEATH_FX, global_position)
	GameFeel.shake(2.5, 0.15)
	queue_free()
