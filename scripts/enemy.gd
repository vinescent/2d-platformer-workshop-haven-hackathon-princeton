class_name Enemy extends CharacterBody2D
## Every mob and boss. What each one looks like and how it fights comes from its entry in KINDS.

signal killed(enemy: Enemy)

const MOBS := "res://assets/enemies/"
const BOSSES := "res://assets/bosses/"
const WORM_SHOT := {
	fly = [MOBS + "fire_worm/Sprites/Fire Ball/Move.png", 46, 46, 6, 12, true],
	boom = [MOBS + "fire_worm/Sprites/Fire Ball/Explosion.png", 46, 46, 7, 16, false],
}
const DEMON_SHOT := {
	fly = [MOBS + "flying_demon/Sprites/projectile.png", 48, 32, 1, 1, true],
	boom = [MOBS + "fire_worm/Sprites/Fire Ball/Explosion.png", 46, 46, 7, 16, false],
}
const BRINGER := BOSSES + "bringer_of_death/SpriteSheet/Bringer-of-Death-SpritSheet.png"
const BRINGER_SPELL := {spell = [BRINGER, 140, 93, 16, 12, false, 48]}
const SLIME_BOSS := BOSSES + "demon_slime/spritesheets/demon_slime_FREE_v1.0_288x160_spritesheet.png"
const RAT := MOBS + "monsters_fantasy_2/Rat/"
const SLIME := MOBS + "monsters_fantasy_2/Slime/"
const BAT := MOBS + "monsters_fantasy_2/Bat/"
const MIMIC := MOBS + "monsters_fantasy_2/Mimic/"
const WORM := MOBS + "fire_worm/Sprites/Worm/"
const DEMON := MOBS + "flying_demon/Sprites/with_outline/"
const WIZARD := BOSSES + "evil_wizard/Sprites/"
const MCF := MOBS + "monsters_fantasy_1/"
const BOMB := {
	fly = [MCF + "Goblin/Bomb_sprite.png", 100, 100, 3, 10, true],
	boom = [MCF + "Goblin/Bomb_sprite.png", 100, 100, 10, 14, false, 9],
}
const SPORE := {
	fly = [MCF + "Mushroom/Projectile_sprite.png", 50, 50, 4, 10, true],
	boom = [MCF + "Mushroom/Projectile_sprite.png", 50, 50, 4, 12, false, 4],
}
const EYE_SHOT := {
	fly = [MCF + "Flying eye/projectile_sprite.png", 48, 48, 3, 10, true],
	boom = [MCF + "Flying eye/projectile_sprite.png", 48, 48, 5, 12, false, 3],
}
const SWORD := {
	fly = [MCF + "Skeleton/Sword_sprite.png", 92, 102, 3, 14, true],
	boom = [MCF + "Skeleton/Sword_sprite.png", 92, 102, 5, 12, false, 3],
}

