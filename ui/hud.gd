extends CanvasLayer
## Interfaz en pantalla. No conoce al jugador ni al jefe: solo escucha al EventBus.
## Por eso se puede rediseñar entera sin tocar una línea de gameplay.

const CELL_FULL := preload("res://assets/ui/hud_cell_full.png")
const CELL_EMPTY := preload("res://assets/ui/hud_cell_empty.png")

@onready var health_bar: HBoxContainer = $HealthBar
@onready var energy: TextureProgressBar = $Energy
@onready var area_title: Control = $AreaTitle
@onready var area_name: Label = $AreaTitle/Name
@onready var message_label: Label = $MessageLabel
@onready var boss_bar: Control = $BossBar
@onready var boss_name: Label = $BossBar/Name
@onready var boss_fill: TextureProgressBar = $BossBar/Bar
@onready var hurt_flash: ColorRect = $HurtFlash

var _message_tween: Tween
var _title_tween: Tween


func _ready() -> void:
	message_label.modulate.a = 0.0
	area_title.modulate.a = 0.0
	boss_bar.visible = false
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_energy_changed.connect(_on_energy_changed)
	EventBus.player_hurt.connect(_on_player_hurt)
	EventBus.message_requested.connect(_on_message_requested)
	EventBus.room_entered.connect(_on_room_entered)
	EventBus.boss_started.connect(_on_boss_started)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_ended.connect(func(_defeated: bool) -> void: boss_bar.visible = false)


func _on_player_health_changed(current: int, max_value: int) -> void:
	while health_bar.get_child_count() < max_value:
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(11, 12.5)
		health_bar.add_child(icon)
	while health_bar.get_child_count() > max_value:
		var extra := health_bar.get_child(health_bar.get_child_count() - 1)
		health_bar.remove_child(extra)
		extra.queue_free()
	for i in health_bar.get_child_count():
		var icon := health_bar.get_child(i) as TextureRect
		icon.texture = CELL_FULL if i < current else CELL_EMPTY


func _on_energy_changed(current: int, max_value: int) -> void:
	energy.max_value = max_value
	create_tween().tween_property(energy, "value", float(current), 0.15)


func _on_player_hurt() -> void:
	hurt_flash.color.a = 0.35
	create_tween().tween_property(hurt_flash, "color:a", 0.0, 0.35)


func _on_message_requested(text: String, duration: float) -> void:
	message_label.text = text
	_message_tween = _show(message_label, _message_tween, duration)


## Cartel de zona: solo la primera vez que se entra a una sala.
func _on_room_entered(room_name: String) -> void:
	area_name.text = room_name
	_title_tween = _show(area_title, _title_tween, 2.0, 0.6)


func _on_boss_started(name_text: String, max_health: int) -> void:
	boss_name.text = name_text
	boss_fill.max_value = max_health
	boss_fill.value = max_health
	boss_bar.visible = true
	boss_bar.modulate.a = 0.0
	create_tween().tween_property(boss_bar, "modulate:a", 1.0, 0.6)


func _on_boss_health_changed(current: int, max_value: int) -> void:
	boss_fill.max_value = max_value
	create_tween().tween_property(boss_fill, "value", float(current), 0.2)


## Aparece, espera y se desvanece. Si había una animación previa, la corta.
func _show(node: CanvasItem, previous: Tween, duration: float, fade_in: float = 0.2) -> Tween:
	if previous and previous.is_valid():
		previous.kill()
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, fade_in)
	tween.tween_interval(duration)
	tween.tween_property(node, "modulate:a", 0.0, 0.6)
	return tween
