extends Control

# Song list
var songs: Array = []
var current_index: int = 0
var song_items: Array = []

# UI References
@onready var song_list_container = $HBoxContainer/LeftPanel/ScrollContainer/SongList
@onready var scroll_container = $HBoxContainer/LeftPanel/ScrollContainer
@onready var info_panel = $HBoxContainer/RightPanel/InfoContainer
@onready var song_title = $HBoxContainer/RightPanel/InfoContainer/SongTitle
@onready var artist_label = $HBoxContainer/RightPanel/InfoContainer/ArtistLabel
@onready var bpm_label = $HBoxContainer/RightPanel/InfoContainer/StatsContainer/BPMLabel
@onready var duration_label = $HBoxContainer/RightPanel/InfoContainer/StatsContainer/DurationLabel
@onready var preview_image = $HBoxContainer/RightPanel/InfoContainer/PreviewImage
@onready var difficulty_container = $HBoxContainer/RightPanel/InfoContainer/DifficultyContainer
@onready var select_bg = $BackgroundLayer/SelectBackground
@onready var unselect_bg = $BackgroundLayer/UnSelectBackground

# Visual settings
const NORMAL_SCALE = 0.85  # Smaller base scale
const HOVER_SCALE = 0.95   # Reduced hover scale
const SELECTED_SCALE = 1.0  # Reduced selected scale
const NORMAL_ALPHA = 0.6
const HOVER_ALPHA = 0.85
const SELECTED_ALPHA = 1.0

# Selected difficulty
var selected_difficulty: String = "Normal"

# Music preview
@onready var preview_player = AudioStreamPlayer.new()
var preview_fade_timer: Timer
var current_preview_song: int = -1

func _ready():
	# Start with fade in
	modulate.a = 0.0
	var fade_in = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.3)

	# Setup music preview player
	add_child(preview_player)
	preview_player.bus = "Master"
	preview_player.volume_db = -15  # Quieter for preview

	# Setup preview fade timer
	preview_fade_timer = Timer.new()
	add_child(preview_fade_timer)
	preview_fade_timer.wait_time = 0.3  # Short delay before playing preview
	preview_fade_timer.one_shot = true
	preview_fade_timer.timeout.connect(_start_preview_playback)

	# Load songs from database
	songs = SongDatabase.get_all_songs()

	# Create song list items
	_create_song_list()

	# Select first song
	if songs.size() > 0:
		_select_song(0)

func _input(event):
	# Navigation with arrow keys and enter
	if event.is_action_pressed("ui_up"):
		# Navigate up in song list
		if current_index > 0:
			_select_song(current_index - 1)
	elif event.is_action_pressed("ui_down"):
		# Navigate down in song list
		if current_index < songs.size() - 1:
			_select_song(current_index + 1)
	elif event.is_action_pressed("ui_left"):
		# Change difficulty left
		_change_difficulty(-1)
	elif event.is_action_pressed("ui_right"):
		# Change difficulty right
		_change_difficulty(1)
	elif event.is_action_pressed("ui_accept"):
		# Start game with selected song and difficulty
		_start_game()
	elif event.is_action_pressed("ui_cancel"):
		# Go back to main menu
		_go_back()

func _create_song_list():
	# Clear existing items
	for child in song_list_container.get_children():
		child.queue_free()
	song_items.clear()

	# Create list items
	for i in range(songs.size()):
		var song = songs[i]
		var item = _create_song_item(song, i)
		song_list_container.add_child(item)
		song_items.append(item)

func _create_song_item(song: Dictionary, index: int) -> Control:
	var item = PanelContainer.new()
	item.custom_minimum_size = Vector2(200, 45)  # Much smaller to account for scaling
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Add a stylebox for the item
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	item.add_theme_stylebox_override("panel", style_normal)

	# Create content container
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)  # Reduced separation
	item.add_child(hbox)

	# Lock icon or number
	var index_label = Label.new()
	index_label.custom_minimum_size = Vector2(25, 0)
	if song.unlock_status:
		index_label.text = str(index + 1).pad_zeros(2)
	else:
		index_label.text = "🔒"
	index_label.add_theme_font_size_override("font_size", 16)  # Smaller font
	hbox.add_child(index_label)

	# Song info container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = song.title
	title.add_theme_font_size_override("font_size", 14)  # Smaller font
	title.add_theme_color_override("font_color", Color.WHITE if song.unlock_status else Color(0.5, 0.5, 0.5))
	title.clip_text = true  # Prevent overflow
	vbox.add_child(title)

	# Artist
	var artist = Label.new()
	artist.text = song.artist
	artist.add_theme_font_size_override("font_size", 11)  # Smaller font
	artist.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if song.unlock_status else Color(0.4, 0.4, 0.4))
	artist.clip_text = true  # Prevent overflow
	vbox.add_child(artist)

	# Difficulty indicators
	var diff_container = HBoxContainer.new()
	diff_container.add_theme_constant_override("separation", 5)
	hbox.add_child(diff_container)

	for diff_name in song.difficulties:
		var diff_label = Label.new()
		diff_label.text = diff_name.substr(0, 1)  # E, N, H, X
		diff_label.add_theme_font_size_override("font_size", 12)

		var diff_color = _get_difficulty_color(diff_name)
		diff_label.add_theme_color_override("font_color", diff_color)
		diff_container.add_child(diff_label)

	# Store metadata
	item.set_meta("index", index)
	item.set_meta("locked", not song.unlock_status)

	return item

