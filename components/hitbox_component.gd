class_name HitboxComponent
extends Area2D
## Zona que HACE daño: espada, cuerpo de un enemigo, pinches, proyectiles.
##
## Es casi solo datos. La lógica la tiene HurtboxComponent: cuando detecta
## una Hitbox, le descuenta vida a su dueño y le avisa a la Hitbox con hit_landed.
##
## Capas sugeridas (Proyecto > Configuración > Nombres de capas):
##   espada del jugador -> capa 6 "playerHitbox"
##   enemigos y trampas -> capa 7 "enemyHitbox"

## Se emite cuando este golpe conecta con una Hurtbox (la emite la Hurtbox).
## El jugador la usa para el "pogo" (rebote al pegar hacia abajo).
@warning_ignore("unused_signal")
signal hit_landed(hurtbox: HurtboxComponent)

@export var damage: int = 1
## Fuerza con la que empuja a quien recibe el golpe (px/s).
@export var knockback_force: float = 150.0
## true = trampa del entorno (pinches, ácido): el jugador vuelve al último suelo seguro.
@export var is_hazard: bool = false


func _ready() -> void:
	monitoring = false  # No necesita detectar a nadie...
	monitorable = true  # ...solo ser detectada por las Hurtbox.