## anims: idle / move / attack / hurt / death (see Assets.frames for the array format).
## anchor: point of the frame placed on the body origin (feet for walkers, centre for flyers).
## size: hit box in world pixels. reach: melee range, or the range a shooter fires from.
## hit_frame: attack frame that deals the damage or launches the shot.
const KINDS := {
	rat = {
		anims = {
			idle = [RAT + "idle.png", 70, 70, 10, 10, true],
			move = [RAT + "run.png", 70, 70, 8, 12, true],
			attack = [RAT + "attack_bite.png", 70, 70, 12, 16, false],
			hurt = [RAT + "hurt.png", 70, 70, 3, 10, false],
			death = [RAT + "rat-death.png", 70, 70, 6, 10, false],
		},
		anchor = Vector2(35, 44), size = Vector2(30, 18),
		hp = 30, damage = 8, speed = 70.0, reach = 28.0, hit_frame = 6,
	},
	slime = {
		anims = {
			idle = [SLIME + "idle.png", 156, 156, 14, 10, true],
			move = [SLIME + "walk.png", 156, 156, 6, 8, true],
			attack = [SLIME + "attack.png", 156, 156, 19, 18, false],
			hurt = [SLIME + "hurt.png", 156, 156, 3, 10, false],
			death = [SLIME + "death.png", 156, 156, 11, 12, false],
		},
		anchor = Vector2(78, 86), size = Vector2(38, 18),
		hp = 45, damage = 10, speed = 38.0, reach = 50.0, hit_frame = 10,
	},
	bat = {
		anims = {
			idle = [BAT + "fly.png", 87, 87, 11, 14, true],
			move = [BAT + "fly.png", 87, 87, 11, 14, true],
			attack = [BAT + "attack.png", 87, 87, 11, 16, false],
			hurt = [BAT + "hurt.png", 87, 87, 3, 10, false],
			death = [BAT + "death.png", 87, 87, 4, 8, false],
		},
		anchor = Vector2(47, 43), size = Vector2(24, 18), scale = 0.8, fly = true,
		hp = 20, damage = 7, speed = 70.0, reach = 24.0, hit_frame = 5,
	},
	mimic = {
		anims = {
			idle = [MIMIC + "Idle_closed.png", 146, 146, 1, 1, true],
			move = [MIMIC + "walk.png", 146, 146, 6, 10, true],
			attack = [MIMIC + "attack_1.png", 146, 146, 14, 16, false],
			hurt = [MIMIC + "hurt.png", 146, 146, 3, 10, false],
			death = [MIMIC + "death.png", 146, 146, 6, 10, false],
		},
		anchor = Vector2(78, 82), size = Vector2(36, 30),
		hp = 70, damage = 14, speed = 50.0, reach = 42.0, hit_frame = 8,
	},
	worm = {
		anims = {
			idle = [WORM + "Idle.png", 90, 90, 9, 10, true],
			move = [WORM + "Walk.png", 90, 90, 9, 10, true],
			attack = [WORM + "Attack.png", 90, 90, 16, 16, false],
			hurt = [WORM + "Get Hit.png", 90, 90, 3, 10, false],
			death = [WORM + "Death.png", 90, 90, 8, 10, false],
		},
		anchor = Vector2(42, 57), size = Vector2(34, 28), shot = WORM_SHOT,
		hp = 40, damage = 10, speed = 32.0, reach = 170.0, hit_frame = 10,
	},
	demon = {
		anims = {
			idle = [DEMON + "IDLE.png", 81, 71, 4, 8, true],
			move = [DEMON + "FLYING.png", 81, 71, 4, 10, true],
			attack = [DEMON + "ATTACK.png", 81, 71, 8, 12, false],
			hurt = [DEMON + "HURT.png", 81, 71, 4, 10, false],
			death = [DEMON + "DEATH.png", 81, 71, 7, 10, false],
		},
		anchor = Vector2(40, 36), size = Vector2(30, 30), scale = 0.8, fly = true, faces_left = true, shot = DEMON_SHOT,
		hp = 35, damage = 10, speed = 55.0, reach = 150.0, hit_frame = 5,
	},
	skeleton = {
		anims = {
			idle = [MCF + "Skeleton/Idle.png", 150, 150, 4, 8, true],
			move = [MCF + "Skeleton/Walk.png", 150, 150, 4, 8, true],
			attack = [MCF + "Skeleton/Attack.png", 150, 150, 8, 12, false],
			hurt = [MCF + "Skeleton/Take Hit.png", 150, 150, 4, 10, false],
			death = [MCF + "Skeleton/Death.png", 150, 150, 4, 8, false],
			throw = [MCF + "Skeleton/Attack3.png", 150, 150, 6, 10, false],
		},
		throw = {frame = 3, shot = SWORD, speed = 210.0, range = 220.0, cooldown = 2.8},
		anchor = Vector2(82, 100), size = Vector2(20, 40), scale = 0.85,
		hp = 60, damage = 12, speed = 45.0, reach = 50.0, hit_frame = 6,
	},
	goblin = {
		anims = {
			idle = [MCF + "Goblin/Idle.png", 150, 150, 4, 8, true],
			move = [MCF + "Goblin/Run.png", 150, 150, 8, 14, true],
			attack = [MCF + "Goblin/Attack.png", 150, 150, 8, 14, false],
			hurt = [MCF + "Goblin/Take Hit.png", 150, 150, 4, 10, false],
			death = [MCF + "Goblin/Death.png", 150, 150, 4, 8, false],
			throw = [MCF + "Goblin/Attack3.png", 150, 150, 12, 16, false],
		},
		throw = {frame = 10, shot = BOMB, lob = true, range = 200.0, cooldown = 3.0},
		anchor = Vector2(74, 100), size = Vector2(22, 32),
		hp = 35, damage = 9, speed = 85.0, reach = 40.0, hit_frame = 6,
	},
	mushroom = {
		anims = {
			idle = [MCF + "Mushroom/Idle.png", 150, 150, 4, 8, true],
			move = [MCF + "Mushroom/Run.png", 150, 150, 8, 10, true],
			attack = [MCF + "Mushroom/Attack.png", 150, 150, 8, 12, false],
			hurt = [MCF + "Mushroom/Take Hit.png", 150, 150, 4, 10, false],
			death = [MCF + "Mushroom/Death.png", 150, 150, 4, 8, false],
			throw = [MCF + "Mushroom/Attack3.png", 150, 150, 11, 14, false],
		},
		throw = {frame = 7, shot = SPORE, speed = 140.0, range = 150.0, cooldown = 2.4},
		anchor = Vector2(75, 100), size = Vector2(20, 34),
		hp = 50, damage = 11, speed = 40.0, reach = 34.0, hit_frame = 7,
	},
	eye = {
		anims = {
			idle = [MCF + "Flying eye/Flight.png", 150, 150, 8, 12, true],
			move = [MCF + "Flying eye/Flight.png", 150, 150, 8, 12, true],
			attack = [MCF + "Flying eye/Attack.png", 150, 150, 8, 14, false],
			hurt = [MCF + "Flying eye/Take Hit.png", 150, 150, 4, 10, false],
			death = [MCF + "Flying eye/Death.png", 150, 150, 4, 8, false],
			throw = [MCF + "Flying eye/Attack3.png", 150, 150, 6, 10, false],
		},
		throw = {frame = 4, shot = EYE_SHOT, speed = 170.0, range = 160.0, cooldown = 2.2},
		anchor = Vector2(76, 76), size = Vector2(26, 24), fly = true,
		hp = 25, damage = 9, speed = 75.0, reach = 26.0, hit_frame = 6,
	},
	wizard = {
		anims = {
			idle = [WIZARD + "Idle.png", 150, 150, 8, 10, true],
			move = [WIZARD + "Move.png", 150, 150, 8, 10, true],
			attack = [WIZARD + "Attack.png", 150, 150, 8, 12, false],
			hurt = [WIZARD + "Take Hit.png", 150, 150, 4, 10, false],
			death = [WIZARD + "Death.png", 150, 150, 5, 8, false],
		},
		anchor = Vector2(71, 101), size = Vector2(30, 72), scale = 1.3, boss = "EVIL WIZARD",
		hp = 450, damage = 16, speed = 55.0, reach = 75.0, hit_frame = 4, cooldown = 0.9,
	},
	bringer = {
		anims = {
			idle = [BRINGER, 140, 93, 8, 10, true, 0],
			move = [BRINGER, 140, 93, 8, 10, true, 8],
			attack = [BRINGER, 140, 93, 10, 12, false, 16],
			hurt = [BRINGER, 140, 93, 3, 10, false, 26],
			death = [BRINGER, 140, 93, 10, 10, false, 29],
			cast = [BRINGER, 140, 93, 9, 12, false, 39],
		},
		anchor = Vector2(105, 91), size = Vector2(34, 72), scale = 1.35, faces_left = true, spell = true,
		boss = "BRINGER OF DEATH",
		hp = 650, damage = 22, speed = 55.0, reach = 70.0, hit_frame = 4, cooldown = 1.1,
	},
	demon_slime = {
		anims = {
			idle = [SLIME_BOSS, 288, 160, 6, 8, true, 0],
			move = [SLIME_BOSS, 288, 160, 12, 10, true, 22],
			attack = [SLIME_BOSS, 288, 160, 15, 12, false, 44],
			hurt = [SLIME_BOSS, 288, 160, 5, 10, false, 66],
			death = [SLIME_BOSS, 288, 160, 22, 12, false, 88],
		},
		anchor = Vector2(145, 158), size = Vector2(50, 96), faces_left = true, boss = "DEMON SLIME",
		hp = 900, damage = 28, speed = 45.0, reach = 95.0, hit_frame = 10, cooldown = 1.0,
	},
}
## Mob health and damage multipliers per level (bosses are tuned directly above).
const LEVEL_HP := [1.0, 1.6, 2.3]
const LEVEL_DAMAGE := [1.0, 1.5, 2.0]

