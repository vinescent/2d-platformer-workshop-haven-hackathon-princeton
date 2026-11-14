class_name Player extends CharacterBody2D
## The knight. A/D move, Space/W jump, S drops through platforms, Shift dash,
## left click swings the sword, right click throws a fireball the way he faces.

signal hp_changed(hp: int)
signal died

const MAX_HP := 100
const SPEED := 120.0
const JUMP_VELOCITY := -330.0
const GRAVITY := 950.0
const DASH_SPEED := 330.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.6
const FIRE_COOLDOWN := 0.55
const SWORD_REACH := 46.0
const SHEET := "res://assets/player/free_knight/%s/NoOutline/120x80_PNGSheets/_%s.png"
## Gear per tier (tier goes up after each boss): sword and fireball damage,
## share of enemy damage taken, sprite colour set and tint.
const TIERS := [
	{sword = 20, fire = 12, armor = 1.0, colour = "Colour1", tint = Color.WHITE},
	{sword = 34, fire = 20, armor = 0.75, colour = "Colour2", tint = Color.WHITE},
	{sword = 52, fire = 30, armor = 0.55, colour = "Colour2", tint = Color(1.0, 0.82, 0.4)},
]
const FIREBALL_SHEET := "res://assets/effects/fire_effect/Firebolt SpriteSheet.png"
const FIREBALL := {
	fly = [FIREBALL_SHEET, 48, 48, 4, 12, true],
	boom = [FIREBALL_SHEET, 48, 48, 6, 18, false, 4],
}

var hp := MAX_HP
var tier := 0
var facing := 1
var dead := false
var sprite := AnimatedSprite2D.new()
var _dash_left := 0.0
var _dash_cd := 0.0
var _fire_cd := 0.0
var _invuln := 0.0
var _attacking := false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 8  # ground/walls (layer 1) + one-way platforms (layer 4)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(14, 34)
	shape.position = Vector2(0, -17)
	add_child(shape)
	sprite.offset = Vector2(6, -40)  # puts the knight's feet (bottom of the 120x80 frame) on our origin
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)
	set_tier(0)


func set_tier(t: int) -> void:
	tier = t
	var c: String = TIERS[t].colour
	sprite.sprite_frames = Assets.frames({
		idle = [SHEET % [c, "Idle"], 120, 80, 10, 10, true],
		run = [SHEET % [c, "Run"], 120, 80, 10, 14, true],
		jump = [SHEET % [c, "Jump"], 120, 80, 3, 10, false],
		fall = [SHEET % [c, "Fall"], 120, 80, 3, 10, true],
		dash = [SHEET % [c, "Dash"], 120, 80, 2, 12, true],
		attack = [SHEET % [c, "AttackNoMovement"], 120, 80, 4, 14, false],
		hurt = [SHEET % [c, "Hit"], 120, 80, 1, 8, false],
		death = [SHEET % [c, "DeathNoMovement"], 120, 80, 10, 10, false],
	})
	sprite.self_modulate = TIERS[t].tint
	sprite.play("death" if dead else "idle")


func _physics_process(delta: float) -> void:
	_dash_cd -= delta
	_fire_cd -= delta
	_invuln -= delta
	if dead:
		velocity.x = 0.0
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0 and not _attacking:
		facing = 1 if dir > 0.0 else -1

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = Vector2(facing * DASH_SPEED, 0.0)
	else:
		velocity.y += GRAVITY * delta
		velocity.x = 0.0 if _attacking and is_on_floor() else dir * SPEED
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			Assets.sound(self, "jump", -12)
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5  # tapping jump gives a short hop
		if Input.is_action_just_pressed("drop") and is_on_floor():
			_drop_through()
		if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
			_dash_left = DASH_TIME
			_dash_cd = DASH_COOLDOWN
			_attacking = false
			Assets.sound(self, "dash", -10)
		if Input.is_action_just_pressed("attack") and not _attacking:
			_attacking = true
			sprite.play("attack")
			Assets.sound(self, "swing", -8)
		if Input.is_action_just_pressed("fire") and _fire_cd <= 0.0:
			_fire_cd = FIRE_COOLDOWN
			Projectile.spawn(get_parent(), global_position + Vector2(facing * 18, -18), facing, TIERS[tier].fire, "enemy", FIREBALL, 280.0)
			Assets.sound(self, "fire", -14)

	move_and_slide()
	sprite.scale.x = facing
	_animate()


func _animate() -> void:
	if _attacking or (sprite.animation == "hurt" and sprite.is_playing()):
		return
	var anim := "idle"
	if _dash_left > 0.0:
		anim = "dash"
	elif not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 1.0:
		anim = "run"
	sprite.play(anim)


func _drop_through() -> void:
	# Stop colliding with one-way platforms for a moment; on solid ground this does nothing.
	set_collision_mask_value(4, false)
	await get_tree().create_timer(0.25).timeout
	set_collision_mask_value(4, true)


func _on_frame_changed() -> void:
	if sprite.animation == "attack" and sprite.frame == 2:
		var reach := Rect2(global_position + Vector2(0.0 if facing > 0 else -SWORD_REACH, -36), Vector2(SWORD_REACH, 36))
		for e in get_tree().get_nodes_in_group("enemy"):
			if reach.intersects(e.hurt_rect()):
				e.take_damage(TIERS[tier].sword)


func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		_attacking = false
	elif sprite.animation == "death":
		died.emit()


func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-8, -34), Vector2(16, 34))


func take_damage(amount: int) -> void:
	if dead or _invuln > 0.0 or _dash_left > 0.0:
		return
	hp = maxi(hp - roundi(amount * TIERS[tier].armor), 0)
	hp_changed.emit(hp)
	_invuln = 0.8
	_attacking = false
	Assets.sound(self, "hurt", -6)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.08)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if hp == 0:
		dead = true
		sprite.play("death")
	else:
		sprite.play("hurt")


## Returns how much health was actually restored (capped at MAX_HP).
func heal(amount: int) -> int:
	var before := hp
	hp = mini(hp + amount, MAX_HP)
	hp_changed.emit(hp)
	return hp - before


func respawn(at: Vector2) -> void:
	dead = false
	hp = MAX_HP
	global_position = at
	velocity = Vector2.ZERO
	_invuln = 1.0
	_attacking = false
	_dash_left = 0.0
	sprite.play("idle")
	hp_changed.emit(hp)
