extends Node2D
## Builds the whole game: one long forest map split into 3 levels, each ending in a boss arena.
## The title screen sits over the live map; Start drops the knight in.

const GROUND_Y := 222.0
const SECTION_W := 3200.0  # length of one level, including its boss arena
const ARENA_W := 480.0  # one screen
const SECTIONS := 3
const BOSSES := ["wizard", "bringer", "demon_slime"]
## Per level: mob kinds (spawned in this order, looping), average gap between mobs, background tint, music.
const LEVELS := [
	{mobs = ["rat", "goblin", "slime", "bat", "mushroom"], gap = 360.0, tint = Color(1, 1, 1), music = "3. Darkwood Path"},
	{mobs = ["skeleton", "worm", "eye", "slime", "mimic", "goblin"], gap = 280.0, tint = Color(0.8, 0.7, 1.0), music = "7. Mystic Grove"},
	{mobs = ["skeleton", "worm", "demon", "mimic", "eye", "slime"], gap = 210.0, tint = Color(1.0, 0.6, 0.55), music = "4. Frostbound"},
]
## HUD icons for each gear tier: sword sheet and armour cell in the Shikashi icon sheet.
const GEAR := [
	{name = "BRONZE SWORD & LEATHER", sword = "bronze", armor = Rect2(192, 224, 32, 32)},
	{name = "STEEL SWORD & CHAINMAIL", sword = "steel", armor = Rect2(224, 224, 32, 32)},
	{name = "GOLD SWORD & PLATE ARMOR", sword = "gold", armor = Rect2(128, 224, 32, 32)},
]
const KILL_HEAL := 10
const ENV := "res://assets/environment/darkwood_forest/"
const PROPS := ["LargeStone1", "Tombstone", "TreeTrunk1", "LittleMossStone", "Fence", "RoundStone", "Flower", "LargeStone2"]
const MUSIC := "res://assets/audio/music/medieval_tracks/Loops/ogg/%s.ogg"
const FONT := "res://assets/ui/fonts/press_start_2p/PressStart2P-Regular.ttf"
const ICONS := "res://assets/icons/shikashi_fantasy/#1 - Transparent Icons.png"
const BAR_W := 50.0  # inner width of the health bar art

var state := "title"  # title, play, won
var section := 0  # current level (0-2)
var boss_fight := false
var player: Player
var bosses: Array[Enemy] = [null, null, null]
var walls: Array[StaticBody2D] = []
var cam := Camera2D.new()
var music := AudioStreamPlayer.new()
var background := Node2D.new()
var world := Node2D.new()
var _title_time := 0.0
# UI
var title: Control
var hud: Control
var win_panel: Control
var pause_panel: Control
var banner: Label
var hp_fill: TextureRect
var hp_label: Label
var level_label: Label
var sword_icon: TextureRect
var armor_icon: TextureRect
var boss_box: Control
var boss_name: Label
var boss_fill: TextureRect


