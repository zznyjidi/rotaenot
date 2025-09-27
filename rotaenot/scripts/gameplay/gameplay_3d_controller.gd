extends Node2D

@onready var playfield = $Playfield3D
@onready var note_spawner = $Playfield3D/NoteSpawner
@onready var note_container = $Playfield3D/NoteContainer
@onready var hud = $HUD
@onready var music_player = AudioStreamPlayer.new()

var score = 0
var combo = 0
var max_combo = 0
var life = 100
var miss_count = 0
var is_paused = false
var pause_menu = null

# Key mappings for pads (loaded from settings)
var key_map = {}

func _ready():
	print("Starting 3D perspective rhythm game...")

	# Load keymap from settings
	if SettingsManager:
		key_map = SettingsManager.get_keymap_dict()
		print("Loaded keymap: ", key_map)
	else:
		# Fallback if SettingsManager isn't available
		key_map = {"W": 0, "E": 1, "F": 2, "J": 3, "I": 4, "O": 5}

	# Set up music player
	add_child(music_player)
	music_player.bus = "Master"

	# Set up input actions dynamically if needed
	_setup_input_actions()

	# Initialize HUD
	hud.update_score(score)
	hud.update_combo(combo)
	hud.update_life(life)
	hud.update_miss(miss_count)

	# Create pause menu (initially hidden)
	_create_pause_menu()

	# Load selected song and chart if available
	if GameData and GameData.selected_song:
		# Load music
		if GameData.selected_song.has("music_path"):
			var music_path = GameData.selected_song.music_path
			print("Loading music: ", music_path)
			if FileAccess.file_exists(music_path):
				var stream = load(music_path)
				if stream:
					music_player.stream = stream
					music_player.volume_db = -5  # Slightly quieter

		# Load chart
		if GameData.selected_song.has("chart_path"):
			var chart_path = GameData.selected_song.chart_path
			print("Loading chart: ", chart_path)
			if note_spawner and note_spawner.has_method("load_chart"):
				note_spawner.load_chart(chart_path)

	# Start the game after a short delay
	await get_tree().create_timer(0.5).timeout
	_start_game()

func _start_game():
	# Start music
	if music_player.stream:
		music_player.play()

	# Start spawning notes
	if note_spawner and note_spawner.has_method("start_spawning"):
		note_spawner.start_spawning()

func _process(_delta):
	# Check for notes that went past the hit zone
	var notes = note_container.get_children()
	for note in notes:
		if note.has_meta("target_pad") and note.has_method("get_hit_distance"):
			var dist = note.get_hit_distance()
			# Note has gone too far past the pad
			if dist < -50:
				_auto_miss_note(note)

func _setup_input_actions():
	# Define the input map for the pads
	# This would normally be in project settings, but we can check them here
	pass

func _input(event):
	# Check for pause
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_toggle_pause()
		return

	# Don't process game inputs when paused
	if is_paused:
		return

	# Check for pad inputs
	if event is InputEventKey and event.pressed and not event.echo:
		var key = OS.get_keycode_string(event.keycode)

		# Map keys to pad indices using the key_map
		var pad_index = -1
		if key_map.has(key):
			pad_index = key_map[key]

		if pad_index >= 0:
			# Initial press - try to hit notes and show visual feedback
			_try_hit_pad(pad_index)

func _try_hit_pad(pad_index: int):
	# Visual feedback
	playfield.highlight_pad(pad_index)

	# Check for notes at this pad
	var notes = note_container.get_children()
	var best_note = null
	var best_distance = 999999

	for note in notes:
		if not note.has_meta("target_pad"):
			continue

		if note.get_meta("target_pad") != pad_index:
			continue

		if note.has_method("get_hit_distance"):
			var dist = note.get_hit_distance()
			if dist < best_distance and dist < 100:  # Within hit window
				best_distance = dist
				best_note = note

	if best_note:
		_hit_note(best_note, best_distance)
	else:
		_miss_hit(pad_index)

func _hit_note(note: Node2D, distance: float):
	var judgment = ""

	if distance < 20:
		judgment = "PERFECT"
		score += 1000
		combo += 1
	elif distance < 40:
		judgment = "GREAT"
		score += 800
		combo += 1
	elif distance < 60:
		judgment = "GOOD"
		score += 500
		combo += 1
	else:
		judgment = "BAD"
		score += 100
		combo = 0

	max_combo = max(max_combo, combo)

	# Update UI
	hud.update_score(score)
	hud.update_combo(combo)
	hud.show_judgment(judgment)

	# Remove the note
	note.queue_free()

func _miss_hit(_pad_index: int):
	combo = 0
	miss_count += 1
	life = max(0, life - 5)  # Lose 5% life per miss

	hud.update_combo(combo)
	hud.update_miss(miss_count)
	hud.update_life(life)
	hud.show_judgment("MISS")

	# Check for game over
	if life <= 0:
		_game_over()

func _auto_miss_note(note: Node2D):
	# Handle notes that passed without being hit
	combo = 0
	miss_count += 1
	life = max(0, life - 3)  # Lose 3% life for auto-miss

	hud.update_combo(combo)
	hud.update_miss(miss_count)
	hud.update_life(life)

	note.queue_free()

	# Check for game over
	if life <= 0:
		_game_over()

func _game_over():
	print("Game Over! Final score: ", score, " Max combo: ", max_combo)
	if note_spawner:
		note_spawner.stop_spawning()
	if music_player:
		music_player.stop()
	# Could transition to results screen here

func _create_pause_menu():
	# Create pause menu overlay
	pause_menu = Control.new()
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	pause_menu.z_index = 100  # On top of everything
	add_child(pause_menu)

	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	pause_menu.add_child(bg)

	# Center container - properly centered on screen
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center)

	# Menu panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 280)  # Taller for extra button
	center.add_child(panel)

	# VBox for menu items
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Add some top margin
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(top_spacer)

	# Paused label
	var paused_label = Label.new()
	paused_label.text = "PAUSED"
	paused_label.add_theme_font_size_override("font_size", 32)
	paused_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(paused_label)

	# Continue button
	var continue_btn = Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(180, 40)
	continue_btn.add_theme_font_size_override("font_size", 20)
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)

	# Restart button
	var restart_btn = Button.new()
	restart_btn.text = "Restart"
	restart_btn.custom_minimum_size = Vector2(180, 40)
	restart_btn.add_theme_font_size_override("font_size", 20)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)

	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Menu"
	quit_btn.custom_minimum_size = Vector2(180, 40)
	quit_btn.add_theme_font_size_override("font_size", 20)
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	# Add some bottom margin
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(bottom_spacer)

func _toggle_pause():
	is_paused = !is_paused

	if is_paused:
		# Pause the game
		get_tree().paused = true
		pause_menu.visible = true
		pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		if music_player:
			music_player.stream_paused = true
	else:
		# Resume the game
		get_tree().paused = false
		pause_menu.visible = false
		if music_player:
			music_player.stream_paused = false

func _on_continue_pressed():
	_toggle_pause()

func _on_quit_pressed():
	# Clean up
	get_tree().paused = false
	if music_player:
		music_player.stop()

	# Return to song select
	get_tree().change_scene_to_file("res://scenes/ui/song_select.tscn")

func _on_restart_pressed():
	# Clean up current state
	get_tree().paused = false
	if music_player:
		music_player.stop()

	# Reload the current scene
	get_tree().reload_current_scene()
