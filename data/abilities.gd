class_name Abilities
## Catálogo de habilidades desbloqueables.
##
## Usamos constantes en vez de escribir "double_jump" a mano en cada script:
## un typo en un string es un bug silencioso, un typo en una constante
## es un error que Godot marca en rojo al instante.
##
## Para agregar una habilidad nueva:
##   1. Sumar la constante y su entrada en INFO.
##   2. Consultarla en el jugador con GameState.has_ability(Abilities.LA_NUEVA).
##   3. Poner un AbilityPickup en alguna sala con ese valor.

const DOUBLE_JUMP: StringName = &"double_jump"
const DASH: StringName = &"dash"
const GLIDE: StringName = &"glide"

## Textos que se muestran al obtener cada habilidad.
const INFO := {
	DOUBLE_JUMP: {
		"name": "Alas de Libélula",
		"hint": "Presioná Saltar en el aire para aletear otra vez.",
	},
	DASH: {
		"name": "Impulso Sináptico",
		"hint": "Presioná Dash (K / Shift) para lanzarte hacia adelante.",
	},
	GLIDE: {
		"name": "Planeo Nocturno",
		"hint": "Mantené Saltar mientras caés para planear.",
	},
}


static func get_display_name(ability: StringName) -> String:
	return INFO.get(ability, {}).get("name", String(ability))


static func get_hint(ability: StringName) -> String:
	return INFO.get(ability, {}).get("hint", "")
