class_name HurtboxComponent
extends Area2D
## Zona que RECIBE daño. Detecta HitboxComponents y descuenta vida al HealthComponent.
##
## Capas sugeridas:
##   hurtbox del jugador -> capa 4 "playerHurtbox", máscara 7 "enemyHitbox"
##   hurtbox de enemigos -> capa 5 "enemyHurtbox",  máscara 6 "playerHitbox"

signal hit_received(hitbox: HitboxComponent)

@export var health_component: HealthComponent
## Segundos de invencibilidad después de un golpe (0 = sin invencibilidad).
@export var invincibility_time: float = 0.0

var is_invincible: bool = false

var _invincibility_timer: Timer


func _ready() -> void:
	monitoring = true    # Detecta las Hitbox que entran...
	monitorable = false  # ...pero nadie necesita detectarla a ella.
	area_entered.connect(_on_area_entered)

	# Usamos un Timer hijo (y no "await create_timer") porque si la entidad
	# muere durante la espera, el Timer muere con ella sin dejar errores.
	_invincibility_timer = Timer.new()
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(_invincibility_timer)


func start_invincibility(duration: float) -> void:
	is_invincible = true
	_invincibility_timer.start(duration)


func _on_area_entered(area: Area2D) -> void:
	_try_take_hit(area)


func _try_take_hit(area: Area2D) -> bool:
	if is_invincible or not area is HitboxComponent:
		return false

	var hitbox := area as HitboxComponent
	if health_component:
		health_component.take_damage(hitbox.damage)
	hit_received.emit(hitbox)
	hitbox.hit_landed.emit(self)

	if invincibility_time > 0.0:
		start_invincibility(invincibility_time)
	return true


func _on_invincibility_timeout() -> void:
	is_invincible = false
	# area_entered solo se dispara al ENTRAR. Si al terminar la invencibilidad
	# seguimos encima de algo que daña, recibimos el golpe ahora.
	for area in get_overlapping_areas():
		if _try_take_hit(area):
			break
