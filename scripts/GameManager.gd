extends Node

enum GameMode { PVP, PVCPU }

var game_mode = GameMode.PVP

# Default control bindings
var default_p1_controls = {
	"left": "a",
	"right": "d",
	"jump": "w",
	"melee": "e",
	"fireball": "q",
	"block": "f"
}

var default_p2_controls = {
	"left": "j",
	"right": "l",
	"jump": "i",
	"melee": "u",
	"fireball": "o",
	"block": "h"
}

var player1_controls = {}
var player2_controls = {}

var player1_health = 100
var player2_health = 100


func _ready():
	player1_controls = default_p1_controls.duplicate()
	player2_controls = default_p2_controls.duplicate()

func reset_health():
	player1_health = 100
	player2_health = 100

func reset_controls_to_default():
	player1_controls = default_p1_controls.duplicate()
	player2_controls = default_p2_controls.duplicate()
