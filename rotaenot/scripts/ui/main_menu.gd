extends Control

func _ready():
	# Redirect to clean main menu using deferred call to avoid node busy error
	call_deferred("_change_to_new_menu")

func _change_to_new_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu/diamond_menu.tscn")

func _on_play_button_pressed():
	print("Opening song selection...")
	get_tree().change_scene_to_file("res://scenes/ui/song_select.tscn")

func _on_settings_button_pressed():
	print("Opening settings menu...")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
