class_name GarraInfernal
extends Area2D
## Garra Infernal: una mano de fuego que sale del brazo demoníaco y vuela en línea recta.
## Atraviesa enemigos (le pega una vez a cada uno) y se deshace contra las paredes.
##
## El daño lo hace su HitboxComponent hijo (capa 6 playerHitbox), igual que la katana.

const SPARK := preload("res://fx/hit_spark.tscn")

@export var speed: float = 330.0
@export var lifetime: float = 0.9

var direction: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	body_entered.connect(_on_body_entered)  # máscara 1: solo paredes
	hitbox.hit_landed.connect(_on_hit)
	sprite.flip_h = direction < 0
	scale = Vector2(0.4, 0.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.08)


func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	lifetime -= delta
	# titila entre los 3 cuadros de la tira
	sprite.frame = int(Time.get_ticks_msec() / 60.0) % 3
	if lifetime <= 0.0:
		_vanish()


func _on_hit(_hurtbox: HurtboxComponent) -> void:
	GameFeel.hit_stop(0.05)
	GameFeel.shake(2.5, 0.12)


func _on_body_entered(_body: Node2D) -> void:
	_vanish()


func _vanish() -> void:
	set_physics_process(false)
	GameFeel.spawn_fx(SPARK, global_position + Vector2(direction * 8, 0))
	queue_free()
