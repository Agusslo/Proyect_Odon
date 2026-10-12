extends Node2D
## Pedazo de chatarra que cae del techo. Primero avisa (marca en el piso
## + polvo que cae), después cae y se rompe contra el suelo.

const DUST := preload("res://fx/dust_puff.tscn")
const SPARK := preload("res://fx/hit_spark.tscn")

@export var warning_time: float = 0.65
@export var gravity: float = 700.0

var _floor_y: float = 0.0
var _falling: bool = false
var _vy: float = 0.0

@onready var marker: Sprite2D = $Marker
@onready var piece: Node2D = $Piece
@onready var dust: CPUParticles2D = $Piece/Dust


## pos = punto de partida en el techo; floor_y = altura del piso.
func setup(pos: Vector2, floor_y: float) -> void:
	global_position = pos
	_floor_y = floor_y
	marker.global_position = Vector2(pos.x, floor_y - 1.0)
	piece.visible = false
	$Piece/HitboxComponent.set_deferred("monitorable", false)
	var tween := create_tween().set_loops(4)
	tween.tween_property(marker, "modulate:a", 1.0, warning_time / 8.0)
	tween.tween_property(marker, "modulate:a", 0.3, warning_time / 8.0)
	dust.emitting = true
	get_tree().create_timer(warning_time, false).timeout.connect(_start_fall)


func _start_fall() -> void:
	_falling = true
	piece.visible = true
	$Piece/HitboxComponent.set_deferred("monitorable", true)
	dust.emitting = false


func _physics_process(delta: float) -> void:
	if not _falling:
		return
	_vy += gravity * delta
	piece.position.y += _vy * delta
	piece.rotation += delta * 6.0
	if piece.global_position.y >= _floor_y - 4.0:
		GameFeel.spawn_fx(DUST, Vector2(piece.global_position.x, _floor_y))
		GameFeel.spawn_fx(SPARK, piece.global_position)
		GameFeel.shake(1.5, 0.1)
		queue_free()
