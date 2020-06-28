extends RigidBody2D

var target
var drawPoints = []
var stage = 0
var init_global_pos = null

func _ready():
	pass

func set_target(target):
	self.target = target
	stage = 1
	update()

func init_global_position(value):
	init_global_pos = value

func _process(delta):
	if target:
		update()
		drawPoints.append(position)

func _draw():
	if target:
		for i in range(drawPoints.size()):
			var point = drawPoints[i]
			var color = Color.gray
			color.a = 0.2
			draw_circle((point - position).rotated(-rotation), 3, color)
		draw_circle((target - position).rotated(-rotation), 1.5, Color.red)

func _on_Bullet_body_entered(body):
	if not "player" in body.get_groups() and not "rocket" in body.get_groups():
		explode()

func explode():
	$ExplosionPlayer.play()
	$Collision.set_deferred("disabled", true)
	set_deferred("mode", RigidBody2D.MODE_CHARACTER)
	linear_velocity = Vector2(0, 0)
	$"rocket-1".visible = false
	$explosion.visible = true
	$animation.play("explode")
	yield($animation, "animation_finished")
	queue_free()

func _physics_process(delta):
	if init_global_pos:
		global_position = init_global_pos
		init_global_pos = null
	if stage == 1:
		mode = RigidBody2D.MODE_RIGID
		apply_central_impulse(Vector2(0, -50))
		$Trigger.start()
		$SelfDestruct.start()
		stage = 2
	if stage == 3:
		if target:
			var direction = Vector2(target - position).normalized()
			var speed = 550
			linear_velocity = direction * speed
			rotation = get_angle_to(target) + deg2rad(90)
			$ThrustPlayer.play()
			stage = 4

func _on_Trigger_timeout():
	stage = 3

func _on_SelfDestruct_timeout():
	explode()
