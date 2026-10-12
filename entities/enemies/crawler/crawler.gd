class_name Crawler
extends CharacterBody2D
## Dron rastrero de seguridad: el enemigo más simple posible.
## Camina, se da vuelta al chocar una pared o al llegar a un borde,
## y daña al jugador por contacto.
##
## Fíjense que NO tiene lógica de vida ni de daño propia: eso lo hacen
## los mismos componentes que usa el jugador. Solo cambia la configuración.

@export var speed: float = 30.0
@export var gravity: float = 900.0
## 1 = empieza caminando a la derecha, -1 = a la izquierda.
@export_enum("Izquierda:-1", "Derecha:1") var start_direction: int = -1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var flash: HitFlashComponent = $HitFlashComponent
@onready var floor_check: RayCast2D = $FloorCheck

var direction: int = -1

var _knockback_timer: float = 0.0


func _ready() -> void:
	direction = start_direction
	health.health_depleted.connect(_on_health_depleted)
	hurtbox.hit_received.connect(_on_hit_received)
	_update_facing()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 400.0)

	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		var at_ledge := is_on_floor() and not floor_check.is_colliding()
		if is_on_wall() or at_ledge:
			direction *= -1
			_update_facing()
		velocity.x = direction * speed

	move_and_slide()


func _update_facing() -> void:
	sprite.flip_h = direction > 0  # el sprite original mira a la izquierda
	floor_check.position.x = 8.0 * direction
	# Actualizamos el rayo YA, si no el próximo frame lee el valor viejo y vuelve a girar.
	floor_check.force_raycast_update()


func _on_hit_received(hit: HitboxComponent) -> void:
	flash.flash()
	var away: float = signf(global_position.x - hit.global_position.x)
	velocity.x = away * hit.knockback_force
	_knockback_timer = 0.15


func _on_health_depleted() -> void:
	set_physics_process(false)
	# Desactivamos las áreas para que no siga dañando mientras desaparece.
	hitbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
