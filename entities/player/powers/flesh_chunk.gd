class_name FleshChunk
extends Area2D
## Trozo que sueltan los jefes al recibir golpes fuertes. Ninfa lo puede Devorar
## (tecla de Devorar estando encima) para curarse en medio de la pelea.
## Si nadie lo come, se pudre a los pocos segundos.

@export var lifetime: float = 7.0

var _velocity: Vector2 = Vector2.ZERO
var _on_floor: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("devourable")
	_velocity = Vector2(randf_range(-80, 80), randf_range(-220, -160))


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime < 2.0:
		sprite.visible = int(lifetime * 10.0) % 2 == 0
	if lifetime <= 0.0:
		queue_free()
		return
	if _on_floor:
		return
	_velocity.y += 700.0 * delta
	var step := _velocity * delta
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step + Vector2(0, 4), 1)
	var hit := space.intersect_ray(query)
	if hit and _velocity.y > 0.0:
		global_position = hit.position - Vector2(0, 4)
		_on_floor = true
	else:
		global_position += step
	rotation += delta * 6.0 * signf(_velocity.x)


## Lo llama el jugador al devorarlo.
func devour(_by: Node2D) -> void:
	remove_from_group("devourable")
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.15)
	tween.tween_callback(queue_free)
