extends Node2D
## Pantalla de título: Continuar (si hay partida guardada), Nueva partida, Salir.

const MAIN := "res://world/main/main.tscn"

@onready var continue_button: Button = $UI/Box/Continue
@onready var new_button: Button = $UI/Box/New


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	continue_button.visible = GameState.has_save()
	continue_button.pressed.connect(_continue)
	new_button.pressed.connect(_new_game)
	$UI/Box/Quit.pressed.connect(func() -> void: get_tree().quit())
	(continue_button if continue_button.visible else new_button).grab_focus()
	var logo := $UI/Logo as Control
	logo.modulate.a = 0.0
	create_tween().tween_property(logo, "modulate:a", 1.0, 1.5)


func _process(delta: float) -> void:
	# La cámara se desliza despacio: el fondo hace parallax solo.
	$Camera2D.position.x += 12.0 * delta


func _continue() -> void:
	get_tree().change_scene_to_file(MAIN)


func _new_game() -> void:
	GameState.delete_save()
	GameState.reset()
	get_tree().change_scene_to_file(MAIN)
