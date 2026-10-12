class_name Door
extends Area2D
## Transición entre salas. Se pone en la abertura de una pared.
##
## Cada puerta tiene un id único y sabe a qué sala y a qué puerta lleva.
## Ejemplo: en room_01, la puerta "r01_der" lleva a room_02 / "r02_izq",
## y en room_02, la puerta "r02_izq" lleva de vuelta a room_01 / "r01_der".
##
## IMPORTANTE: el SpawnPoint (donde aparece el jugador al LLEGAR por esta puerta)
## tiene que quedar FUERA del área de colisión, o el jugador rebota en un loop.

@export var door_id: String = ""
## Ruta como texto (y no PackedScene) para evitar dependencias circulares A <-> B.
@export_file("*.tscn") var target_room_path: String = ""
@export var target_door_id: String = ""
## Hacia qué lado de la puerta aparece el jugador al llegar.
## Puerta en la pared IZQUIERDA de la sala -> Derecha. Pared DERECHA -> Izquierda.
@export_enum("Derecha:1", "Izquierda:-1") var spawn_side: int = 1

@onready var spawn_point: Marker2D = $SpawnPoint


func _ready() -> void:
	add_to_group("spawn_points")
	spawn_point.position.x = absf(spawn_point.position.x) * spawn_side
	body_entered.connect(_on_body_entered)


func get_spawn_id() -> String:
	return door_id


func get_spawn_position() -> Vector2:
	return spawn_point.global_position


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and target_room_path != "":
		EventBus.room_change_requested.emit(target_room_path, target_door_id)
