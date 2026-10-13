class_name Afterimage
extends Sprite2D
## Sombra que deja el Galope del Diablo: una copia del cuadro actual, teñida de rojo, que se apaga.

static func spawn(from: AnimatedSprite2D, color: Color = Color(1.0, 0.18, 0.12, 0.65)) -> void:
	var tex := from.sprite_frames.get_frame_texture(from.animation, from.frame)
	if tex == null:
		return
	var ghost := Afterimage.new()
	ghost.texture = tex
	ghost.centered = from.centered
	ghost.offset = from.offset
	ghost.flip_h = from.flip_h
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = color
	ghost.z_index = 15
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ghost.material = mat
	var layer := from.get_tree().get_first_node_in_group("fx_layer")
	if layer == null:
		return
	layer.add_child(ghost)
	ghost.global_position = from.global_position
	ghost.scale = from.scale
	ghost.rotation = from.global_rotation
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.28)
	tween.tween_callback(ghost.queue_free)
