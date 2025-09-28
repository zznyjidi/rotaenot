extends Control

# Chart Generator Tool
# UI for generating charts from audio files

@onready var file_dialog = FileDialog.new()
@onready var audio_analyzer = AudioAnalyzer.new()

var selected_audio_path: String = ""
var generated_chart: Dictionary = {}

func _ready():
	# Setup UI
	_create_ui()

	# Setup file dialog
	add_child(file_dialog)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.mp3", "MP3 Audio Files")
	file_dialog.add_filter("*.ogg", "OGG Audio Files")
	file_dialog.add_filter("*.wav", "WAV Audio Files")
	file_dialog.file_selected.connect(_on_file_selected)

	add_child(audio_analyzer)

func _create_ui():
	# Create main container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(600, 400)
	add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Chart Generator Tool"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# Separator
	vbox.add_child(HSeparator.new())

	# File selection
	var file_section = HBoxContainer.new()
	vbox.add_child(file_section)

	var file_label = Label.new()
	file_label.text = "Audio File: "
	file_section.add_child(file_label)

	var file_path_label = Label.new()
	file_path_label.text = "No file selected"
	file_path_label.name = "FilePath"
	file_section.add_child(file_path_label)

	var browse_btn = Button.new()
	browse_btn.text = "Browse..."
	browse_btn.pressed.connect(_on_browse_pressed)
	file_section.add_child(browse_btn)

	# Parameters section
	vbox.add_child(Label.new())  # Spacer

	var params_label = Label.new()
	params_label.text = "Generation Parameters:"
	params_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(params_label)

	# Difficulty selector
	var diff_container = HBoxContainer.new()
	vbox.add_child(diff_container)

	var diff_label = Label.new()
	diff_label.text = "Difficulty: "
	diff_container.add_child(diff_label)

	var diff_selector = OptionButton.new()
	diff_selector.name = "DifficultySelector"
	diff_selector.add_item("Easy")
	diff_selector.add_item("Normal")
	diff_selector.add_item("Hard")
	diff_selector.add_item("Expert")
	diff_selector.selected = 1  # Default to Normal
	diff_container.add_child(diff_selector)

	# Note density slider
	var density_container = HBoxContainer.new()
	vbox.add_child(density_container)

	var density_label = Label.new()
	density_label.text = "Note Density: "
	density_container.add_child(density_label)

	var density_slider = HSlider.new()
	density_slider.name = "DensitySlider"
	density_slider.min_value = 0.5
	density_slider.max_value = 2.0
	density_slider.value = 1.0
	density_slider.step = 0.1
	density_slider.custom_minimum_size.x = 200
	density_container.add_child(density_slider)

	var density_value = Label.new()
	density_value.name = "DensityValue"
	density_value.text = "1.0x"
	density_container.add_child(density_value)

	density_slider.value_changed.connect(func(value):
		density_value.text = str(value) + "x"
	)

	# Pattern style selector
	var pattern_container = HBoxContainer.new()
	vbox.add_child(pattern_container)

	var pattern_label = Label.new()
	pattern_label.text = "Pattern Style: "
	pattern_container.add_child(pattern_label)

	var pattern_selector = OptionButton.new()
	pattern_selector.name = "PatternSelector"
	pattern_selector.add_item("Balanced")
	pattern_selector.add_item("Stream")
	pattern_selector.add_item("Jump")
	pattern_selector.add_item("Technical")
	pattern_selector.selected = 0
	pattern_container.add_child(pattern_selector)

	# Generate button
	vbox.add_child(Label.new())  # Spacer

	var generate_btn = Button.new()
	generate_btn.text = "Generate Chart"
	generate_btn.custom_minimum_size = Vector2(200, 40)
	generate_btn.add_theme_font_size_override("font_size", 18)
	generate_btn.pressed.connect(_on_generate_pressed)
	vbox.add_child(generate_btn)

	# Status label
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	vbox.add_child(status_label)

	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.visible = false
	vbox.add_child(progress_bar)

	# Action buttons
	var action_container = HBoxContainer.new()
	action_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(action_container)

	var save_btn = Button.new()
	save_btn.name = "SaveButton"
	save_btn.text = "Save Chart"
	save_btn.visible = false
	save_btn.pressed.connect(_on_save_pressed)
	action_container.add_child(save_btn)

	var test_btn = Button.new()
	test_btn.name = "TestButton"
	test_btn.text = "Test Chart"
	test_btn.visible = false
	test_btn.pressed.connect(_on_test_pressed)
	action_container.add_child(test_btn)

