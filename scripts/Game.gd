# Game.gd
extends Node2D

@onready var player1 = $Player1
@onready var player2 = $Player2

func _ready():
	
	# Set up Player 2 as CPU if needed
	if GameManager.game_mode == GameManager.GameMode.PVCPU:
		player2.is_cpu = true
	
	# Link opponents
	player1.set_opponent(player2)
	player2.set_opponent(player1)
