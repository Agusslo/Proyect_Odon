extends Node2D
## Escena raíz del juego. NUNCA se destruye.
##
## El jugador y el HUD viven acá; lo único que cambia son las salas,
## que se cargan y descargan dentro de RoomContainer.
## Así el jugador conserva su vida y estado entre salas sin pasar datos de un lado a otro.

@export_file("*.tscn") var starting_room_path: String = "res://world/rooms/room_01.tscn"
## Desmarcar en el Inspector para empezar siempre de cero mientras prueban cosas.
@export var load_save_on_start: bool = true
@export var fade_time: float = 0.25
## Muestra la intro de la historia al empezar una partida nueva (una sola vez).
@export var play_intro: bool = true

const INTRO := preload("res://ui/intro.tscn")

@onready var room_container: Node2D = $RoomContainer
@onready var player: Player = $Player
@onready var fade: ColorRect = $TransitionLayer/Fade
@onready var fx_layer: Node2D = $FX

var _current_room: Room
var _is_transitioning: bool = false


func _ready() -> void:
	EventBus.room_change_requested.connect(_on_room_change_requested)
	EventBus.player_died.connect(_on_player_died)

	var room_path := starting_room_path
	var spawn_id := ""
	var is_new_game := true
	if load_save_on_start and GameState.load_game() and GameState.respawn_room_path != "":
		room_path = GameState.respawn_room_path
		spawn_id = GameState.respawn_spawn_id
		is_new_game = false
	else:
		GameState.reset()

	_load_room(room_path, spawn_id)
	fade.color.a = 1.0
	if is_new_game and play_intro and not GameState.get_flag("intro_vista"):
		GameState.set_flag("intro_vista")
		var intro := INTRO.instantiate()
		add_child(intro)
		fade.color.a = 0.0
		get_tree().paused = true
		await intro.finished
		get_tree().paused = false
		EventBus.message_requested.emit("J: atacar (el 3er golpe es el Zarpazo)   ·   Espacio: saltar   ·   L: devorar\nI: Garra Infernal (gasta Brasas)   ·   E: sumergirse en las charcas", 6.0)
	else:
		_fade_to(0.0)


# --- Atajo de prueba ---------------------------------------------------------

## F1: desbloquea todos los poderes y llena las Brasas (para probar sin recorrer el mapa).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		for ability in [Abilities.DOUBLE_JUMP, Abilities.DASH, Abilities.GLIDE]:
			GameState.unlock_ability(ability)
		player._set_energy(player.brasas_max)
		EventBus.message_requested.emit("[Prueba] Todos los poderes desbloqueados y Brasas llenas.", 2.5)


# --- Cambio de sala ----------------------------------------------------------

func _on_room_change_requested(room_path: String, spawn_id: String) -> void:
	if _is_transitioning:
		return
	_change_room(room_path, spawn_id)


func _change_room(room_path: String, spawn_id: String) -> void:
	_is_transitioning = true
	player.controls_enabled = false
	await _fade_to(1.0)
	_load_room(room_path, spawn_id)
	await _fade_to(0.0)
	player.controls_enabled = true
	_is_transitioning = false
	if player.state == Player.State.DEAD:  # murió justo mientras cambiaba de sala
		_respawn()


func _load_room(room_path: String, spawn_id: String) -> void:
	var scene := load(room_path) as PackedScene
	if scene == null:
		push_error("No se pudo cargar la sala: %s" % room_path)
		return

	if _current_room:
		# remove_child inmediato: que sus puertas dejen de detectar al jugador YA.
		room_container.remove_child(_current_room)
		_current_room.queue_free()

	_current_room = scene.instantiate() as Room
	room_container.add_child(_current_room)
	GameState.current_room_path = room_path

	player.teleport_to(_current_room.get_spawn_position(spawn_id))
	_apply_camera_limits(_current_room.get_bounds())
	_clear_fx()
	EventBus.boss_ended.emit(false)  # por si se salió de una pelea (muerte)
	if GameState.visit_room(room_path):
		EventBus.room_entered.emit(_current_room.room_name)


## Borra efectos sueltos (chispas, ondas) de la sala anterior.
func _clear_fx() -> void:
	for fx in fx_layer.get_children():
		fx.queue_free()


func _apply_camera_limits(bounds: Rect2) -> void:
	var camera := player.camera
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.reset_smoothing()


# --- Muerte y reaparición ----------------------------------------------------

func _on_player_died() -> void:
	if _is_transitioning:
		return
	_respawn()


func _respawn() -> void:
	_is_transitioning = true
	player.controls_enabled = false
	await get_tree().create_timer(0.8).timeout
	await _fade_to(1.0)

	var room_path := GameState.respawn_room_path
	var spawn_id := GameState.respawn_spawn_id
	if room_path == "":
		room_path = starting_room_path  # nunca se conectó a una terminal
		spawn_id = ""

	player.revive()
	_load_room(room_path, spawn_id)
	await _fade_to(0.0)
	player.controls_enabled = true
	_is_transitioning = false


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, fade_time)
	await tween.finished
