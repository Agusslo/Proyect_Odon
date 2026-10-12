extends Node2D
## Onda de choque que corre por el piso. Se esquiva saltando.

@export var speed: float = 170.0
@export var lifetime: float = 3.0
var direction: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var wall_check: RayCast2D = $WallCheck


func _ready() -> void:
	wall_check.target_position = Vector2(10 * direction, 0)


func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	lifetime -= delta
	sprite.scale.x = (0.12 + 0.02 * sin(lifetime * 30.0)) * direction
	if lifetime <= 0.0 or wall_check.is_colliding():
		queue_free()
