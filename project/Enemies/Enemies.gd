extends Node

var world
var enemies = 0
var last_tick = OS.get_ticks_msec()
var tick_rate = 2000
var last_color: int = 0

func _ready():
	world = get_node("/root/World")

func spawn_enemy():
	var enemyScene = preload("res://Enemy/Enemy.tscn")
	var enemy: RigidBody2D  = enemyScene.instance()
	world.add_child(enemy)
	
	var scene_pos = get_node("/root/World/Camera").position
	enemy.position = Vector2(randi()%480, scene_pos.y - 400)
	
	if last_color == 1:
		enemy.set_red()
		last_color = 0
	else:
		enemy.set_blue()
		last_color = 1

	var max_velocity = 100
	var vel = Vector2(randi()%max_velocity-max_velocity/2, randi()%max_velocity-max_velocity/2)
	enemy.linear_velocity = vel
	
	enemy.angular_velocity = randi()%2-1

func tick():
	enemies = len(get_tree().get_nodes_in_group("enemy"))
	if enemies < 20:
		spawn_enemy()

func _process(delta):
	if OS.get_ticks_msec() - last_tick > tick_rate:
		last_tick = OS.get_ticks_msec()
		tick()
