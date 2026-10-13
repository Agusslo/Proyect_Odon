class_name HealthComponent
extends Node
## Componente desacoplado para gestionar la vida de cualquier entidad.
##
## No sabe QUIÉN lo usa (jugador, enemigo, caja rompible): solo lleva la cuenta
## y avisa por señales. El dueño decide qué hacer (animación, morir, HUD...).

signal health_changed(new_health: int, max_health: int)
signal health_depleted

@export var max_health: int = 5:
	set(value):
		max_health = maxi(1, value)
		if is_node_ready():
			current_health = clampi(current_health, 0, max_health)
			health_changed.emit(current_health, max_health)

var current_health: int
## Si es true, el primer golpe que lo mataría lo deja con 1 de vida (después se apaga solo).
## Los enemigos devorables lo usan para quedar SIEMPRE aturdidos antes de morir.
var survive_once: bool = false


func _ready() -> void:
	current_health = max_health


## Aplica daño. Si la vida llega a 0 emite health_depleted (una sola vez).
func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	current_health = clampi(current_health - amount, 0, max_health)
	if current_health == 0 and survive_once:
		survive_once = false
		current_health = 1
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		health_depleted.emit()


## Cura sin pasarse de max_health. No revive a los muertos (para eso: reset_health).
func heal(amount: int) -> void:
	if amount <= 0 or current_health >= max_health or is_dead():
		return

	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)


## Restablece la vida al máximo (terminales, respawn).
func reset_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health == 0


## Porcentaje de 0.0 a 1.0 (útil para barras de vida de jefes).
func get_health_percent() -> float:
	return float(current_health) / float(max_health)