var kind: Dictionary
var level := 0
var hp := 1
var max_hp := 1
var damage := 1
var active := false  # mobs wake up when the player gets close; bosses are woken by main.gd
var dead := false
var facing := -1
var sprite := AnimatedSprite2D.new()
var _busy := false  # attacking, casting or hurt
var _cooldown := 0.0
var _spell_cd := 3.0
var _throw_cd := 1.0


static func create(kind_name: String, pos: Vector2, lvl: int) -> Enemy:
	var e := Enemy.new()
	e.kind = KINDS[kind_name]
	e.level = lvl
	e.position = pos
	return e


func _ready() -> void:
	var boss := kind.has("boss")
	hp = roundi(kind.hp * (1.0 if boss else LEVEL_HP[level]))
	max_hp = hp
	damage = roundi(kind.damage * (1.0 if boss else LEVEL_DAMAGE[level]))
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0 if _flies() else 1
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = kind.size
	shape.position = hurt_rect().get_center() - global_position
	add_child(shape)
	sprite.sprite_frames = Assets.frames(kind.anims)
	sprite.offset = Vector2(kind.anims.idle[1], kind.anims.idle[2]) / 2.0 - kind.anchor
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)
	_face()
	sprite.play("idle")


func _flies() -> bool:
	return kind.get("fly", false)


