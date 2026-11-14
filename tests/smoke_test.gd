extends SceneTree
## Plays the game's rules without a human and checks them: kill heal, death/respawn,
## each boss fight (scroll lock, walls, full heal, gear upgrade) and the win screen.
## Run from the project folder:  godot --path . -s res://tests/smoke_test.gd -- <folder for screenshots>

var main: Node
var failed := false
var shots := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	shots = args[0] if args.size() > 0 else ""
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await _frames(10)
	main._start()
	await _frames(5)
	var p: Player = main.player

	# More mobs every level.
	var counts := [0, 0, 0]
	for n in main.world.get_children():
		if n is Enemy and not n.kind.has("boss"):
			counts[n.get_meta("section")] += 1
	_check(counts[0] < counts[1] and counts[1] < counts[2], "mob count rises per level %s" % [counts])

	# S drops through a one-way platform (first one: x 600-696, top at GROUND_Y - 56).
	p.global_position = Vector2(640, main.GROUND_Y - 70)
	await _frames(40)
	_check(absf(p.global_position.y - (main.GROUND_Y - 56)) < 1.0, "landed on platform (y=%d)" % p.global_position.y)
	Input.action_press("drop")
	await _frames(2)
	Input.action_release("drop")
	await _frames(40)
	_check(absf(p.global_position.y - main.GROUND_Y) < 1.0, "dropped through to the ground (y=%d)" % p.global_position.y)

	# Killing a mob heals 10.
	p.hp = 50
	var mob: Enemy = _first_mob(0)
	mob.take_damage(99999)
	_check(p.hp == 60, "kill heals +10 (hp=%d)" % p.hp)

	# Dying sends you back to the start of the level with full health.
	p.global_position.x = 1500
	await _frames(2)
	p.take_damage(1000)
	await _frames(200)
	_check(not p.dead and p.hp == 100, "respawned with full health")
	_check(is_equal_approx(p.global_position.x, 80.0), "respawned at level start (x=%d)" % p.global_position.x)

	# Esc pauses (menu shown, knight frozen even with a key held) and Esc again resumes.
	_press_esc()
	await _frames(2)
	Input.action_press("move_right")
	var x0 := p.global_position.x
	await _frames(30)
	_check(paused and main.pause_panel.visible and p.global_position.x == x0, "esc pauses the game")
	await _shot("paused")
	Input.action_release("move_right")
	_press_esc()
	await _frames(2)
	_check(not paused and not main.pause_panel.visible, "esc resumes")

	for i in 3:
		# Walking into the arena starts the fight and locks the scrolling.
		p.global_position = Vector2(main.arena_start(i) + 100, main.GROUND_Y)
		await _frames(30)
		_check(main.boss_fight, "boss %d fight started" % (i + 1))
		_check(main.walls.size() == 2 and main.cam.limit_left == int(main.arena_start(i)), "boss %d arena locked" % (i + 1))
		if i == 0:
			# Dying mid-fight unlocks the arena and resets the level with a fresh boss,
			# even if a fireball thrown just before dying finishes the boss off afterwards.
			main.bosses[0].hp = 1
			Projectile.spawn(main.world, main.bosses[0].global_position + Vector2(-150, -30), 1, 20, "enemy", Player.FIREBALL, 280.0)
			p.take_damage(1000)
			await _frames(200)
			_check(not main.boss_fight and main.walls.is_empty(), "death ends the boss fight")
			_check(main.section == 0 and p.tier == 0 and is_equal_approx(p.global_position.x, 80.0), "still level 1 after boss died post-death")
			_check(main.bosses[0].hp == main.bosses[0].max_hp and not main.bosses[0].active, "boss reset after death")
			p.global_position = Vector2(main.arena_start(i) + 100, main.GROUND_Y)
			await _frames(30)
			_check(main.boss_fight, "boss fight restarts")
		await _frames(60)
		await _shot("boss_%d" % (i + 1))
		p.hp = 30
		main.bosses[i].take_damage(99999)
		await _frames(5)
		_check(not main.boss_fight and main.walls.is_empty() and main.cam.limit_left == 0, "boss %d arena unlocked" % (i + 1))
		_check(p.hp == 100, "boss %d full heal" % (i + 1))
		if i < 2:
			_check(main.section == i + 1 and p.tier == i + 1, "level %d reached with tier %d gear" % [i + 2, i + 2])
			p.global_position = Vector2((i + 1) * main.SECTION_W + 300, main.GROUND_Y)
			await _frames(150)
			await _shot("level_%d" % (i + 2))
	_check(main.state == "won" and main.win_panel.visible, "victory screen shown")
	await _shot("victory")

	# Monsters with a ranged attack throw it from a distance (tested in the empty final arena).
	var thrown := []
	main.win_panel.hide()
	main.world.child_entered_tree.connect(func(n: Node) -> void:
		if n is Projectile and n.target == "player":
			thrown.append(n))
	for k in ["goblin", "mushroom", "skeleton", "eye"]:
		thrown.clear()
		p.hp = 100
		p.global_position = Vector2(9200, main.GROUND_Y)
		var dist: float = Enemy.KINDS[k].throw.range - 20.0
		var e := Enemy.create(k, Vector2(9200 - dist, main.GROUND_Y - (18.0 if k == "eye" else 0.0)), 2)
		main.world.add_child(e)
		await _frames(105)  # first throw is released after ~80-100 frames
		await _shot("throw_" + k)
		await _frames(45)
		_check(thrown.size() > 0 and p.hp < 100, "%s throws and hits (hp=%d)" % [k, p.hp])
		e.queue_free()

	print("SMOKE TEST " + ("FAILED" if failed else "PASSED"))
	quit(1 if failed else 0)


func _first_mob(section: int) -> Enemy:
	for n in main.world.get_children():
		if n is Enemy and n.get_meta("section") == section and not n.kind.has("boss") and not n.dead:
			return n
	return null


func _press_esc() -> void:
	for down in [true, false]:
		var e := InputEventAction.new()
		e.action = "ui_cancel"
		e.pressed = down
		Input.parse_input_event(e)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	failed = failed or not ok


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _shot(shot_name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(shots.path_join(shot_name + ".png"))
