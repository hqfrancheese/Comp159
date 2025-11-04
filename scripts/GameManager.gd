extends Node

enum GameMode { PVP, PVCPU }

var game_mode = GameMode.PVP

# Default control bindings
var default_p1_controls = {
	"left": "a",
	"right": "d",
	"jump": "w",
	"melee": "f",
	"fireball": "g",
	"block": "h"
}

var default_p2_controls = {
	"left": "left",
	"right": "right",
	"jump": "up",
	"melee": "l",
	"fireball": "k",
	"block": "j"
}

var player1_controls = {}
var player2_controls = {}

var player1_health = 100
var player2_health = 100

const SAVE_PATH = "user://controls.json"

func _ready():
	load_controls()

func reset_health():
	player1_health = 100
	player2_health = 100

func save_controls():
	var data = {"p1": player1_controls, "p2": player2_controls}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Controls saved:", data)
	else:
		push_error("Failed to open file for saving.")

func load_controls():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var result = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(result) == TYPE_DICTIONARY:
			player1_controls = result.get("p1", default_p1_controls)
			player2_controls = result.get("p2", default_p2_controls)
			print("Controls loaded:", result)
			return
	print("No valid save found. Using defaults.")
	player1_controls = default_p1_controls.duplicate()
	player2_controls = default_p2_controls.duplicate()

func reset_controls_to_default():
	player1_controls = default_p1_controls.duplicate()
	player2_controls = default_p2_controls.duplicate()
	save_controls()