func _face() -> void:
	var flip := -1 if kind.get("faces_left", false) else 1
	sprite.scale = Vector2(facing * flip, 1) * kind.get("scale", 1.0)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	_spell_cd -= delta
	_throw_cd -= delta
	if not _flies() or dead:
		velocity.y += 950.0 * delta
	if dead or _busy:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if _flies() and not dead:
			velocity.y = 0.0
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Player
	var to := Vector2.ZERO
	if player and not player.dead:
		to = player.global_position + Vector2(0, -18 if _flies() else 0) - global_position
	if not active and player and not kind.has("boss") and absf(to.x) < 260.0:
		active = true
	if not active or to == Vector2.ZERO:
		velocity.x = 0.0
		if _flies():
			velocity.y = 0.0
		move_and_slide()
		sprite.play("idle")
		return

	facing = 1 if to.x > 0.0 else -1
	_face()
	var level_with := absf(to.y) < (24.0 if _flies() else 50.0)
	var in_reach: bool = absf(to.x) < kind.reach and level_with
	if in_reach and _cooldown <= 0.0:
		_busy = true
		_cooldown = kind.get("cooldown", 1.3)
		sprite.play("attack")
		return
	if kind.has("throw") and not in_reach and level_with and _throw_cd <= 0.0 and absf(to.x) < kind.throw.range:
		_busy = true
		_throw_cd = kind.throw.cooldown
		sprite.play("throw")
		return
	if kind.has("spell") and _spell_cd <= 0.0 and absf(to.x) > 110.0:
		_busy = true
		_spell_cd = 4.5
		sprite.play("cast")
		return

	# Close in, but stop short so shooters keep their distance and melee mobs wait out the cooldown.
	var stop_x: float = kind.reach * (0.7 if kind.has("shot") else 0.6)
	var vx: float = 0.0 if absf(to.x) < stop_x else signf(to.x) * kind.speed
	if _flies():
		velocity = Vector2(vx, clampf(to.y * 3.0, -kind.speed, kind.speed))
	else:
		velocity.x = vx
	move_and_slide()
	sprite.play("move" if vx != 0.0 or _flies() else "idle")


