class_name Room
extends Node2D
## Script base de TODAS las salas.
##
## Estructura que espera encontrar (ver README):
##   Room (Node2D, este script)
##   ├── Decor (Node2D)         -> carteles, faroles, puestos (detrás de todo)
##   ├── Atmosphere             -> niebla baja y motas de luz
##   ├── Tiles (TileMapLayer)   -> tiles HD de 64 px escalados a 0.25; definen los límites de la cámara
##   ├── PlayerStart (Marker2D) -> spawn por defecto (partida nueva)
##   ├── Doors (Node2D)         -> instancias de door.tscn
##   ├── Objects (Node2D)       -> terminales, pickups, pinches...
##   └── Enemies (Node2D)

@export var room_name: String = "Sala sin nombre"

@onready var tiles: TileMapLayer = $Tiles
@onready var player_start: Marker2D = $PlayerStart


## Devuelve dónde aparecer según el id de una puerta o terminal.
## Si no lo encuentra (o viene vacío), usa PlayerStart.
func get_spawn_position(spawn_id: String) -> Vector2:
	if spawn_id != "":
		for node in get_tree().get_nodes_in_group("spawn_points"):
			if is_ancestor_of(node) and node.get_spawn_id() == spawn_id:
				return node.get_spawn_position()
		push_warning("%s: no existe el spawn '%s', uso PlayerStart." % [name, spawn_id])
	return player_start.global_position


## Rectángulo de la sala en píxeles, calculado a partir de los tiles pintados.
## Main lo usa para que la cámara no muestre nada fuera de la sala.
func get_bounds() -> Rect2:
	var used := tiles.get_used_rect()
	# Los tiles son HD (64 px) y la capa está escalada a 0.25: cada celda mide 16 en el juego.
	var cell := Vector2(tiles.tile_set.tile_size) * tiles.scale
	return Rect2(
		tiles.global_position + Vector2(used.position) * cell,
		Vector2(used.size) * cell
	)
