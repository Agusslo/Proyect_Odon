extends Node2D
## Atmósfera de una sala: niebla baja que se arrastra por el piso y motas de luz
## flotando. El builder la ajusta al tamaño de cada sala.

@export var room_size: Vector2 = Vector2(480, 272):
	set(value):
		room_size = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var fog := $Fog as CPUParticles2D
	fog.position = Vector2(room_size.x / 2.0, room_size.y - 30.0)
	fog.emission_rect_extents = Vector2(room_size.x / 2.0, 14)
	fog.amount = maxi(8, int(room_size.x / 22.0))
	var motes := $Motes as CPUParticles2D
	motes.position = room_size / 2.0
	motes.emission_rect_extents = room_size / 2.0
	motes.amount = maxi(10, int(room_size.x * room_size.y / 5000.0))