func _on_frame_changed() -> void:
	if dead:
		return
	if sprite.animation == "throw" and sprite.frame == kind.throw.frame:
		_throw(kind.throw)
		return
	if sprite.animation != "attack" or sprite.frame != kind.hit_frame:
		return
	if kind.has("shot"):
		var at := global_position + Vector2(facing * 16, 0 if _flies() else -20)
		Projectile.spawn(get_parent(), at, facing, damage, "player", kind.shot, 170.0)
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var r := hurt_rect()
	var reach := Rect2(r.get_center().x + (0.0 if facing > 0 else -kind.reach), r.position.y, kind.reach, r.size.y)
	if player and reach.intersects(player.hurt_rect()):
		player.take_damage(damage)


func _on_animation_finished() -> void:
	match sprite.animation:
		"death":
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.6)
			t.tween_callback(queue_free)
		"cast":
			_busy = false
			var player := get_tree().get_first_node_in_group("player") as Player
			if player:
				_cast_spell(Vector2(player.global_position.x, global_position.y))
		_:
			_busy = false
			sprite.play("idle")


## Ranged attack of the Monster Creatures mobs: sword, spore and eye shots fly straight; bombs are lobbed.
func _throw(t: Dictionary) -> void:
	var at := global_position + Vector2(facing * 16, 0 if _flies() else -24)
	var shot := Projectile.spawn(get_parent(), at, facing, damage, "player", t.shot, t.get("speed", 170.0))
	if t.get("lob", false):
		var player := get_tree().get_first_node_in_group("player") as Player
		var dist := absf(player.global_position.x - global_position.x) if player else 120.0
		shot.vy = -280.0
		shot.gravity = 700.0
		shot.floor_y = global_position.y
		shot.speed = maxf(dist / 0.88, 60.0)  # 0.88 s = time this arc takes to fall back to the ground


## Bringer of Death: a shadow hand drops on the player's spot after the cast.
func _cast_spell(at: Vector2) -> void:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = Assets.frames(BRINGER_SPELL)
	fx.position = at
	fx.offset = Vector2(0, -46)
	fx.scale = Vector2(1.35, 1.35)
	fx.animation_finished.connect(fx.queue_free)
	var dmg := damage
	fx.frame_changed.connect(func() -> void:
		if fx.frame != 7:
			return
		var p := fx.get_tree().get_first_node_in_group("player") as Player
		if p and Rect2(at + Vector2(-18, -60), Vector2(36, 60)).intersects(p.hurt_rect()):
			p.take_damage(dmg))
	get_parent().add_child(fx)
	fx.play("spell")


func hurt_rect() -> Rect2:
	var s: Vector2 = kind.size
	return Rect2(global_position - Vector2(s.x / 2.0, s.y / 2.0 if _flies() else s.y), s)


func take_damage(amount: int) -> void:
	if dead or (kind.has("boss") and not active):
		return
	active = true
	hp -= amount
	Assets.sound(self, "hit", -8)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(1, 0.4, 0.4), 0.06)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	if hp <= 0:
		dead = true
		_busy = true
		remove_from_group("enemy")
		collision_layer = 0
		collision_mask = 1  # dead flyers drop to the ground
		sprite.play("death")
		Assets.sound(self, "enemy_die", -6)
		killed.emit(self)
	elif not kind.has("boss"):  # bosses don't flinch
		_busy = true
		sprite.play("hurt")
