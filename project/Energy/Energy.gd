extends RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$FusionPlayer.play()	
	$"fusion-fx".visible = true
	$animation.play("fusion")
	yield($animation, "animation_finished")
	$"fusion-fx".visible = false

func captured():
	$Area2D/Collision2.set_deferred("disabled", true)
	$Collision.set_deferred("disabled", true)
	$animation.play("captured")
	yield($animation, "animation_finished")
	queue_free()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
