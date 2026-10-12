extends Node
## Estado global de la partida (Autoload "GameState").
##
## Equivale a un Singleton: existe una sola instancia y vive durante todo el juego,
## aunque cambien las salas. Todo lo que tiene que "recordarse" va acá:
##   - habilidades desbloqueadas
##   - flags del mundo (objetos agarrados, jefes derrotados, puertas abiertas)
##   - último punto de guardado (terminal de recarga)
##
## Las escenas NUNCA guardan estado propio entre visitas: al volver a una sala,
## se instancia de nuevo y le pregunta a GameState qué debe mostrar.

signal ability_unlocked(ability: StringName)
signal max_health_changed(new_max: int)

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 2
const BASE_MAX_HEALTH := 5

var unlocked_abilities: Dictionary = {}  # StringName -> true
var world_flags: Dictionary = {}         # String -> bool  (ej: "pickup_alas": true)
## Celdas de vida extra conseguidas con Fragmentos de Núcleo.
var max_health_bonus: int = 0
## Salas ya visitadas (para mostrar el cartel de zona solo la primera vez).
var visited_rooms: Dictionary = {}

## Sala cargada ahora mismo (la setea Main).
var current_room_path: String = ""

## Dónde reaparece el jugador al morir o al cargar la partida.
var respawn_room_path: String = ""
var respawn_spawn_id: String = ""


# --- Habilidades -------------------------------------------------------------

func unlock_ability(ability: StringName) -> void:
	if has_ability(ability):
		return
	unlocked_abilities[ability] = true
	ability_unlocked.emit(ability)


func has_ability(ability: StringName) -> bool:
	return unlocked_abilities.get(ability, false)


# --- Flags del mundo ---------------------------------------------------------

func set_flag(key: String, value: bool = true) -> void:
	world_flags[key] = value


func get_flag(key: String) -> bool:
	return world_flags.get(key, false)


# --- Vida máxima -------------------------------------------------------------

func get_max_health() -> int:
	return BASE_MAX_HEALTH + max_health_bonus


func add_max_health(amount: int = 1) -> void:
	max_health_bonus += amount
	max_health_changed.emit(get_max_health())


## Marca una sala como visitada. Devuelve true si es la primera vez.
func visit_room(room_path: String) -> bool:
	if visited_rooms.has(room_path):
		return false
	visited_rooms[room_path] = true
	return true


# --- Punto de reaparición ----------------------------------------------------

func set_respawn_point(room_path: String, spawn_id: String) -> void:
	respawn_room_path = room_path
	respawn_spawn_id = spawn_id


# --- Guardado en disco (JSON) ------------------------------------------------
# "user://" es una carpeta del sistema operativo propia del juego.
# En Windows: %APPDATA%\Godot\app_userdata\Proyecto Metroidvania\

func save_game() -> bool:
	var abilities: Array[String] = []
	for ability in unlocked_abilities.keys():
		abilities.append(String(ability))

	var data := {
		"version": SAVE_VERSION,
		"abilities": abilities,
		"flags": world_flags,
		"max_health_bonus": max_health_bonus,
		"visited": visited_rooms.keys(),
		"respawn_room": respawn_room_path,
		"respawn_spawn": respawn_spawn_id,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar la partida: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Archivo de guardado inválido, se ignora.")
		return false

	var data: Dictionary = parsed
	reset()
	for ability in data.get("abilities", []):
		unlocked_abilities[StringName(ability)] = true
	world_flags = (data.get("flags", {}) as Dictionary).duplicate()
	respawn_room_path = data.get("respawn_room", "")
	respawn_spawn_id = data.get("respawn_spawn", "")
	max_health_bonus = int(data.get("max_health_bonus", 0))
	for room in data.get("visited", []):
		visited_rooms[room] = true
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Vuelve todo a cero (partida nueva).
func reset() -> void:
	unlocked_abilities.clear()
	world_flags.clear()
	visited_rooms.clear()
	max_health_bonus = 0
	respawn_room_path = ""
	respawn_spawn_id = ""
