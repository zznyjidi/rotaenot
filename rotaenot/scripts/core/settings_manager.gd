extends Node

# Settings Manager Singleton
# Handles saving and loading of game settings including keymaps

const SETTINGS_FILE = "user://settings.cfg"

# Default keymap configuration
var default_keymap = {
	"pad_0": "W",  # Left top
	"pad_1": "E",  # Left mid
	"pad_2": "F",  # Left bot
	"pad_3": "J",  # Right top
	"pad_4": "I",  # Right mid
	"pad_5": "O"   # Right bot
}

# Current keymap (will be loaded from settings or use default)
var keymap = {}

# Other settings
var master_volume: float = 0.8
var sfx_volume: float = 1.0
var music_volume: float = 0.7

func _ready():
	# Load settings on startup
	load_settings()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)

	if err != OK:
		print("No settings file found, using defaults")
		# Use default settings
		keymap = default_keymap.duplicate()
		save_settings()
		return

	# Load keymap
	keymap.clear()
	for i in range(6):
		var key = "pad_" + str(i)
		if config.has_section_key("keymap", key):
			keymap[key] = config.get_value("keymap", key)
		else:
			keymap[key] = default_keymap[key]

	# Load audio settings
	if config.has_section_key("audio", "master_volume"):
		master_volume = config.get_value("audio", "master_volume")
	if config.has_section_key("audio", "sfx_volume"):
		sfx_volume = config.get_value("audio", "sfx_volume")
	if config.has_section_key("audio", "music_volume"):
		music_volume = config.get_value("audio", "music_volume")

	print("Settings loaded successfully")

func save_settings():
	var config = ConfigFile.new()

	# Save keymap
	for key in keymap:
		config.set_value("keymap", key, keymap[key])

	# Save audio settings
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)

	# Save to file
	var err = config.save(SETTINGS_FILE)
	if err == OK:
		print("Settings saved successfully")
	else:
		print("Failed to save settings")

func get_key_for_pad(pad_index: int) -> String:
	var key = "pad_" + str(pad_index)
	if keymap.has(key):
		return keymap[key]
	return default_keymap.get(key, "")

func set_key_for_pad(pad_index: int, key_string: String):
	var key = "pad_" + str(pad_index)
	keymap[key] = key_string
	save_settings()

func get_keymap_dict() -> Dictionary:
	# Return a dictionary mapping key strings to pad indices
	var result = {}
	for i in range(6):
		var key = get_key_for_pad(i)
		if key != "":
			result[key] = i
	return result

func reset_keymap_to_default():
	keymap = default_keymap.duplicate()
	save_settings()