class_name Assets
## Shared loaders: sprite-sheet animations, atlas regions and one-shot sound effects.

const UI := "res://assets/ui/medieval_ui.png"
const SFX_DIR := "res://assets/audio/sfx/rpg_essentials/"
const SFX := {
	swing = "10_Battle_SFX/22_Slash_04.wav",
	hit = "10_Battle_SFX/15_Impact_flesh_02.wav",
	enemy_die = "10_Battle_SFX/69_Enemy_death_01.wav",
	boss = "10_Battle_SFX/55_Encounter_02.wav",
	jump = "12_Player_Movement_SFX/30_Jump_03.wav",
	hurt = "12_Player_Movement_SFX/61_Hit_03.wav",
	dash = "8_Atk_Magic_SFX/25_Wind_01.wav",
	fire = "8_Atk_Magic_SFX/04_Fire_explosion_04_medium.wav",
	heal = "8_Buffs_Heals_SFX/02_Heal_02.wav",
	upgrade = "8_Buffs_Heals_SFX/16_Atk_buff_04.wav",
	revive = "8_Buffs_Heals_SFX/30_Revive_03.wav",
	confirm = "10_UI_Menu_SFX/013_Confirm_03.wav",
}

static var _frames_cache := {}


## anims: {name: [sheet_path, frame_w, frame_h, frame_count, fps, loop, first_frame (optional)]}.
## Frames are read left-to-right, top-to-bottom, so one sheet can hold several animations.
@warning_ignore("integer_division")
static func frames(anims: Dictionary) -> SpriteFrames:
	var key := str(anims)
	if _frames_cache.has(key):
		return _frames_cache[key]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in anims:
		var a: Array = anims[anim]
		var tex: Texture2D = load(a[0])
		var fw: int = a[1]
		var fh: int = a[2]
		var cols: int = tex.get_width() / fw
		var first: int = a[6] if a.size() > 6 else 0
		sf.add_animation(anim)
		sf.set_animation_speed(anim, a[4])
		sf.set_animation_loop(anim, a[5])
		for i in range(first, first + a[3]):
			sf.add_frame(anim, region(tex, Rect2((i % cols) * fw, (i / cols) * fh, fw, fh)))
	_frames_cache[key] = sf
	return sf


static func region(tex: Variant, rect: Rect2) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex if tex is Texture2D else load(tex)
	at.region = rect
	return at


static func sound(node: Node, key: String, volume_db := -6.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load(SFX_DIR + SFX[key])
	p.volume_db = volume_db
	p.autoplay = true
	p.finished.connect(p.queue_free)
	node.get_tree().root.add_child.call_deferred(p)
