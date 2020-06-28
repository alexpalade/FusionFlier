extends RigidBody2D

var target
var drawPoints = []

func _ready():
	pass

func set_target(target):
	self.target = target
	apply_central_impulse(Vector2(0, -50))
	$Trigger.start()
	$SelfDestruct.start()
	update()

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
	set_deferred("mode", RigidBody2D.MODE_CHARACTER)
	linear_velocity = Vector2(0, 0)
	$"rocket-1".visible = false
	$explosion.visible = true
	$animation.play("explode")
	yield($animation, "animation_finished")
	queue_free()
	
func _on_Trigger_timeout():
	if target:
		var direction = Vector2(target - position).normalized()
		var speed = 750
		linear_velocity = direction * speed
		rotation = get_angle_to(target) + deg2rad(90)
		$ThrustPlayer.play()
		
func _on_SelfDestruct_timeout():
	explode()
