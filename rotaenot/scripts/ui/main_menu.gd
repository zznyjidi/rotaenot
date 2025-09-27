extends Control

func _ready():
	$VBoxContainer/PlayButton.grab_focus()

func _on_play_button_pressed():
	print("Opening song selection...")
	get_tree().change_scene_to_file("res://scenes/ui/song_select.tscn")

func _on_settings_button_pressed():
	print("Opening settings menu...")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
