class_name Projectile
extends Area2D
## Bola de plasma: avanza en línea recta, explota al tocar una pared
## o al ser cortada por la espada (tiene su propia Hurtbox con 1 de vida).

const SPARK := preload("res://fx/hit_spark.tscn")

@export var lifetime: float = 3.5

var velocity: Vector2 = Vector2.ZERO

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	body_entered.connect(func(_b: Node) -> void: pop())
	health.health_depleted.connect(pop)
	$HitboxComponent.hit_landed.connect(func(_h: HurtboxComponent) -> void: pop.call_deferred())


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		pop()


func pop() -> void:
	if is_queued_for_deletion():
		return
	GameFeel.spawn_fx(SPARK, global_position)
	queue_free()
