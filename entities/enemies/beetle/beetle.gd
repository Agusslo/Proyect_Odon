class_name Beetle
extends Enemy
## Escarabajo Chatarra: patrulla el piso, se da vuelta en paredes y bordes,
## y daña por contacto. El enemigo más simple: ideal para aprender a pelear.

@export var speed: float = 32.0
@export var gravity: float = 900.0
@export_enum("Izquierda:-1", "Derecha:1") var start_direction: int = -1

@onready var floor_check: RayCast2D = $FloorCheck
@onready var legs: Array[Node2D] = [$Visual/LegFront, $Visual/LegMid, $Visual/LegBack]

var direction: int = -1
var _walk_time: float = 0.0


func _setup() -> void:
	direction = start_direction
	_update_facing()


func _ai(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 400.0)
	if knockback.length() > 5.0:
		velocity.x = knockback.x
	else:
		var at_ledge := is_on_floor() and not floor_check.is_colliding()
		if is_on_wall() or at_ledge:
			direction *= -1
			_update_facing()
		velocity.x = direction * speed
	move_and_slide()
	_animate_legs(delta)


func _animate_legs(delta: float) -> void:
	_walk_time += delta * 12.0
	for i in legs.size():
		legs[i].rotation = sin(_walk_time + i * 2.1) * 0.45


func _update_facing() -> void:
	visual.scale.x = absf(visual.scale.x) * direction
	floor_check.position.x = 9.0 * direction
	floor_check.force_raycast_update()
