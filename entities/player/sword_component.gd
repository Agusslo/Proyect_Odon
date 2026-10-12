class_name SwordComponent
extends Node2D
## La katana del jugador: activa un HitboxComponent durante un instante
## en la dirección del ataque (adelante, arriba o abajo) y muestra el corte.
##
## No sabe nada de cómo se mueve el jugador: solo avisa con hit_landed
## cuando el golpe conecta, y el jugador decide (rebote, retroceso, energía).

const HIT_SPARK := preload("res://fx/hit_spark.tscn")

## El golpe conectó. direction = hacia dónde se atacó; target = a quién se le pegó.
signal hit_landed(direction: Vector2, target: Node2D)

@export var active_time: float = 0.12  # segundos que la hitbox está activa
@export var cooldown: float = 0.32     # segundos entre ataques
@export var reach: float = 18.0        # distancia del centro del jugador al golpe

@onready var hitbox: HitboxComponent = $SwordHitbox
@onready var shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var slash: Sprite2D = $SwordHitbox/Slash

var is_attacking: bool = false
## Dirección del ataque actual (el jugador la usa para elegir la animación).
var attack_direction: Vector2 = Vector2.RIGHT
var _active_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _slash_scale: Vector2


func _ready() -> void:
	shape.disabled = true
	slash.visible = false
	_slash_scale = slash.scale
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

	attack_direction = direction
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
	_play_slash()
	return true


func _play_slash() -> void:
	slash.visible = true
	slash.modulate = Color(1, 1, 1, 1)
	slash.scale = _slash_scale * 0.8
	var tween := create_tween().set_parallel()
	tween.tween_property(slash, "scale", _slash_scale * 1.1, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(slash, "modulate:a", 0.0, 0.18).set_delay(0.04)


func _end_attack() -> void:
	is_attacking = false
	shape.set_deferred("disabled", true)


func _on_hitbox_hit_landed(hurtbox: HurtboxComponent) -> void:
	var target := hurtbox.get_parent() as Node2D
	var spark_at := hurtbox.global_position.lerp(hitbox.global_position, 0.5)
	GameFeel.spawn_fx(HIT_SPARK, spark_at, randf() * TAU)
	hit_landed.emit(attack_direction, target)
