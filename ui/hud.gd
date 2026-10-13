extends CanvasLayer
## Interfaz en pantalla. No conoce al jugador ni al jefe: solo escucha al EventBus.
## Por eso se puede rediseñar entera sin tocar una línea de gameplay.
##
## Arriba a la izquierda:
##   - Retrato de Ninfa en un aro de hierro (late en rojo con Hambre).
##   - Vida: celdas hexagonales. Al perder una, destella blanco y se apaga.
##     Con 1 sola de vida, la última se pone roja y late (¡peligro!).
##   - Brasas: 3 segmentos de fuego. Cada segmento lleno = 1 Garra Infernal.
##     Si intentás usar la Garra sin un segmento lleno, la barra tiembla en rojo.

const HP_FULL := preload("res://assets/ui/hp_full.png")
const HP_EMPTY := preload("res://assets/ui/hp_empty.png")
const HP_FLASH := preload("res://assets/ui/hp_flash.png")
const HP_DANGER := preload("res://assets/ui/hp_danger.png")
const CELL_SIZE := Vector2(11, 11)

@onready var panel: Control = $Panel
@onready var portrait: TextureRect = $Panel/Portrait
@onready var health_bar: HBoxContainer = $Panel/HealthBar
@onready var brasas: HBoxContainer = $Panel/Brasas
@onready var hunger_label: Label = $Panel/HungerLabel
@onready var area_title: Control = $AreaTitle
@onready var area_name: Label = $AreaTitle/Name
@onready var message_label: Label = $MessageLabel
@onready var boss_bar: Control = $BossBar
@onready var boss_name: Label = $BossBar/Name
@onready var boss_fill: TextureProgressBar = $BossBar/Bar
@onready var hurt_flash: ColorRect = $HurtFlash

var _message_tween: Tween
var _title_tween: Tween
var _hp: int = -1                 # vida mostrada (-1 = todavía no se dibujó)
var _segments: Array[TextureProgressBar] = []
var _seg_full: Array[bool] = [false, false, false]
var _shake: float = 0.0           # temblor de la barra de Brasas
var _hungry: bool = false
var _brasas_origin: Vector2


func _ready() -> void:
	message_label.modulate.a = 0.0
	area_title.modulate.a = 0.0
	boss_bar.visible = false
	hunger_label.visible = false
	for child in brasas.get_children():
		_segments.append(child as TextureProgressBar)
	_brasas_origin = brasas.position
	EventBus.player_hunger_changed.connect(_on_hunger_changed)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_energy_changed.connect(_on_energy_changed)
	EventBus.brasas_insufficient.connect(_on_brasas_insufficient)
	EventBus.player_hurt.connect(_on_player_hurt)
	EventBus.message_requested.connect(_on_message_requested)
	EventBus.room_entered.connect(_on_room_entered)
	EventBus.boss_started.connect(_on_boss_started)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_ended.connect(func(_defeated: bool) -> void: boss_bar.visible = false)


# ------------------------------------------------------------------ vida

func _on_player_health_changed(current: int, max_value: int) -> void:
	# Una celda por punto de vida máxima.
	while health_bar.get_child_count() < max_value:
		var icon := TextureRect.new()
		icon.texture = HP_FULL
		icon.custom_minimum_size = CELL_SIZE
		icon.pivot_offset = CELL_SIZE / 2.0
		health_bar.add_child(icon)
	while health_bar.get_child_count() > max_value:
		var extra := health_bar.get_child(health_bar.get_child_count() - 1)
		health_bar.remove_child(extra)
		extra.queue_free()

	var before := _hp if _hp >= 0 else current
	for i in health_bar.get_child_count():
		var icon := health_bar.get_child(i) as TextureRect
		if i < current:
			icon.texture = HP_FULL
			icon.modulate = Color.WHITE
			if i >= before:
				_pop(icon, 1.5)          # celda recuperada (al Devorar o sumergirse)
		elif i < before:
			_lose_cell(icon)             # celda perdida: destello y se apaga
		else:
			icon.texture = HP_EMPTY
	_hp = current