func _on_browse_pressed():
	file_dialog.popup_centered(Vector2(800, 600))

func _on_file_selected(path: String):
	selected_audio_path = path
	var file_label = get_node("FilePath")
	if file_label:
		file_label.text = path.get_file()

func _on_generate_pressed():
	if selected_audio_path.is_empty():
		_show_status("Please select an audio file first!", true)
		return

	_show_status("Analyzing audio...")

	# Get parameters
	var difficulty = get_node("DifficultySelector").selected
	var density = get_node("DensitySlider").value
	var pattern_style = get_node("PatternSelector").selected

	# Show progress
	var progress_bar = get_node("ProgressBar")
	progress_bar.visible = true
	progress_bar.value = 0

	# Generate chart
	generated_chart = await audio_analyzer.analyze_audio_file(selected_audio_path)

	if generated_chart.is_empty():
		_show_status("Failed to generate chart!", true)
		progress_bar.visible = false
		return

	# Apply parameters to modify the generated chart
	_apply_difficulty_modifier(difficulty)
	_apply_density_modifier(density)
	_apply_pattern_style(pattern_style)

	progress_bar.value = 100
	_show_status("Chart generated successfully!")

	# Show action buttons
	get_node("SaveButton").visible = true
	get_node("TestButton").visible = true

func _apply_difficulty_modifier(difficulty: int):
	"""Modify chart based on difficulty"""
	# Adjust note density and complexity based on difficulty
	var keep_ratio = [0.4, 0.6, 0.8, 1.0][difficulty]  # Easy, Normal, Hard, Expert

	# Remove some notes for easier difficulties
	if keep_ratio < 1.0:
		var notes = generated_chart.notes
		var new_notes = []
		for i in range(notes.size()):
			if randf() < keep_ratio:
				new_notes.append(notes[i])
		generated_chart.notes = new_notes

func _apply_density_modifier(density: float):
	"""Adjust note density"""
	if density == 1.0:
		return

	if density < 1.0:
		# Remove notes
		var notes = generated_chart.notes
		var new_notes = []
		for i in range(notes.size()):
			if randf() < density:
				new_notes.append(notes[i])
		generated_chart.notes = new_notes
	else:
		# Add more notes (simplified - just duplicate some with slight offset)
		var notes = generated_chart.notes.duplicate()
		var extra_notes = []
		for note in notes:
			if randf() < (density - 1.0):
				var new_note = note.duplicate()
				new_note.time += 0.1  # Slight offset
				new_note.track = (note.track + 1) % 6  # Different track
				extra_notes.append(new_note)
		generated_chart.notes.append_array(extra_notes)
		generated_chart.notes.sort_custom(func(a, b): return a.time < b.time)

func _apply_pattern_style(style: int):
	"""Apply pattern style preferences"""
	# This would modify the note patterns
	# For now, it's a placeholder
	pass

func _on_save_pressed():
	if generated_chart.is_empty():
		return

	# Generate output filename
	var audio_name = selected_audio_path.get_file().get_basename()
	var output_path = "res://charts/" + audio_name + "_generated.json"

	audio_analyzer.save_chart_to_file(generated_chart, output_path)
	_show_status("Chart saved to: " + output_path)

func _on_test_pressed():
	if generated_chart.is_empty():
		return

	# Save temporary chart and load in game
	var temp_path = "res://charts/temp_test_chart.json"
	audio_analyzer.save_chart_to_file(generated_chart, temp_path)

	# Set up game data for testing
	GameData.selected_song = {
		"title": "Test Chart",
		"artist": "Generated",
		"bpm": generated_chart.metadata.bpm,
		"music_path": selected_audio_path,
		"chart_path": temp_path
	}

	# Load gameplay scene
	get_tree().change_scene_to_file("res://scenes/gameplay/gameplay_3d.tscn")

func _show_status(message: String, is_error: bool = false):
	var status = get_node("StatusLabel")
	if status:
		status.text = message
		if is_error:
			status.add_theme_color_override("font_color", Color.RED)
		else:
			status.add_theme_color_override("font_color", Color.GREEN)