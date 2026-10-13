class_name SwordComponent
extends Node2D
## La katana y el brazo demoníaco de Ninfa: activa un HitboxComponent durante
## un instante en la dirección del ataque y muestra el corte.
##
## Hay tres tipos de golpe hacia adelante, que forman el combo:
##   "slash"   -> primer tajo de katana
##   "slash2"  -> segundo tajo, de abajo hacia arriba
##   "zarpazo" -> el tercero: garras de fuego del brazo, más daño y más empuje
## Hacia arriba y hacia abajo siempre es un tajo simple.
##
## No sabe cómo se mueve el jugador: solo avisa con hit_landed cuando el golpe
## conecta, y el jugador decide (rebote, retroceso, Brasas).

const HIT_SPARK := preload("res://fx/hit_spark.tscn")
const TEX := {
	"slash": preload("res://assets/fx/slash_px.png"),
	"slash2": preload("res://assets/fx/slash2_px.png"),
	"zarpazo": preload("res://assets/fx/zarpazo_px.png"),
}
## Datos de cada golpe: daño, empuje, alcance y tamaño del área.
const KINDS := {
	"slash": {"damage": 1, "knockback": 140.0, "reach": 20.0, "size": Vector2(30, 24)},
	"slash2": {"damage": 1, "knockback": 150.0, "reach": 20.0, "size": Vector2(30, 26)},
	"zarpazo": {"damage": 2, "knockback": 260.0, "reach": 26.0, "size": Vector2(38, 28)},
}

## El golpe conectó. direction = hacia dónde se atacó; target = a quién se le pegó.
signal hit_landed(direction: Vector2, target: Node2D, kind: String)

@export var windup: float = 0.03       # el corte sale un instante después de apretar
@export var active_time: float = 0.12  # segundos que la hitbox está activa
@export var cooldown: float = 0.24     # segundos entre ataques

@onready var hitbox: HitboxComponent = $SwordHitbox
@onready var shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var slash: Sprite2D = $SwordHitbox/Slash

var is_attacking: bool = false
## Dirección y tipo del ataque actual (el jugador los usa para elegir la animación).
var attack_direction: Vector2 = Vector2.RIGHT
var attack_kind: String = "slash"
## Daño extra (por ejemplo, cuando el brazo tiene Hambre).
var bonus_damage: int = 0
var _windup_timer: float = 0.0
var _active_timer: float = 0.0
var _cooldown_timer: float = 0.0


func _ready() -> void:
	shape.disabled = true
	slash.visible = false
	hitbox.hit_landed.connect(_on_hitbox_hit_landed)


func _physics_process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	if not is_attacking:
		return
	if _windup_timer > 0.0:
		_windup_timer -= delta
		if _windup_timer <= 0.0:
			shape.set_deferred("disabled", false)
			_play_slash()
		return
	_active_timer -= delta
	if _active_timer <= 0.0:
		_end_attack()


func can_attack() -> bool:
	return _cooldown_timer <= 0.0


## Inicia un ataque. direction: Vector2.RIGHT/LEFT/UP/DOWN. kind: "slash", "slash2" o "zarpazo".
func attack(direction: Vector2, kind: String = "slash") -> bool:
	if not can_attack():
		return false

	attack_direction = direction
	attack_kind = kind if direction.y == 0.0 else "slash"
	is_attacking = true
	_windup_timer = windup
	_active_timer = active_time
	_cooldown_timer = cooldown + (0.08 if attack_kind == "zarpazo" else 0.0)

	var data: Dictionary = KINDS[attack_kind]
	hitbox.damage = data.damage + bonus_damage
	hitbox.knockback_force = data.knockback
	(shape.shape as RectangleShape2D).size = data.size

	# Este nodo se voltea con scale.x = facing, así que trabajamos en coordenadas
	# locales "mirando a la derecha": adelante siempre es +X.
	var local_dir := Vector2(absf(direction.x), direction.y)
	hitbox.position = local_dir * data.reach
	hitbox.rotation = local_dir.angle()
	slash.texture = TEX[attack_kind]
	return true


func cancel() -> void:
	if is_attacking:
		_end_attack()


func _play_slash() -> void:
	slash.visible = true
	slash.modulate = Color(1, 1, 1, 1)
	slash.frame = 0
	slash.scale = Vector2(0.85, 0.85 if attack_kind != "slash2" else -0.85)
	var tween := create_tween().set_parallel()
	tween.tween_property(slash, "scale:x", 1.05, 0.12)
	tween.tween_property(slash, "modulate:a", 0.0, 0.16).set_delay(0.06)


func _end_attack() -> void:
	is_attacking = false
	shape.set_deferred("disabled", true)


func _on_hitbox_hit_landed(hurtbox: HurtboxComponent) -> void:
	var target := hurtbox.get_parent() as Node2D
	var spark_at := hurtbox.global_position.lerp(hitbox.global_position, 0.5)
	GameFeel.spawn_fx(HIT_SPARK, spark_at, randf() * TAU)
	hit_landed.emit(attack_direction, target, attack_kind)
