extends CanvasLayer
## Interfaz en pantalla. No conoce al jugador: solo escucha al EventBus.
## Por eso se puede rediseñar entero sin tocar una línea del jugador.

const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")

@onready var health_bar: HBoxContainer = $Margin/HealthBar
@onready var message_label: Label = $MessageLabel
@onready var room_label: Label = $RoomLabel

var _message_tween: Tween
var _room_tween: Tween


func _ready() -> void:
	message_label.modulate.a = 0.0
	room_label.modulate.a = 0.0
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.message_requested.connect(_on_message_requested)
	EventBus.room_entered.connect(_on_room_entered)


func _on_player_health_changed(current: int, max_value: int) -> void:
	# Ajustar la cantidad de íconos a la vida máxima...
	while health_bar.get_child_count() < max_value:
		var icon := TextureRect.new()
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		health_bar.add_child(icon)
	while health_bar.get_child_count() > max_value:
		var extra := health_bar.get_child(health_bar.get_child_count() - 1)
		health_bar.remove_child(extra)
		extra.queue_free()
	# ...y pintar llenos / vacíos.
	for i in health_bar.get_child_count():
		var icon := health_bar.get_child(i) as TextureRect
		icon.texture = HEART_FULL if i < current else HEART_EMPTY


func _on_message_requested(text: String, duration: float) -> void:
	message_label.text = text
	_message_tween = _show_label(message_label, _message_tween, duration)


func _on_room_entered(room_name: String) -> void:
	room_label.text = room_name
	_room_tween = _show_label(room_label, _room_tween, 1.5)


## Aparece, espera y se desvanece. Si había una animación previa, la corta.
func _show_label(label: Label, previous: Tween, duration: float) -> Tween:
	if previous and previous.is_valid():
		previous.kill()
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	return tween