func _lose_cell(icon: TextureRect) -> void:
	icon.texture = HP_FLASH
	icon.scale = Vector2(1.6, 1.6)
	var tween := icon.create_tween()
	tween.tween_property(icon, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if health_bar.get_children().find(icon) >= _hp:
			icon.texture = HP_EMPTY)


func _pop(node: Control, amount: float) -> void:
	node.scale = Vector2(amount, amount)
	node.create_tween().tween_property(node, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ Brasas

func _on_energy_changed(current: int, max_value: int) -> void:
	var per := float(max_value) / _segments.size()
	for i in _segments.size():
		var seg := _segments[i]
		seg.max_value = per
		var target := clampf(current - i * per, 0.0, per)
		var tween := seg.create_tween()
		if target < seg.value - 1.0:
			# Se gastaron Brasas: el segmento destella y se vacía con un pequeño retraso.
			seg.modulate = Color(2.4, 2.0, 1.6)
			tween.set_parallel()
			tween.tween_property(seg, "modulate", Color.WHITE, 0.35)
			tween.tween_property(seg, "value", target, 0.3).set_delay(0.08) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(seg, "value", target, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var full := target >= per - 0.01
		if full and not _seg_full[i]:
			_pop(seg, 1.35)                       # el segmento se llenó: ¡listo para una Garra!
			seg.modulate = Color(2.2, 1.8, 1.4)
			seg.create_tween().tween_property(seg, "modulate", Color.WHITE, 0.3)
		_seg_full[i] = full


func _on_brasas_insufficient() -> void:
	_shake = 0.3
	for seg in _segments:
		seg.modulate = Color(1.8, 0.25, 0.2)
		seg.create_tween().tween_property(seg, "modulate", Color.WHITE, 0.4)


# ------------------------------------------------------------------ Hambre

## Con Hambre el retrato late en rojo y aparece el aviso.
func _on_hunger_changed(hungry: bool, _ratio: float) -> void:
	_hungry = hungry
	hunger_label.visible = hungry
	if not hungry:
		portrait.modulate = Color.WHITE


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0

	# Segmentos llenos: brillo suave que respira.
	for i in _segments.size():
		var seg := _segments[i]
		if _seg_full[i] and seg.modulate.is_equal_approx(Color.WHITE) == false:
			continue  # está en medio de un destello
		if _seg_full[i]:
			var g := 1.0 + 0.18 * (0.5 + 0.5 * sin(t * 4.0 + i * 0.9))
			seg.self_modulate = Color(g, g, g)
		else:
			seg.self_modulate = Color.WHITE

	# Temblor cuando no alcanzan las Brasas.
	if _shake > 0.0:
		_shake -= delta
		brasas.position = _brasas_origin + Vector2(round(randf_range(-2, 2)), 0)
	else:
		brasas.position = _brasas_origin

	# Última celda de vida en peligro: roja y latiendo.
	if _hp == 1 and health_bar.get_child_count() > 1:
		var last := health_bar.get_child(0) as TextureRect
		if last.texture != HP_FLASH:
			last.texture = HP_DANGER
			var s := 1.0 + 0.12 * maxf(sin(t * 7.0), 0.0)
			last.scale = Vector2(s, s)

	if _hungry:
		var k := 0.5 + 0.5 * sin(t * 6.0)
		hunger_label.modulate.a = 0.55 + 0.45 * k
		portrait.modulate = Color(1.0, 1.0 - 0.45 * k, 1.0 - 0.45 * k)


# ------------------------------------------------------------------ resto

func _on_player_hurt() -> void:
	hurt_flash.color.a = 0.35
	create_tween().tween_property(hurt_flash, "color:a", 0.0, 0.35)
	# El panel entero se sacude un poco con el golpe.
	var tween := create_tween()
	for k in 4:
		tween.tween_property(panel, "position", Vector2(5, 5) + Vector2(2 - 4 * (k % 2), 0), 0.03)
	tween.tween_property(panel, "position", Vector2(5, 5), 0.03)


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