func _get_difficulty_color(difficulty: String) -> Color:
	match difficulty:
		"Easy":
			return Color(0.3, 0.8, 0.3)
		"Normal":
			return Color(0.3, 0.6, 1.0)
		"Hard":
			return Color(1.0, 0.5, 0.3)
		"Expert":
			return Color(1.0, 0.2, 0.5)
		"Hell":
			return Color(0.8, 0.0, 0.0)  # Dark red
		_:
			return Color.WHITE

# Duplicate _input function removed - navigation is handled by the first _input function at line 48

func _navigate(direction: int):
	var new_index = current_index + direction

	# Wrap around
	if new_index < 0:
		new_index = songs.size() - 1
	elif new_index >= songs.size():
		new_index = 0

	_select_song(new_index)

func _select_song(index: int):
	# Play a light navigation sound (using the same sound at lower volume for now)
	if current_index != index:  # Only play if actually changing selection
		UISoundManager.play_selection_sound()

	current_index = index
	var song = songs[current_index]

	# Update visual states of all items
	for i in range(song_items.size()):
		var item = song_items[i]
		_update_item_visual(item, i == current_index, abs(i - current_index))

	# Scroll to selected item
	_scroll_to_item(current_index)

	# Update info panel
	_update_info_panel(song)

	# Animate background transition
	_animate_background_selection()

	# Start preview music after a short delay
	if current_preview_song != index:
		current_preview_song = index
		preview_fade_timer.stop()
		preview_fade_timer.start()

func _update_item_visual(item: Control, is_selected: bool, distance: int):
	# Calculate scale and alpha based on distance from selected
	var target_scale = NORMAL_SCALE
	var target_alpha = NORMAL_ALPHA

	if is_selected:
		target_scale = SELECTED_SCALE
		target_alpha = SELECTED_ALPHA
	elif distance == 1:
		target_scale = HOVER_SCALE
		target_alpha = HOVER_ALPHA
	elif distance == 2:
		target_scale = NORMAL_SCALE + 0.03  # Smaller increment
		target_alpha = NORMAL_ALPHA + 0.1

	# Apply scale with animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "scale", Vector2(target_scale, target_scale), 0.2)
	tween.tween_property(item, "modulate:a", target_alpha, 0.2)

	# Update panel color for selected
	var style = item.get_theme_stylebox("panel")
	if style and style is StyleBoxFlat:
		var target_color = Color(0.15, 0.15, 0.2, 0.8)
		if is_selected:
			target_color = Color(0.2, 0.25, 0.4, 0.9)
		elif distance == 1:
			target_color = Color(0.17, 0.17, 0.25, 0.85)
		tween.tween_property(style, "bg_color", target_color, 0.2)

func _scroll_to_item(index: int):
	if index >= 0 and index < song_items.size():
		var item = song_items[index]
		var item_y = item.position.y
		var item_height = item.size.y
		var container_height = scroll_container.size.y

		# Center the selected item
		var target_scroll = item_y - (container_height - item_height) / 2

		var tween = create_tween()
		tween.tween_property(scroll_container, "scroll_vertical", int(target_scroll), 0.3)

func _update_info_panel(song: Dictionary):
	# Update basic info
	song_title.text = song.title
	artist_label.text = "by " + song.artist
	bpm_label.text = "BPM: " + str(song.bpm)
	duration_label.text = "Duration: " + song.duration

	# Update preview image with smart scaling
	_load_and_scale_preview_image(song.preview_image)

	# Update difficulty buttons
	for child in difficulty_container.get_children():
		child.queue_free()

	# Find first available difficulty
	var first_diff = ""
	for diff_name in song.difficulties:
		if first_diff == "":
			first_diff = diff_name

		var diff_btn = Button.new()
		diff_btn.text = diff_name + " ★" + str(song.difficulties[diff_name].level)
		diff_btn.custom_minimum_size = Vector2(120, 40)
		diff_btn.add_theme_font_size_override("font_size", 16)

		# Style the button
		if diff_name == selected_difficulty and song.difficulties.has(selected_difficulty):
			diff_btn.add_theme_color_override("font_color", _get_difficulty_color(diff_name))

		diff_btn.pressed.connect(_on_difficulty_selected.bind(diff_name))
		difficulty_container.add_child(diff_btn)

	# Select default difficulty if current is not available
	if not song.difficulties.has(selected_difficulty):
		selected_difficulty = first_diff

