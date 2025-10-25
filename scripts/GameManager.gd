# GameManager.gd (Autoload)
extends Node

enum GameMode { PVP, PVCPU }
var game_mode: GameMode = GameMode.PVP

var player1_health: float = 100.0
var player2_health: float = 100.0

func reset_health():
	player1_health = 100.0
	player2_health = 100.0
