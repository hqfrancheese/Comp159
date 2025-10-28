extends Control

var waiting_for_input: Button = null
var editing_player = ""
var action_name = ""

func _ready():
	# Connect all buttons
	for grid in [$VBoxContainer/Player1Grid, $VBoxContainer/Player2Grid]:
		for child in grid.get_children():
			if child is Button:
				child.pressed.connect(_on_control_button_pressed.bind(child))
	
	$VBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	
	_load_controls()

func _load_controls():
	var p1 = GameManager.player1_controls
	var p2 = GameManager.player2_controls
	
	_set_grid_values($VBoxContainer/Player1Grid, p1)
	_set_grid_values($VBoxContainer/Player2Grid, p2)

func _set_grid_values(grid, controls):
	var i = 0
	for key in controls.keys():
		var button = grid.get_child(i * 2 + 1)
		button.text = controls[key]
		button.name = key
		i += 1

func _on_control_button_pressed(button: Button):
	waiting_for_input = button
	editing_player = "p1" if button.get_parent() == $VBoxContainer/Player1Grid else "p2"
	action_name = button.name
	button.text = "Press key..."
	set_process_input(true)

func _input(event):
	if waiting_for_input and event is InputEventKey and event.pressed:
		var new_key = OS.get_keycode_string(event.keycode)
		waiting_for_input.text = new_key
		_update_player_controls(editing_player, action_name, new_key)
		waiting_for_input = null
		set_process_input(false)

func _update_player_controls(player, action, key):
	if player == "p1":
		GameManager.player1_controls[action] = key.to_lower()
	else:
		GameManager.player2_controls[action] = key.to_lower()

func _on_save_pressed():
	GameManager.save_controls() # optional
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
