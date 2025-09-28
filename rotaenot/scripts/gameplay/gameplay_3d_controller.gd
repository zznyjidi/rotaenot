extends Node2D

@onready var playfield = $Playfield3D
@onready var note_spawner = $Playfield3D/NoteSpawner
@onready var note_container = $Playfield3D/NoteContainer
@onready var hud = $HUD
@onready var music_player = AudioStreamPlayer.new()
@onready var background_image = get_node_or_null("BackgroundLayer/BackgroundImage")
@onready var blur_overlay = get_node_or_null("BackgroundLayer/BlurOverlay")
@onready var fallback_bg = get_node_or_null("Background")

var score = 0
var combo = 0
var max_combo = 0
var life = 100
var miss_count = 0
var is_paused = false
var pause_menu = null
var game_ended = false

# Statistics tracking
var perfect_count = 0
var great_count = 0
var good_count = 0
var bad_count = 0
var total_notes = 0

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

	# Update playfield combo display
	if playfield and playfield.has_method("update_combo_display"):
		playfield.update_combo_display(combo)
	hud.update_life(life)
	hud.update_miss(miss_count)

	# Create pause menu (initially hidden)
	_create_pause_menu()

	# Load background image
	_load_background()

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
	# Don't process if game ended
	if game_ended:
		return

	# Check for notes that went past the hit zone
	var notes = note_container.get_children()
	for note in notes:
		if note.has_meta("target_pad") and note.has_method("get_hit_distance"):
			var dist = note.get_hit_distance()
			# Note has gone too far past the pad
			if dist < -50:
				_auto_miss_note(note)

	# Check if song is finished (no spawner and no notes left)
	if note_spawner and note_spawner.has_method("is_finished"):
		if note_spawner.is_finished() and notes.size() == 0:
			_song_completed()
	elif music_player and music_player.stream:
		# Check if music has finished playing
		if not music_player.playing and notes.size() == 0:
			_song_completed()

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
	total_notes += 1

	if distance < 20:
		judgment = "PERFECT"
		score += 1000
		combo += 1
		perfect_count += 1
	elif distance < 40:
		judgment = "GREAT"
		score += 800
		combo += 1
		great_count += 1
	elif distance < 60:
		judgment = "GOOD"
		score += 500
		combo += 1
		good_count += 1
	else:
		judgment = "BAD"
		score += 100
		combo = 0
		bad_count += 1

	max_combo = max(max_combo, combo)

	# Update UI
	hud.update_score(score)
	hud.update_combo(combo)

	# Update playfield combo display
	if playfield and playfield.has_method("update_combo_display"):
		playfield.update_combo_display(combo)
	hud.show_judgment(judgment)

	# Update playfield combo display
	if playfield and playfield.has_method("update_combo_display"):
		playfield.update_combo_display(combo)

	# Remove the note
	note.queue_free()

func _miss_hit(_pad_index: int):
	combo = 0
	miss_count += 1
	total_notes += 1
	life = max(0, life - 5)  # Lose 5% life per miss

	hud.update_combo(combo)

	# Update playfield combo display
	if playfield and playfield.has_method("update_combo_display"):
		playfield.update_combo_display(combo)
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
	total_notes += 1
	life = max(0, life - 3)  # Lose 3% life for auto-miss

	hud.update_combo(combo)

	# Update playfield combo display
	if playfield and playfield.has_method("update_combo_display"):
		playfield.update_combo_display(combo)
	hud.update_miss(miss_count)
	hud.update_life(life)

	note.queue_free()

	# Check for game over
	if life <= 0:
		_game_over()

func _game_over():
	if game_ended:
		return
	game_ended = true

	print("Game Over! Final score: ", score, " Max combo: ", max_combo)
	if note_spawner:
		note_spawner.stop_spawning()
	if music_player:
		music_player.stop()

	# Store results in GameData
	GameData.last_game_results = {
		"result_type": 1,  # GAME_OVER
		"score": score,
		"max_combo": max_combo,
		"perfect_count": perfect_count,
		"great_count": great_count,
		"good_count": good_count,
		"bad_count": bad_count,
		"miss_count": miss_count
	}

	# Transition to results screen
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/results_screen.tscn")

func _song_completed():
	if game_ended:
		return
	game_ended = true

	print("Song Complete! Final score: ", score, " Max combo: ", max_combo)
	if music_player:
		music_player.stop()

	# Store results in GameData
	GameData.last_game_results = {
		"result_type": 0,  # VICTORY
		"score": score,
		"max_combo": max_combo,
		"perfect_count": perfect_count,
		"great_count": great_count,
		"good_count": good_count,
		"bad_count": bad_count,
		"miss_count": miss_count
	}

	# Transition to results screen
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/results_screen.tscn")

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

func _load_background():
	# Check if background nodes exist
	if not background_image:
		print("No background_image node found")
		return

	# Try to load song cover as background
	if GameData and GameData.selected_song:
		var image_path = GameData.selected_song.get("preview_image", "")
		print("Attempting to load background from: ", image_path)

		# Check if file exists
		if image_path != "" and FileAccess.file_exists(image_path):
			var texture = load(image_path) as Texture2D
			if texture:
				print("Successfully loaded background texture: ", texture)
				# Set the background image
				background_image.texture = texture

				# Apply blur effect using shader
				_apply_blur_shader()

				# Show the background layer
				if fallback_bg:
					fallback_bg.visible = false

				# Update the playfield mask after background is loaded
				# Pass the texture directly since timing might be an issue
				if playfield and playfield.has_method("update_center_mask_with_texture"):
					playfield.update_center_mask_with_texture(texture)
				elif playfield and playfield.has_method("update_center_mask"):
					# Wait a frame for the texture to be properly set
					await get_tree().process_frame
					playfield.update_center_mask()
				return
		else:
			print("Background image path not found or empty: ", image_path)

	# If no image, use the fallback solid color
	print("Using fallback solid color background")
	if fallback_bg:
		fallback_bg.visible = true
	if background_image:
		background_image.texture = null

func _apply_blur_shader():
	if not background_image or not blur_overlay:
		return

	# Create a shader material for blur effect
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform float darken_amount : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec4 color = vec4(0.0);
	float total = 0.0;

	// Simplified box blur for better performance
	for(float x = -2.0; x <= 2.0; x += 1.0) {
		for(float y = -2.0; y <= 2.0; y += 1.0) {
			float weight = 1.0 - (abs(x) + abs(y)) * 0.1;
			vec2 offset = vec2(x, y) * pixel_size * blur_amount;
			color += texture(TEXTURE, UV + offset) * weight;
			total += weight;
		}
	}

	color /= total;
	color.rgb *= (1.0 - darken_amount); // Darken the image
	COLOR = color;
}
"""

	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("blur_amount", 2.0)
	shader_material.set_shader_parameter("darken_amount", 0.3)
	background_image.material = shader_material

	# Adjust overlay darkness for additional contrast
	blur_overlay.color = Color(0, 0, 0, 0.5)
