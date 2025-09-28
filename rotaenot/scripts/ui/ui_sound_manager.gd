extends Node

# UI Sound Manager Singleton
# Handles playing UI sounds like button clicks

var selection_sound_player: AudioStreamPlayer

func _ready():
	# Create audio player for selection sound
	selection_sound_player = AudioStreamPlayer.new()
	add_child(selection_sound_player)
	selection_sound_player.bus = "Master"
	selection_sound_player.volume_db = -5  # Slightly quieter

	# Load the selection sound
	var sound_path = "res://assets/ui/backgrounds/pop-6.mp3"
	if FileAccess.file_exists(sound_path):
		var stream = load(sound_path)
		if stream:
			selection_sound_player.stream = stream
		else:
			print("Failed to load selection sound")
	else:
		print("Selection sound file not found: ", sound_path)

func play_selection_sound():
	if selection_sound_player and selection_sound_player.stream:
		# Apply SFX volume from settings
		if SettingsManager:
			var sfx_volume = SettingsManager.sfx_volume
			selection_sound_player.volume_db = linear_to_db(sfx_volume) - 5  # -5 for base reduction
		selection_sound_player.play()

func play_hover_sound():
	# Could add a different sound for hover if desired
	pass

func play_back_sound():
	# Could add a different sound for going back if desired
	pass