extends KinematicBody2D

var world

const spawn_pos = Vector2(240, 480)
const spawn_health = 3
const spawn_energy = 5

var health = 3 setget set_health, get_health
var energy = 5 setget set_energy, get_energy

const NORMAL_SPEED = Vector2(0, -1)
const SLOW_SPEED = Vector2(0, -0.5)
var IDLE_SPEED = NORMAL_SPEED

const FRICTION = 1.03

var acc = Vector2()
var vel = Vector2()
var offset = Vector2()
var thrust = false

var current_frame = 0

enum Weapon {BOMB, ROCKET}
var weapon = Weapon.ROCKET
var ammunition = 0
var is_reloading = false
var bomb
var rocketLeft
var rocketRight
var bombScene = preload("res://Bomb/Bomb.tscn")
var rocketScene = preload("res://Rocket/Rocket.tscn")
const reloaderWaitTime = 0.7

func _ready():
	world = get_node("/root/World")
	reset()
	
func reset():
	visible = true
	$player.visible = true
	$hit.visible = false
	$explosion.visible = false
	vel = Vector2(0, 0)
	offset = Vector2(0, 0)
	thrust = false
	position = spawn_pos
	current_frame = 0
	health = spawn_health
	energy = spawn_energy
	$Timer.start()
	reset_weapons()
	$Reloader.wait_time = reloaderWaitTime
	$Reloader.start()

func reset_weapons():
	if rocketLeft and is_a_parent_of(rocketLeft):
		remove_child(rocketLeft)
		rocketLeft = null
	if rocketRight and is_a_parent_of(rocketRight):
		remove_child(rocketRight)
		rocketRight = null
	if bomb and is_a_parent_of(bomb):
		remove_child(bomb)
		bomb = null
	ammunition = 0

func _physics_process(delta):
	acc = Vector2(0, 0)
	
	if thrust and is_game_on():
		$thrust.visible = true
		var direction = get_local_mouse_position().normalized()
		var length = get_local_mouse_position().length()
		acc = direction * length / 30
		if not $ThrustPlayer.playing:
			$ThrustPlayer.play()
	else:
		$thrust.visible = false
		$ThrustPlayer.stop()

	vel.x /= FRICTION
	vel.y /= FRICTION

	vel += 4 *  acc * delta
	vel = vel.clamped(3)

	if position.x < 35 and vel.x < 0:
		vel.x = 0
	if position.x > 445 and vel.x > 0:
		vel.x = 0
	
	if offset.y > 100 and vel.y > 0:
		vel.y = 0
		IDLE_SPEED = SLOW_SPEED
	else:
		IDLE_SPEED = NORMAL_SPEED
	
	if is_game_on():
		move_and_collide(IDLE_SPEED + vel)
		offset += vel
		
	var camera_pos = position - offset + Vector2(0,-180)
	
	get_node("/root/World/Camera").position = camera_pos
	if floor((-camera_pos.y + 320) / 640.0) > current_frame:
		current_frame = floor((-camera_pos.y + 320) / 640.0) 
		world.rotate_bgs(current_frame)
	get_node("/root/World/SideWalls").position.y = (position - offset + Vector2(0,-180)).y
	get_node("/root/World/GarbageCollector").position.y = (position - offset + Vector2(240, 240)).y

var target = Vector2(0, 0)
func _draw():
	draw_line(Vector2(0,  0), target, Color.red)

func _input(event):

	if not is_game_on():
		return
	
	if event.is_action_pressed("switch_weapon"):
		if weapon == Weapon.BOMB:
			weapon = Weapon.ROCKET
			if bomb:
				remove_child(bomb)
				bomb = null
		else:
			weapon = Weapon.BOMB
			if rocketLeft:
				remove_child(rocketLeft)
				rocketLeft = null
			if rocketRight:
				remove_child(rocketRight)
				rocketRight = null
		ammunition = 0
		$Reloader.wait_time = 0.1
		$Reloader.start()

	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:

			if (weapon == Weapon.ROCKET):
				if not ammunition > 0:
					return;
				
				var rocket = null
				var target_is_left = get_global_mouse_position() < global_position
				var target_is_right = not target_is_left
				
				if target_is_left and rocketLeft:
					rocket = rocketLeft
					rocketLeft = null
				elif target_is_right and rocketRight:
					rocket = rocketRight
					rocketRight = null
				elif rocketLeft:
						rocket = rocketLeft
						rocketLeft = null
				elif rocketRight:
					rocket = rocketRight
					rocketRight = null

				if not rocket:
					return
				
				var rocketPosition  = rocket.global_position
				remove_child(rocket)
				world.add_child(rocket)
				rocket.init_global_position(rocketPosition)
				rocket.set_target(get_global_mouse_position())
				ammunition -= 1
				$Reloader.start()
				
			elif (weapon == Weapon.BOMB):
				# shoot! only if no bombs already
				if not ammunition > 0:
					return;

				var bombPosition = bomb.global_position
				remove_child(bomb)
				world.add_child(bomb)
				bomb.set_target(get_global_mouse_position())
				bomb.position = bombPosition
				ammunition = 0
				$Reloader.start()
				
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			thrust = event.pressed

func _on_GarbageCollector_body_entered(body):
	if not body.is_in_group("player") and not body.is_in_group("walls"):
		body.queue_free()

func increase_health():
	health += 1
	
func _on_Area2D_body_entered(body):
	if world.state != world.State.PLAYING:
		return
		
	if body.is_in_group("enemy"):
		set_health(health - 1)
		$hit.position = 20 * (body.global_position - global_position).normalized()
		$animation.play("hit")
		$HitPlayer.play()
		body.queue_free()

	if body.is_in_group("energy"):
		body.captured()
		$EnergyPlayer.play()
		set_energy(energy + 1)

func _on_Timer_timeout():
	set_energy(energy-1)

func is_game_on():
	return world.state == world.State.PLAYING

func set_health(value):
	if not is_game_on():
		return
	health = clamp(value, 0, value)
	
func get_health():
	return health
	
func set_energy(value):
	if not is_game_on():
		return
	energy = clamp(value, 0, value)
	
func get_energy():
	return energy

func drain():
	$EnergyLosePlayer.play()

func destroy():
	$DestroyedPlayer.play()
	reset_weapons()
	$player.visible = false
	$animation.play("destruction")
	yield($animation, "animation_finished")
	visible = false

func _on_Reloader_timeout():
	
	$Reloader.wait_time = reloaderWaitTime
	
	if weapon == Weapon.BOMB and ammunition == 0:
		ammunition = 1
		bomb = bombScene.instance()
		bomb.position = Vector2(0, 16)
		add_child(bomb)
	
	if weapon == Weapon.ROCKET and ammunition < 2:

		var rocket
		var rocketPosition
		var rocketLeftPosition = Vector2(-20, 0)
		var rocketRightPosition = Vector2(20, 0)

		rocket = rocketScene.instance()
		rocket.mode = RigidBody2D.MODE_KINEMATIC
		
		var chooseLeftRocket
		if not rocketLeft and not rocketRight:
			chooseLeftRocket = randi()%2 == 0
		elif not rocketLeft:
			chooseLeftRocket = true
		elif not rocketRight:
			chooseLeftRocket = false
		
		if chooseLeftRocket:
			rocketLeft = rocket
			rocketLeft.position = rocketLeftPosition
		else:
			rocketRight = rocket
			rocketRight.position = rocketRightPosition
			
		add_child(rocket)
		
		ammunition += 1
		
		if ammunition < 2:
			$Reloader.start()
