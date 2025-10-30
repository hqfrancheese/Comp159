extends Node

enum GameMode { PVP, PVCPU }

var game_mode = GameMode.PVP

# Default control bindings
var player1_controls = {
	"left": "a",
	"right": "d",
	"jump": "w",
	"melee": "f",
	"fireball": "g",
	"block": "h"
}

var player2_controls = {
	"left": "left",
	"right": "right",
	"jump": "up",
	"melee": "l",
	"fireball": "k",
	"block": "j"
}

var player1_health = 100
var player2_health = 100

func reset_health():
	player1_health = 100.0
	player2_health = 100.0

# (Optional) Save/load functions
func save_controls():
	var data = {
		"p1": player1_controls,
		"p2": player2_controls
	}
	var file = FileAccess.open("user://controls.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_controls():
	if FileAccess.file_exists("user://controls.json"):
		var file = FileAccess.open("user://controls.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		player1_controls = data["p1"]
		player2_controls = data["p2"]
		file.close()