func _ready() -> void:
	# This node and the UI keep running while paused (to read Esc and the menu buttons); the world freezes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	background.process_mode = Node.PROCESS_MODE_PAUSABLE
	cam.process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_background()
	add_child(world)
	_build_map()
	for i in SECTIONS:
		_spawn_section(i)
	cam.limit_left = 0
	cam.limit_right = int(SECTION_W * SECTIONS)
	cam.limit_top = 0
	cam.limit_bottom = 270
	cam.position = Vector2(240, 135)
	cam.position_smoothing_enabled = true
	cam.limit_smoothed = true
	add_child(cam)
	cam.make_current()
	music.volume_db = -10.0
	add_child(music)
	_build_ui()
	_play_music("10. Elven Dawn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state == "play":  # ui_cancel = Esc
		_toggle_pause()


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused


func _main_menu() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if state == "title":
		_title_time += delta
		cam.position.x = 240.0 + pingpong(_title_time * 25.0, 1800.0)  # slow pan over level 1
		return
	cam.position = Vector2(player.global_position.x, 135)
	if boss_fight:
		var boss := bosses[section]
		if is_instance_valid(boss):  # it can fade out while the knight is dead, before the level resets
			boss_fill.size.x = BAR_W * maxf(boss.hp, 0) / boss.max_hp
	elif bosses[section] and not player.dead and player.global_position.x > arena_start(section) + 60.0:
		_start_boss()


func arena_start(i: int) -> float:
	return (i + 1) * SECTION_W - ARENA_W


# ---------- game flow ----------

func _start() -> void:
	state = "play"
	title.hide()
	hud.show()
	Assets.sound(self, "confirm")
	player = Player.new()
	player.position = Vector2(80, GROUND_Y)
	player.hp_changed.connect(_on_hp_changed)
	player.died.connect(_on_player_died)
	world.add_child(player)
	_update_gear()
	_play_music(LEVELS[0].music)


func _start_boss() -> void:
	boss_fight = true
	var a := arena_start(section)
	cam.limit_left = int(a)
	cam.limit_right = int(a + ARENA_W)
	walls = [_solid(Rect2(a - 16, -200, 16, 500)), _solid(Rect2(a + ARENA_W, -200, 16, 500))]
	bosses[section].active = true
	boss_name.text = bosses[section].kind.boss
	boss_fill.size.x = BAR_W
	boss_box.show()
	_play_music("8. Throne of Storms")
	Assets.sound(self, "boss")


func _end_boss_fight() -> void:
	boss_fight = false
	boss_box.hide()
	for w in walls:
		w.queue_free()
	walls.clear()
	cam.limit_left = 0
	cam.limit_right = int(SECTION_W * SECTIONS)


func _on_enemy_killed(e: Enemy) -> void:
	# Kills that land after the knight died (e.g. a fireball still in flight) don't count:
	# the level is about to restart, and counting a boss kill here would skip to the next level.
	if not player or player.dead:
		return
	if e != bosses[section]:
		_popup_heal(player.heal(KILL_HEAL))
		return
	# Boss down: full heal, then the next level brings better gear.
	bosses[section] = null
	_end_boss_fight()
	_popup_heal(player.heal(Player.MAX_HP))
	Assets.sound(self, "revive")
	if section == SECTIONS - 1:
		state = "won"
		win_panel.show()
		_play_music("2. Winds of Valor")
		return
	section += 1
	player.set_tier(section)
	_update_gear()
	Assets.sound(self, "upgrade")
	_banner("BOSS DEFEATED!\n\nLEVEL %d\n%s" % [section + 1, GEAR[section].name])
	_play_music(LEVELS[section].music)
	create_tween().tween_property(background, "modulate", LEVELS[section].tint, 2.0)


func _on_player_died() -> void:
	_banner("YOU DIED")
	await get_tree().create_timer(1.5, false).timeout  # false: the countdown waits while paused
	# Restart the current level: fresh mobs and boss, knight back at its start with full health.
	for n in world.get_children():
		if n is Enemy and n.get_meta("section") == section:
			n.queue_free()
	if boss_fight:
		_end_boss_fight()
	_spawn_section(section)
	player.respawn(Vector2(section * SECTION_W + 80, GROUND_Y))
	cam.position = Vector2(player.global_position.x, 135)
	cam.reset_smoothing()
	Assets.sound(self, "revive")


# ---------- world ----------

func _build_background() -> void:
	# Far layers scroll slowly, near layers faster.
	var layers := {starsky = 0.0, Clouds = 0.08, mountains = 0.15, farforestbaretrees = 0.3, farforest = 0.45, forest = 0.6, foreground = 0.8}
	for n: String in layers:
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(layers[n], 1)
		p.repeat_size = Vector2(480, 0)
		p.repeat_times = 3
		var s := Sprite2D.new()
		s.texture = load(ENV + "Backgrounds/%s.png" % n)
		s.centered = false
		s.scale = Vector2(1.5, 1.5)
		p.add_child(s)
		background.add_child(p)
	add_child(background)


func _build_map() -> void:
	var width := SECTION_W * SECTIONS
	_solid(Rect2(-32, GROUND_Y, width + 64, 64))
	_solid(Rect2(-32, -200, 32, 500))  # left edge of the world
	_solid(Rect2(width, -200, 32, 500))  # right edge
	_tiled(ENV + "Free Environment/Grass.png", Rect2(0, GROUND_Y, width, 16))
	_tiled(ENV + "Free Environment/Ground.png", Rect2(0, GROUND_Y + 16, width, 48))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for x in range(150, int(width), 170):
		var prop := Sprite2D.new()
		prop.texture = load(ENV + "Free Environment/%s.png" % PROPS[rng.randi() % PROPS.size()])
		prop.position = Vector2(x + rng.randf_range(-40, 40), GROUND_Y - 8)
		world.add_child(prop)
	# One-way platforms (jump up through them, S to drop down) in each level, outside the arena.
	for i in SECTIONS:
		for j in 4:
			var x := i * SECTION_W + 600.0 + j * 560.0
			var y := GROUND_Y - (56.0 if j % 2 == 0 else 92.0)
			_solid(Rect2(x, y, 96, 8), true)
			_tiled(ENV + "Free Environment/BridgeCenter.png", Rect2(x, y, 96, 16))


func _solid(r: Rect2, one_way := false) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = r.size
	shape.position = r.get_center()
	shape.one_way_collision = one_way
	body.add_child(shape)
	if one_way:
		body.collision_layer = 8  # layer 4: the player can drop through these
	world.add_child(body)
	return body


func _tiled(path: String, r: Rect2) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, r.size)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.position = r.position
	world.add_child(s)


