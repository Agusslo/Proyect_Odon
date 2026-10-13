extends SceneTree
## Arma res://entities/player/ninfa_frames.tres (SpriteFrames) con las tiras de assets/characters/ninfa/.

func _initialize() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var fw: int = meta.frame_w
	var fh: int = meta.frame_h
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	for anim_name in meta.anims:
		var info: Dictionary = meta.anims[anim_name]
		var tex := load("res://assets/characters/ninfa/%s.png" % anim_name) as Texture2D
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, info.fps)
		sf.set_animation_loop(anim_name, info.loop)
		for i in int(info.frames):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, fh)
			sf.add_frame(anim_name, at)
	var err := ResourceSaver.save(sf, "res://entities/player/ninfa_frames.tres")
	print("frames: ", err)
	quit()
