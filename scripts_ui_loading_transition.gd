extends Control

# Transition settings
var fade_in_duration: float = 0.3
var display_duration: float = 2.0
var fade_out_duration: float = 0.5

# UI References
@onready var background = $CoverBackground
@onready var song_info_container = $VBoxContainer/InfoPanel
@onready var song_title = $VBoxContainer/InfoPanel/InfoContainer/SongTitle
@onready var artist_label = $VBoxContainer/InfoPanel/InfoContainer/ArtistLabel
@onready var difficulty_label = $VBoxContainer/InfoPanel/InfoContainer/DifficultyLabel
@onready var song_image = $VBoxContainer/SongImage
@onready var loading_label = $VBoxContainer/InfoPanel/InfoContainer/LoadingLabel

func _ready():
	# Start fully transparent
	modulate.a = 0.0

	# Load song info from GameData
	if GameData and GameData.selected_song:
		var song = GameData.selected_song
		song_title.text = song.get("title", "Unknown Song")
		artist_label.text = song.get("artist", "Unknown Artist")

		var difficulty = GameData.selected_difficulty
		var level = "?"
		if song.has("difficulties") and song.difficulties.has(difficulty):
			level = str(song.difficulties[difficulty].get("level", "?"))

		difficulty_label.text = difficulty + " ★" + level

		# Load song image with smart scaling
		var image_path = song.get("preview_image", "")
		_load_and_scale_preview_image(image_path)

	# Start the transition sequence
	_start_transition()

func _start_transition():
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

	# Wait for display duration
	await get_tree().create_timer(fade_in_duration + display_duration).timeout

	# Fade out
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)

	# Wait for fade out to complete
	await fade_out_tween.finished

	# Load the gameplay scene
	get_tree().change_scene_to_file("res://scenes_gameplay_gameplay_3d.tscn")

func _load_and_scale_preview_image(image_path: String):
	# Fixed width for consistent layout
	const FIXED_WIDTH = 600.0  # Wider for transition screen
	const MAX_HEIGHT = 400.0
	const MIN_HEIGHT = 200.0

	# Clear current texture first
	song_image.texture = null

	# Use ImagePreloader for HTML5 compatibility
	var texture = ImagePreloader.get_cover_from_path(image_path)
	if not texture:
		print("Failed to load image: ", image_path)
		return

	# Get original image dimensions
	var original_width = texture.get_width()
	var original_height = texture.get_height()

	if original_width <= 0 or original_height <= 0:
		print("Invalid image dimensions")
		return

	# Calculate aspect ratio
	var aspect_ratio = float(original_height) / float(original_width)

	# Calculate target height based on fixed width
	var target_height = FIXED_WIDTH * aspect_ratio

	# Clamp height within reasonable bounds
	target_height = clamp(target_height, MIN_HEIGHT, MAX_HEIGHT)

	# Apply the texture
	song_image.texture = texture

	# Update image size
	if song_image:
		song_image.custom_minimum_size = Vector2(FIXED_WIDTH, target_height)

	# Set appropriate stretch mode based on aspect ratio
	if target_height == MAX_HEIGHT or target_height == MIN_HEIGHT:
		# Image was clamped, use keep aspect centered
		song_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		# Image fits perfectly, use keep aspect
		song_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	# Animate the image appearance
	song_image.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(song_image, "modulate:a", 1.0, 0.3)
