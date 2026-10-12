class_name Enemy
extends CharacterBody2D
## Base de todos los enemigos.
##
## Conecta los componentes que todos comparten (vida, hurtbox, retroceso,
## destello blanco, muerte con explosión). Cada enemigo concreto hereda de acá
## y solo escribe su comportamiento en _ai(delta).
##
## Estructura que espera:
##   Enemy (este script)
##   ├── Visual (Node2D)        -> todo lo que se dibuja (se voltea con scale.x)
##   ├── HealthComponent
##   ├── HurtboxComponent       -> capa 5 enemyHurtbox, máscara 6 playerHitbox
##   └── HitboxComponent        -> capa 7 enemyHitbox (daño por contacto)

const DEATH_FX := preload("res://fx/death_burst.tscn")

## 0 = el golpe lo empuja todo, 1 = no se mueve (jefes).
@export_range(0.0, 1.0) var knockback_resist: float = 0.0

@onready var visual: Node2D = $Visual
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent

var knockback: Vector2 = Vector2.ZERO
var is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")
	health.health_depleted.connect(die)
	hurtbox.hit_received.connect(_on_hurt)
	_setup()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	knockback = knockback.move_toward(Vector2.ZERO, 700.0 * delta)
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


func flash() -> void:
	visual.modulate = Color(5, 5, 5)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.14)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	GameFeel.spawn_fx(DEATH_FX, global_position)
	GameFeel.shake(2.5, 0.15)
	queue_free()
