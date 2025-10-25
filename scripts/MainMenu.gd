# MainMenu.gd
extends Control

func _ready():
	$VBoxContainer/PvPButton.pressed.connect(_on_pvp_pressed)
	$VBoxContainer/PvCPUButton.pressed.connect(_on_pvcpu_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_pvp_pressed():
	GameManager.game_mode = GameManager.GameMode.PVP
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_pvcpu_pressed():
	GameManager.game_mode = GameManager.GameMode.PVCPU
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _process(_delta):
	pass