func _spawn_section(i: int) -> void:
	var lvl: Dictionary = LEVELS[i]
	var rng := RandomNumberGenerator.new()
	rng.seed = i + 7  # same layout every time the level restarts
	var x := i * SECTION_W + 420.0
	var n := 0
	while x < arena_start(i) - 120.0:
		var kind: String = lvl.mobs[n % lvl.mobs.size()]
		var y := GROUND_Y - (70.0 if Enemy.KINDS[kind].get("fly", false) else 0.0)
		_add_enemy(kind, Vector2(x, y), i)
		x += lvl.gap * rng.randf_range(0.7, 1.3)
		n += 1
	bosses[i] = _add_enemy(BOSSES[i], Vector2(arena_start(i) + ARENA_W - 110, GROUND_Y), i)


func _add_enemy(kind: String, pos: Vector2, i: int) -> Enemy:
	var e := Enemy.create(kind, pos, i)
	e.set_meta("section", i)
	e.killed.connect(_on_enemy_killed)
	world.add_child(e)
	return e


func _play_music(track: String) -> void:
	var stream: AudioStreamOggVorbis = load(MUSIC % track)
	stream.loop = true
	music.stream = stream
	music.play()


# ---------- UI ----------

func _build_ui() -> void:
	var theme := Theme.new()
	theme.default_font = load(FONT)
	theme.default_font_size = 8
	theme.set_color("font_outline_color", "Label", Color.BLACK)
	theme.set_constant("outline_size", "Label", 4)
	var plank := StyleBoxTexture.new()
	plank.texture = Assets.region(Assets.UI, Rect2(224, 35, 27, 25))
	plank.set_texture_margin_all(6)
	plank.set_content_margin_all(8)
	for s in ["normal", "hover", "pressed"]:
		theme.set_stylebox(s, "Button", plank)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", Color(1, 0.95, 0.8))
	theme.set_color("font_hover_color", "Button", Color(1, 1, 0.4))
	theme.set_color("font_focus_color", "Button", Color(1, 1, 0.4))

	var layer := CanvasLayer.new()
	add_child(layer)
	var root := _screen(layer)
	root.theme = theme

	# Title screen
	title = _screen(root)
	_board(title, Rect2(100, 36, 280, 196))
	_label(title, "KNIGHT OF\n\nDARKWOOD", Vector2(100, 62), 16, 280)
	_label(title, "A/D MOVE   W/SPACE JUMP\nS DROP     SHIFT DASH\nL-CLICK SWORD   ESC PAUSE\nR-CLICK FIREBALL", Vector2(100, 124), 8, 280)
	var start := _button(title, "START", Vector2(195, 184))
	start.pressed.connect(_start)
	start.grab_focus()

	# HUD
	hud = _screen(root)
	hud.hide()
	hp_fill = _bar(hud, Vector2(8, 8), 2.0)
	hp_label = _label(hud, "100 / 100", Vector2(12, 40))
	level_label = _label(hud, "LEVEL 1", Vector2(0, 12), 8, 480)
	sword_icon = _icon(hud, Vector2(400, 6))
	armor_icon = _icon(hud, Vector2(438, 6))
	boss_box = _screen(hud)
	boss_box.hide()
	boss_name = _label(boss_box, "", Vector2(0, 30), 8, 480)
	boss_fill = _bar(boss_box, Vector2(240 - 62 * 1.25, 42), 2.5)

	banner = _label(root, "", Vector2(0, 92), 16, 480)

	# Victory screen
	win_panel = _screen(root)
	win_panel.hide()
	_board(win_panel, Rect2(120, 60, 240, 150))
	_label(win_panel, "VICTORY!\n\nDARKWOOD IS SAFE", Vector2(120, 90), 8, 240)
	_button(win_panel, "PLAY AGAIN", Vector2(180, 160)).pressed.connect(get_tree().reload_current_scene)

	# Pause menu (Esc)
	pause_panel = _screen(root)
	pause_panel.hide()
	_board(pause_panel, Rect2(140, 60, 200, 150))
	_label(pause_panel, "PAUSED", Vector2(140, 84), 16, 200)
	_button(pause_panel, "RESUME", Vector2(180, 118)).pressed.connect(_toggle_pause)
	_button(pause_panel, "MAIN MENU", Vector2(180, 156)).pressed.connect(_main_menu)