func _on_difficulty_selected(difficulty: String):
	UISoundManager.play_selection_sound()
	selected_difficulty = difficulty
	_update_info_panel(songs[current_index])

func _change_difficulty(direction: int):
	var song = songs[current_index]
	var difficulties = song.difficulties.keys()
	var current_diff_index = difficulties.find(selected_difficulty)

	if current_diff_index == -1:
		current_diff_index = 0

	var new_index = current_diff_index + direction
	if new_index < 0:
		new_index = difficulties.size() - 1
	elif new_index >= difficulties.size():
		new_index = 0

	selected_difficulty = difficulties[new_index]
	_update_info_panel(song)

func _start_game():
	var song = songs[current_index]

	if not song.unlock_status:
		# Show locked message
		print("This song is locked!")
		# Could play an error sound here
		return

	# Play selection sound for starting game
	UISoundManager.play_selection_sound()

	# Check if this difficulty has a specific chart path
	var song_copy = song.duplicate(true)
	if song.difficulties.has(selected_difficulty):
		var diff_data = song.difficulties[selected_difficulty]
		if diff_data.has("chart_path"):
			song_copy.chart_path = diff_data.chart_path

	# Store selected song data
	GameData.selected_song = song_copy
	GameData.selected_difficulty = selected_difficulty

	# Stop preview music
	if preview_player:
		preview_player.stop()

	# Fade out before transitioning
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.2)
	await fade_out.finished

	# Load the transition scene
	get_tree().change_scene_to_file("res://scenes/ui/loading_transition.tscn")

func _go_back():
	# Stop preview music
	if preview_player:
		preview_player.stop()

	# Fade out before going back
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.2)
	await fade_out.finished

	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _animate_background_selection():
	# Crossfade between backgrounds
	if not select_bg or not unselect_bg:
		return

	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in selected background
	tween.tween_property(select_bg, "modulate:a", 1.0, 0.3)
	# Fade out unselected background slightly
	tween.tween_property(unselect_bg, "modulate:a", 0.3, 0.3)

func _load_and_scale_preview_image(image_path: String):
	# Fixed width for consistent layout
	const FIXED_WIDTH = 400.0
	const MAX_HEIGHT = 300.0
	const MIN_HEIGHT = 150.0
	const NO_IMAGE_PATH = "res://assets/ui/menu_backgrounds/NoImage.png"

	# Clear current texture first
	preview_image.texture = null

	# Check if file exists, use NoImage.png as fallback
	if not FileAccess.file_exists(image_path):
		print("Image not found: ", image_path, " - using NoImage.png")
		image_path = NO_IMAGE_PATH

	# Load the image
	var texture = load(image_path) as Texture2D
	if not texture:
		print("Failed to load image: ", image_path)
		preview_image.custom_minimum_size = Vector2(FIXED_WIDTH, 225)
		return

	# Get original image dimensions
	var original_width = texture.get_width()
	var original_height = texture.get_height()

	if original_width <= 0 or original_height <= 0:
		print("Invalid image dimensions")
		preview_image.custom_minimum_size = Vector2(FIXED_WIDTH, 225)
		return

	# Calculate aspect ratio
	var aspect_ratio = float(original_height) / float(original_width)

	# Calculate target height based on fixed width
	var target_height = FIXED_WIDTH * aspect_ratio

	# Clamp height within reasonable bounds
	target_height = clamp(target_height, MIN_HEIGHT, MAX_HEIGHT)

	# Apply the texture and size
	preview_image.texture = texture
	preview_image.custom_minimum_size = Vector2(FIXED_WIDTH, target_height)

	# Set appropriate stretch mode based on aspect ratio
	if target_height == MAX_HEIGHT or target_height == MIN_HEIGHT:
		# Image was clamped, use keep aspect centered
		preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		# Image fits perfectly, use keep aspect
		preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	# Animate the image appearance
	preview_image.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(preview_image, "modulate:a", 1.0, 0.2)

func _start_preview_playback():
	# Stop current preview if playing
	if preview_player.playing:
		var fade_out = create_tween()
		fade_out.tween_property(preview_player, "volume_db", -60.0, 0.2)
		await fade_out.finished
		preview_player.stop()

	# Get current song
	if current_index >= 0 and current_index < songs.size():
		var song = songs[current_index]

		# Check if song has a music path
		if song.has("music_path") and song.music_path != "":
			var music_path = song.music_path

			# Check if file exists
			if FileAccess.file_exists(music_path):
				print("Playing preview: ", music_path)

				# Load and play the music
				var stream = load(music_path)
				if stream:
					preview_player.stream = stream
					preview_player.volume_db = -60.0  # Start quiet
					preview_player.play()

					# Fade in the preview
					var fade_in = create_tween()
					fade_in.tween_property(preview_player, "volume_db", -15.0, 0.5)
				else:
					print("Failed to load preview: ", music_path)
			else:
				print("Music file not found: ", music_path)
		else:
			print("No music path for song: ", song.title if song.has("title") else "Unknown")
