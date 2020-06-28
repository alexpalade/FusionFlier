extends CanvasLayer


var world

func _ready():
	world = get_node("/root/World")

func _unhandled_input(event):
	
	if event.is_action_pressed("ui_cancel"):
		if world.state == world.State.PAUSED:
			world.resume()
		elif world.state == world.State.PLAYING:
			$Paused.visible = true
			get_tree().paused = true
			world.state = world.State.PAUSED
			
	if event is InputEventMouseButton:
		if event.pressed:
			if world.state == world.State.PAUSED:
				world.resume()
			elif world.state == world.State.NEW:
				world.restart_game()
			#elif world.state == world.State.GAME_OVER:
			#	world.restart_game()

func _on_Resume_pressed():
	world.resume()
