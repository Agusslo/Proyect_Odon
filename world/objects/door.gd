class_name Door
extends Area2D
## Transición entre salas. Se pone en una abertura de la pared, del piso o del techo.
##
## Cada puerta tiene un id único y sabe a qué sala y a qué puerta lleva.
## Ejemplo: en room_01, la puerta "r01_der" lleva a room_02 / "r02_izq",
## y en room_02, la puerta "r02_izq" lleva de vuelta a room_01 / "r01_der".
##
## IMPORTANTE: el punto de aparición (spawn_offset) tiene que quedar FUERA del
## área de la puerta, o el jugador rebota en un loop.

@export var door_id: String = ""
## Ruta como texto (y no PackedScene) para evitar dependencias circulares A <-> B.
@export_file("*.tscn") var target_room_path: String = ""
@export var target_door_id: String = ""
## Tamaño del área. Puertas en paredes: (16, 48). En piso o techo: (48, 16).
@export var size: Vector2 = Vector2(16, 48):
	set(value):
		size = value
		_apply_size()
## Dónde aparece el jugador al LLEGAR por esta puerta, relativo al centro.
## Pared izquierda: (32, 12). Pared derecha: (-32, 12).
## Puerta en el techo: abajo y a un costado. Puerta en el piso: arriba, sobre un borde.
@export var spawn_offset: Vector2 = Vector2(32, 12)


func _ready() -> void:
	add_to_group("spawn_points")
	_apply_size()
	body_entered.connect(_on_body_entered)


func _apply_size() -> void:
	if not is_node_ready():
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	($CollisionShape2D as CollisionShape2D).shape = shape


func get_spawn_id() -> String:
	return door_id


func get_spawn_position() -> Vector2:
	return global_position + spawn_offset


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and target_room_path != "":
		EventBus.room_change_requested.emit(target_room_path, target_door_id)
