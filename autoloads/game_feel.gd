extends Node
## "Game feel" (Autoload "GameFeel"): lo que hace que los golpes se SIENTAN.
##   - hit_stop(): congela el juego una fracción de segundo al impactar.
##   - shake(): sacude la cámara.
##   - spawn_fx(): crea un efecto (chispas, polvo, explosión) en una posición.
## Cualquier script puede llamarlo: GameFeel.shake(4.0)

var _camera: Camera2D
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _stopping: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## La cámara del jugador se registra sola al aparecer.
func register_camera(camera: Camera2D) -> void:
	_camera = camera


## Pausa de impacto: el tiempo corre al 5% durante `duration` segundos reales.
func hit_stop(duration: float = 0.05, time_scale: float = 0.05) -> void:
	if _stopping:
		return
	_stopping = true
	Engine.time_scale = time_scale
	# ignore_time_scale = true: este temporizador usa tiempo real.
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


func shake(strength: float, duration: float = 0.2) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, duration)


## Instancia un efecto en el mundo (dentro del nodo del grupo "fx_layer").
func spawn_fx(scene: PackedScene, at: Vector2, rotation: float = 0.0) -> Node2D:
	var fx := scene.instantiate() as Node2D
	var layer := get_tree().get_first_node_in_group("fx_layer")
	if layer == null:
		layer = get_tree().current_scene
	if layer == null:
		return null
	layer.add_child(fx)
	fx.global_position = at
	fx.rotation = rotation
	return fx


func _process(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if _shake_time > 0.0:
		_shake_time -= delta
		_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength
		_shake_strength = move_toward(_shake_strength, 0.0, _shake_strength * delta * 4.0)
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO
		_shake_strength = 0.0
