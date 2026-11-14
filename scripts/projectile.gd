class_name Projectile extends Node2D
## A fireball that flies straight, damages the first body of the `target` group it touches, then explodes.
## `anims` needs a looping "fly" and a one-shot "boom" animation.

var dir := 1
var speed := 260.0
var damage := 10
var target := "enemy"
var life := 1.8
var vy := 0.0  # with gravity > 0 the shot arcs (goblin bombs) and blows up when it reaches floor_y
var gravity := 0.0
var floor_y := INF
var sprite := AnimatedSprite2D.new()
var _done := false


static func spawn(parent: Node, pos: Vector2, dir_x: int, dmg: int, target_group: String, anims: Dictionary, spd: float) -> Projectile:
	var p := Projectile.new()
	p.position = pos
	p.dir = dir_x
	p.damage = dmg
	p.target = target_group
	p.speed = spd
	p.sprite.sprite_frames = Assets.frames(anims)
	parent.add_child(p)
	return p


func _ready() -> void:
	sprite.scale.x = dir
	sprite.animation_finished.connect(queue_free)  # only the one-shot explosion ever finishes
	add_child(sprite)
	sprite.play("fly")


func _physics_process(delta: float) -> void:
	if _done:
		return
	position.x += dir * speed * delta
	if gravity > 0.0:
		vy += gravity * delta
		position.y += vy * delta
		if position.y >= floor_y:
			position.y = floor_y
			_explode(Rect2(global_position - Vector2(28, 48), Vector2(56, 48)))
			return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	_explode(Rect2(global_position - Vector2(8, 6), Vector2(16, 12)), true)


## Damages every target touching `area`. A contact check (`only_if_hit`) does nothing when nothing is touched.
func _explode(area: Rect2, only_if_hit := false) -> void:
	var hit := false
	for body in get_tree().get_nodes_in_group(target):
		if area.intersects(body.hurt_rect()):
			body.take_damage(damage)
			hit = true
	if hit or not only_if_hit:
		_done = true
		sprite.play("boom")
