extends Node2D

@onready var player1 = $Player1
@onready var player2 = $Player2

func _ready():
	# Apply current session controls without overwriting them
	_apply_current_controls()

	# Set up Player 2 as CPU if needed
	player2.is_cpu = GameManager.game_mode == GameManager.GameMode.PVCPU

	# Link opponents
	player1.set_opponent(player2)
	player2.set_opponent(player1)

	# Reset player health
	GameManager.reset_health()
	player1.health = 100.0
	player2.health = 100.0

	# Reset positions
	player1.global_position = Vector2(400, 500)
	player2.global_position = Vector2(800, 500)


# This applies the current session controls without touching the defaults
func _apply_current_controls():
	# If the current controls are empty (first session), use defaults
	if GameManager.player1_controls.size() == 0:
		GameManager.player1_controls = GameManager.default_p1_controls.duplicate()
	if GameManager.player2_controls.size() == 0:
		GameManager.player2_controls = GameManager.default_p2_controls.duplicate()

	# Assign controls to players
	player1.controls = GameManager.player1_controls.duplicate()
	player2.controls = GameManager.player2_controls.duplicate()
