extends CanvasLayer
## Intro de la historia: frases sobre negro, una por una. Cualquier botón la saltea.
## Main la crea al empezar una partida nueva (ver main.gd, play_intro).

signal finished

const LINES := [
	"Odón se levantó sobre el pantano de las libélulas.",
	"Para construirla, lo drenaron.\nA nosotras nos borraron.",
	"Pero en el Fondo, algo que dormía despertó con hambre.",
	"Zébul me ofreció volver.\nSolo pidió un brazo para entrar al mundo.",
	"Me llamaban Caballito del Diablo.\nAhora tienen razón.",
]

@onready var label: Label = $Text
@onready var hint: Label = $Hint

var _done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # el mundo queda en pausa mientras se cuenta la historia
	label.modulate.a = 0.0
	_play()


func _play() -> void:
	for line in LINES:
		if _done:
			return
		label.text = line
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.8)
		tween.tween_interval(2.2)
		tween.tween_property(label, "modulate:a", 0.0, 0.7)
		await tween.finished
	_finish()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("attack") or event.is_action_pressed("interact") \
			or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	var tween := create_tween()
	tween.tween_property($Black, "color:a", 0.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(hint, "modulate:a", 0.0, 0.3)
	await tween.finished
	finished.emit()
	queue_free()
