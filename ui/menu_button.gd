extends Button
## Botón de menú con estilo: texto que se ilumina al enfocarlo (teclado o joystick).

func _ready() -> void:
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	mouse_entered.connect(grab_focus)
	_on_focus(false)


func _on_focus(on: bool) -> void:
	add_theme_color_override("font_color", Color(1, 0.5, 0.38) if on else Color(0.75, 0.8, 0.86))
	add_theme_color_override("font_focus_color", Color(1, 0.5, 0.38))
	add_theme_color_override("font_hover_color", Color(1, 0.5, 0.38))
	text = ("◆  " + text.trim_prefix("◆  ")) if on else text.trim_prefix("◆  ")