func _screen(parent: Node) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _label(parent: Node, text: String, pos: Vector2, font_size := 8, width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	if width > 0.0:
		l.size.x = width
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = Vector2(90 if text.length() < 6 else 120, 28)
	parent.add_child(b)
	return b


func _board(parent: Node, r: Rect2) -> void:
	var board := NinePatchRect.new()
	board.texture = load(Assets.UI)
	board.region_rect = Rect2(3, 22, 71, 71)  # wooden board without its chain
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		board.set_patch_margin(side, 14)
	board.position = r.position
	board.size = r.size
	parent.add_child(board)


## Health bar from the UI sheet: wooden frame, dark trough and a red fill whose width we change.
func _bar(parent: Node, pos: Vector2, s: float) -> TextureRect:
	var frame := TextureRect.new()
	frame.texture = Assets.region(Assets.UI, Rect2(2, 97, 62, 14))
	frame.position = pos
	frame.scale = Vector2(s, s)
	parent.add_child(frame)
	var fill: TextureRect
	for src in [Rect2(50, 101, 1, 6), Rect2(20, 101, 1, 6)]:  # trough, then red fill
		fill = TextureRect.new()
		fill.texture = Assets.region(Assets.UI, src)
		fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fill.position = Vector2(6, 4)
		fill.size = Vector2(BAR_W, 6)
		frame.add_child(fill)
	return fill


func _icon(parent: Node, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.position = pos
	t.size = Vector2(32, 32)
	parent.add_child(t)
	return t


func _update_gear() -> void:
	sword_icon.texture = Assets.region("res://assets/icons/weapons_16x16/%s-weapons.png" % GEAR[section].sword, Rect2(32, 0, 16, 16))
	armor_icon.texture = Assets.region(ICONS, GEAR[section].armor)
	level_label.text = "LEVEL %d" % (section + 1)


func _on_hp_changed(hp: int) -> void:
	hp_fill.size.x = BAR_W * hp / Player.MAX_HP
	hp_label.text = "%d / %d" % [hp, Player.MAX_HP]


## The "+N" that floats up off the health bar.
func _popup_heal(amount: int) -> void:
	if amount <= 0:
		return
	var l := _label(hud, "+%d" % amount, Vector2(140, 12))
	l.add_theme_color_override("font_color", Color(0.45, 1, 0.45))
	var t := l.create_tween().set_parallel()
	t.tween_property(l, "position:y", -16.0, 1.0).as_relative()
	t.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)
	Assets.sound(self, "heal", -12)


func _banner(text: String) -> void:
	banner.text = text
	banner.modulate.a = 1.0
	var t := banner.create_tween()
	t.tween_interval(2.5)
	t.tween_property(banner, "modulate:a", 0.0, 0.8)
