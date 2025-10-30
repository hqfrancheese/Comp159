# UI.gd
extends CanvasLayer

@onready var p1_health_bar = $MarginContainer/VBoxContainer/Player1Health/HealthBar
@onready var p2_health_bar = $MarginContainer/VBoxContainer/Player2Health/HealthBar
@onready var result_label = $ResultLabel
@onready var restart_button = $RestartButton

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.visible = false
	result_label.visible = false
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	# Update health bars
	p1_health_bar.value = GameManager.player1_health
	p2_health_bar.value = GameManager.player2_health
	
	# Check for game over
	if GameManager.player1_health <= 0:
		_show_result("Player 2 Wins!")
	elif GameManager.player2_health <= 0:
		_show_result("Player 1 Wins!")

func _show_result(text: String):
	result_label.text = text
	result_label.visible = true
	restart_button.visible = true
	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	GameManager.reset_health()
	get_tree().reload_current_scene()
