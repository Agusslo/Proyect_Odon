class_name SwordComponent
extends Node2D
## La espada del jugador: activa un HitboxComponent durante un instante
## en la dirección del ataque (adelante, arriba o abajo).
##
## No sabe nada de cómo se mueve el jugador: solo avisa con hit_landed
## cuando el golpe conecta, y el jugador decide (rebote, retroceso).

## El golpe conectó. direction = hacia dónde se atacó (sirve para el pogo).
signal hit_landed(direction: Vector2)

@export var active_time: float = 0.12  # segundos que la hitbox está activa
@export var cooldown: float = 0.35     # segundos entre ataques
@export var reach: float = 18.0        # distancia del centro del jugador al golpe

@onready var hitbox: HitboxComponent = $SwordHitbox
@onready var shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var slash: Node2D = $SwordHitbox/Slash

var is_attacking: bool = false

var _direction: Vector2 = Vector2.RIGHT
var _active_timer: float = 0.0
var _cooldown_timer: float = 0.0


func _ready() -> void:
	shape.disabled = true
	slash.visible = false
	hitbox.hit_landed.connect(_on_hitbox_hit_landed)


func _physics_process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	if is_attacking:
		_active_timer -= delta
		if _active_timer <= 0.0:
			_end_attack()


func can_attack() -> bool:
	return _cooldown_timer <= 0.0


## Inicia un ataque. direction: Vector2.RIGHT/LEFT/UP/DOWN.
func attack(direction: Vector2) -> bool:
	if not can_attack():
		return false

	_direction = direction
	is_attacking = true
	_active_timer = active_time
	_cooldown_timer = cooldown

	# Este nodo se voltea con scale.x = facing, así que trabajamos en coordenadas
	# locales "mirando a la derecha": adelante siempre es +X.
	var local_dir := Vector2(absf(direction.x), direction.y)
	hitbox.position = local_dir * reach
	hitbox.rotation = local_dir.angle()

	# set_deferred: no se puede activar una colisión en medio del paso de física.
	shape.set_deferred("disabled", false)
	slash.visible = true
	return true


func _end_attack() -> void:
	is_attacking = false
	shape.set_deferred("disabled", true)
	slash.visible = false


func _on_hitbox_hit_landed(_hurtbox: HurtboxComponent) -> void:
	hit_landed.emit(_direction)
