extends KinematicBody2D

var target
var exploded = false
var launched = false

func _ready():
	pass # Replace with function body.

func set_target(target):
	$SelfDestruct.start()
	self.target = target
	launched = true
	update()

func _process(delta):
	if not launched:
		return

	var direction = (target - position)
	if direction.length() < 10:
		explode()
	else:
		move_and_collide(direction.normalized() * 5)
		update()

func _draw():
	if target:
		draw_circle(target - position, 1.5, Color.red)

func explode():
	if exploded:
		return
	
	$ExplosionPlayer.play()
	exploded = true
	var bodies = $ExplosionRadius.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			var distance = (body.position - position).length()
			distance = clamp(distance, 0.1, distance)
			var direction = body.position - position
			var magnitude = 12000/(distance*distance)
			body.apply_central_impulse(direction*magnitude)
	$bomb.visible = false
	$explosion.visible = true
	$animation.play("explode")
	yield($animation, "animation_finished")

	queue_free()

func _on_CollisionRadius_body_entered(body):
	if "enemy" in body.get_groups():
		explode()

func _on_SelfDestruct_timeout():
	explode()
