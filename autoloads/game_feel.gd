extends Node
## "Game feel" (Autoload "GameFeel"): lo que hace que los golpes se SIENTAN.
##   - hit_stop(): congela el juego una fracción de segundo al impactar.
##   - shake(): sacude la cámara (suave: ruido continuo, no saltos al azar).
##   - kick(): empujoncito de cámara en la dirección del golpe.
##   - spawn_fx(): crea un efecto (chispas, polvo, explosión) en una posición.
## Cualquier script puede llamarlo: GameFeel.shake(4.0)

var _camera: Camera2D
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _stopping: bool = false
var _noise := FastNoiseLite.new()
var _noise_t: float = 0.0
var _kick: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.9


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


## Empuja la cámara unos píxeles hacia `direction` y vuelve sola (los golpes "pesan").
func kick(direction: Vector2, strength: float = 2.0) -> void:
	_kick += direction.normalized() * strength


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
	_noise_t += delta * 60.0
	var offset := Vector2.ZERO
	if _shake_time > 0.0:
		_shake_time -= delta
		# Ruido continuo: la cámara tiembla con suavidad en vez de teletransportarse.
		offset = Vector2(_noise.get_noise_2d(_noise_t, 0.0), _noise.get_noise_2d(0.0, _noise_t)) * _shake_strength * 1.6
		_shake_strength = move_toward(_shake_strength, 0.0, _shake_strength * delta * 5.0)
	else:
		_shake_strength = 0.0
	_kick = _kick.lerp(Vector2.ZERO, minf(delta * 14.0, 1.0))
	_camera.offset = offset + _kick
