extends Control

var waiting_for_input: Button = null
var editing_player = ""
var action_name = ""

func _ready():
	for grid in [$VBoxContainer/Player1Grid, $VBoxContainer/Player2Grid]:
		for child in grid.get_children():
			if child is Button:
				child.pressed.connect(_on_control_button_pressed.bind(child))
	$VBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	$VBoxContainer/ResetP1Button.pressed.connect(_on_reset_p1_pressed)
	$VBoxContainer/ResetP2Button.pressed.connect(_on_reset_p2_pressed)
	_load_controls()


func _load_controls():
	_set_grid_values($VBoxContainer/Player1Grid, GameManager.player1_controls)
	_set_grid_values($VBoxContainer/Player2Grid, GameManager.player2_controls)


func _set_grid_values(grid: GridContainer, controls: Dictionary):
	for child in grid.get_children():
		if child is Button:
			var action = child.name.to_lower()
			if controls.has(action):
				child.text = controls[action].capitalize()


func _on_control_button_pressed(button: Button):
	waiting_for_input = button
	editing_player = "p1" if button.get_parent() == $VBoxContainer/Player1Grid else "p2"
	action_name = button.name.to_lower()
	button.text = "Press key..."
	set_process_input(true)


func _input(event):
	if waiting_for_input and event is InputEventKey and event.pressed:
		var new_key = OS.get_keycode_string(event.keycode).to_lower()
		waiting_for_input.text = new_key.capitalize()
		_update_player_controls(editing_player, action_name, new_key)
		waiting_for_input = null
		set_process_input(false)


func _update_player_controls(player: String, action: String, key: String):
	if player == "p1":
		GameManager.player1_controls[action] = key
	else:
		GameManager.player2_controls[action] = key
	print("Updated", player, "control:", action, "=", key)


func _on_save_pressed():
	print("Controls updated for this session (not saved).")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_reset_p1_pressed():
	GameManager.player1_controls = GameManager.default_p1_controls.duplicate()
	_set_grid_values($VBoxContainer/Player1Grid, GameManager.player1_controls)
	print("Player 1 controls reset to default (session only).")


func _on_reset_p2_pressed():
	GameManager.player2_controls = GameManager.default_p2_controls.duplicate()
	_set_grid_values($VBoxContainer/Player2Grid, GameManager.player2_controls)
	print("Player 2 controls reset to default (session only).")
