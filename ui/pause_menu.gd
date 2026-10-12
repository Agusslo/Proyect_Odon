extends CanvasLayer
## Menú de pausa (Esc / Start). Mientras está abierto, el árbol de escenas queda pausado.

@onready var root: Control = $Root
@onready var resume_button: Button = $Root/Box/Resume


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	$Root/Box/Resume.pressed.connect(toggle)
	$Root/Box/Title.pressed.connect(_to_title)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	root.visible = paused
	if paused:
		resume_button.grab_focus()


func _to_title() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
