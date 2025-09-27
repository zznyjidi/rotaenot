extends Control

func _ready():
	$VBoxContainer/PlayButton.grab_focus()

func _on_play_button_pressed():
	print("Starting game...")
	get_tree().change_scene_to_file("res://scenes/gameplay/gameplay.tscn")

func _on_settings_button_pressed():
	print("Settings not implemented yet")

func _on_quit_button_pressed():
	get_tree().quit()