extends Node2D

const WIDTH = 480
const HEIGHT = 640

enum State {NEW, GAME_OVER, PAUSED, PLAYING}
var state
var player
var score: int = 0

var bg = preload("res://World/Background.tscn")
var bgs = {}

func _ready():
	randomize()

	state = State.NEW
	$HUD/NewGame.visible = true
	$HUD/GameOver.visible = false
	$HUD/Paused.visible = false
	player = preload("res://Player/Player.tscn").instance()
	add_child(player)
	player.visible = false
	init_bg()

func init_bg():
	bgs[0] = bg.instance()
	bgs[1] = bg.instance()
	
	bgs[0].position = Vector2(WIDTH/2, HEIGHT/2)
	bgs[1].position = Vector2(WIDTH/2, HEIGHT/2 - HEIGHT)

	for key in bgs:
		add_child(bgs[key])

func reset_bgs():
	bgs[0].position = Vector2(WIDTH/2, HEIGHT/2)
	bgs[1].position = Vector2(WIDTH/2, HEIGHT/2 - HEIGHT)

func rotate_bgs(current_frame):
	var height = HEIGHT/2 - (1+current_frame)*HEIGHT
	bgs[0].position = Vector2(WIDTH/2, height)
	
	var temp = bgs[1]
	bgs[1] = bgs[0]
	bgs[0] = temp

func restart_game():
	state = State.PLAYING
	player.visible = true
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()
	for energy in get_tree().get_nodes_in_group("energy"):
		energy.queue_free()
	$ScoreTimer.start()
	get_tree().paused = false
	$HUD/Paused.visible = false
	$HUD/GameOver.visible = false
	$HUD/NewGame.visible = false
	score = 0
	$Player.reset()
	reset_bgs()

func format_seconds(s):
	var minutes = floor(s/60)
	var seconds = s-minutes*60
	if minutes > 1:
		return str(minutes) + " minutes and " + str(seconds) + " seconds"
	elif minutes == 1:
		return str(minutes) + " minute and " + str(seconds) + " seconds"
	else:
		return str(seconds) + " seconds"

func game_over():
	state = State.GAME_OVER
	$Player/ThrustPlayer.stop()
	if player.health == 0:
		player.destroy()
	elif player.energy == 0:
		player.drain()
	$ScoreTimer.stop()
	$Player/Timer.stop()
	get_tree().paused = false
	$HUD/GameOver.visible = true
	$HUD/GameOver/ScoreLabel.text = format_seconds(score)

func resume():
	get_tree().paused = false
	$HUD/Paused.visible = false
	state = State.PLAYING

func _process(_delta):

	var health = $Player.health
	var energy = $Player.energy
	
	var health_str = ""
	for i in range(health):
		health_str += "❤"
	$HUD/GameHUD/VBoxContainer/Health.text = health_str
	
	var energy_str = ""
	for i in range(energy):
		energy_str += "⚡"
	$HUD/GameHUD/VBoxContainer/Energy.text = energy_str
	if energy < 2 and state == State.PLAYING:
		$HUD/GameHUD/VBoxContainer/animation.play("alarm")
	else:
		$HUD/GameHUD/VBoxContainer/animation.play("default")
	$HUD/GameHUD/Score.text = str(score)
	
	if not state == State.GAME_OVER:
		if health <= 0 || energy <= 0:
			game_over()

func _on_ScoreTimer_timeout():
	score += 1

func _on_RestartButton_pressed():
	restart_game()

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_StartButton_pressed():
	restart_game()

func _on_GarbageCollector_body_entered(body):
	if not body.is_in_group("player") and not body.is_in_group("walls"):
		body.queue_free()
