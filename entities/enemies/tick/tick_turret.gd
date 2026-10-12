class_name TickTurret
extends Enemy
## Garrapata Torreta: se queda quieta. Cuando ve al jugador, infla su saco
## de plasma (aviso) y le dispara un proyectil. Los proyectiles se pueden
## cortar con la espada.

const PROJECTILE := preload("res://entities/enemies/projectile/projectile.tscn")

@export var range_radius: float = 190.0
@export var charge_time: float = 0.7
@export var cooldown: float = 1.6
@export var projectile_speed: float = 120.0
@export var gravity: float = 900.0

@onready var sac: Sprite2D = $Visual/Sac
@onready var nozzle: Node2D = $Visual/Nozzle
@onready var muzzle: Marker2D = $Visual/Nozzle/Muzzle
@onready var sight: RayCast2D = $Sight

var _charge: float = 0.0
var _cool: float = 0.8
var _sac_scale: Vector2


func _setup() -> void:
	_sac_scale = sac.scale


func _ai(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 400.0)
	velocity.x = knockback.x * 0.3
	move_and_slide()

	_cool = maxf(_cool - delta, 0.0)
	var player := get_player()
	var sees := false
	if player and player.state != Player.State.DEAD:
		var to := player.global_position + Vector2(0, -4) - global_position
		if to.length() < range_radius:
			sight.target_position = to
			sight.force_raycast_update()
			sees = not sight.is_colliding()
			visual.scale.x = absf(visual.scale.x) * (1.0 if to.x >= 0.0 else -1.0)
			var local := Vector2(absf(to.x), to.y)
			nozzle.rotation = clampf(local.angle(), -1.2, 0.5)

	if sees and _cool <= 0.0:
		_charge += delta
		var k := _charge / charge_time
		sac.scale = _sac_scale * (1.0 + 0.35 * k + 0.08 * sin(_charge * 40.0))
		sac.modulate = Color(1 + k * 2.0, 1 + k, 1 + k)
		if _charge >= charge_time:
			_fire(player)
	else:
		_charge = maxf(_charge - delta * 2.0, 0.0)
		sac.scale = sac.scale.lerp(_sac_scale, 0.2)
		sac.modulate = Color.WHITE


func _fire(player: Player) -> void:
	_charge = 0.0
	_cool = cooldown
	var p := PROJECTILE.instantiate() as Projectile
	get_parent().add_child(p)
	p.global_position = muzzle.global_position
	p.velocity = (player.global_position + Vector2(0, -4) - muzzle.global_position).normalized() * projectile_speed
	sac.scale = _sac_scale * 0.8
