extends RigidBody2D

var color
var world
	
func _ready():
	world = get_node("/root/World")

func set_blue():
	color = "blue"
	$sprite_neutral.visible = false
	$sprite_blue.visible = true

func set_red():
	color = "red"
	$sprite_neutral.visible = false
	$sprite_red.visible = true

func set_gray():
	color = "gray"
	modulate = Color.gray

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Enemy_body_entered(body):
	if "enemy" in body.get_groups():
		if color == "red" and body.color == "blue":
			var energy = preload("res://Energy/Energy.tscn").instance()
			energy.position = (position + body.position)/2
			var velocity = (linear_velocity + body.linear_velocity)
			energy.linear_velocity = velocity
			#world.add_child(energy)
			world.call_deferred("add_child", energy)
			body.queue_free()
			queue_free()
		if color == body.color:
			if position < body.position:
				$HitPlayer.play()
