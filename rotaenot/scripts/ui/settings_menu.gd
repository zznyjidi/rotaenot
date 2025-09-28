extends Control

# Settings menu for configuring keymaps and other options

@onready var key_button_container = $Panel/ScrollContainer/VBoxContainer/KeymapSection/GridContainer
@onready var volume_master = $Panel/ScrollContainer/VBoxContainer/AudioSection/MasterVolume
@onready var volume_music = $Panel/ScrollContainer/VBoxContainer/AudioSection/MusicVolume
@onready var volume_sfx = $Panel/ScrollContainer/VBoxContainer/AudioSection/SFXVolume
@onready var fps_toggle = $Panel/ScrollContainer/VBoxContainer/DisplaySection/FPSContainer/FPSToggle

var key_buttons = []
var waiting_for_key = -1  # Which pad index we're waiting for key input

func _ready():
	# Start with fade in
	modulate.a = 0.0
	var fade_in = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.3)

	# Create key mapping buttons
	_create_keymap_buttons()

	# Load current settings
	_load_settings()

func _create_keymap_buttons():
	var pad_names = ["Left Top", "Left Mid", "Left Bottom", "Right Top", "Right Mid", "Right Bottom"]

	for i in range(6):
		# Create label
		var label = Label.new()
		label.text = pad_names[i] + ":"
		label.add_theme_font_size_override("font_size", 18)
		key_button_container.add_child(label)

		# Create button
		var button = Button.new()
		button.custom_minimum_size = Vector2(100, 40)
		button.add_theme_font_size_override("font_size", 20)
		button.set_meta("pad_index", i)
		button.pressed.connect(_on_key_button_pressed.bind(i))
		key_button_container.add_child(button)
		key_buttons.append(button)

func _load_settings():
	# Load keymap
	for i in range(6):
		var key = SettingsManager.get_key_for_pad(i)
		key_buttons[i].text = key

	# Load audio settings
	if volume_master:
		volume_master.value = SettingsManager.master_volume * 100
	if volume_music:
		volume_music.value = SettingsManager.music_volume * 100
	if volume_sfx:
		volume_sfx.value = SettingsManager.sfx_volume * 100

	# Load display settings
	if fps_toggle:
		fps_toggle.button_pressed = SettingsManager.show_fps

func _on_key_button_pressed(pad_index: int):
	UISoundManager.play_selection_sound()
	waiting_for_key = pad_index
	key_buttons[pad_index].text = "Press key..."

func _input(event):
	if waiting_for_key >= 0 and event is InputEventKey and event.pressed:
		var key_string = OS.get_keycode_string(event.keycode)

		# Don't allow escape or enter
		if key_string in ["Escape", "Enter"]:
			return

		# Check if this key is already used
		for i in range(6):
			if i != waiting_for_key and SettingsManager.get_key_for_pad(i) == key_string:
				# Key already in use
				key_buttons[waiting_for_key].text = SettingsManager.get_key_for_pad(waiting_for_key)
				waiting_for_key = -1
				# Show error message
				print("Key already in use!")
				return

		# Set the new key
		SettingsManager.set_key_for_pad(waiting_for_key, key_string)
		key_buttons[waiting_for_key].text = key_string
		waiting_for_key = -1

		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_cancel") and waiting_for_key < 0:
		_go_back()

func _on_master_volume_changed(value: float):
	SettingsManager.master_volume = value / 100.0
	SettingsManager.save_settings()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))

func _on_music_volume_changed(value: float):
	SettingsManager.music_volume = value / 100.0
	SettingsManager.save_settings()

func _on_sfx_volume_changed(value: float):
	SettingsManager.sfx_volume = value / 100.0
	SettingsManager.save_settings()

func _on_fps_toggle_toggled(button_pressed: bool):
	UISoundManager.play_selection_sound()
	SettingsManager.show_fps = button_pressed
	SettingsManager.save_settings()

	# Update FPS display immediately
	if get_tree().root.has_node("FPSDisplay"):
		var fps_display = get_tree().root.get_node("FPSDisplay")
		fps_display.visible = button_pressed

func _on_reset_button_pressed():
	UISoundManager.play_selection_sound()
	SettingsManager.reset_keymap_to_default()
	_load_settings()

func _on_back_button_pressed():
	UISoundManager.play_selection_sound()
	_go_back()

func _go_back():
	# Fade out before going back
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.2)
	await fade_out.finished

	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
