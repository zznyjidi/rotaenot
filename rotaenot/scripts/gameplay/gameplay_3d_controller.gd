extends Node2D

@onready var playfield = $Playfield3D
@onready var note_spawner = $Playfield3D/NoteSpawner
@onready var note_container = $Playfield3D/NoteContainer
@onready var hud = $HUD

var score = 0
var combo = 0
var max_combo = 0

# Key mappings for pads (index matches pad_config in playfield)
var key_map = {
	"pad_q": 0,  # Left top
	"pad_a": 1,  # Left mid
	"pad_z": 2,  # Left bot
	"pad_p": 3,  # Right top
	"pad_l": 4,  # Right mid
	"pad_m": 5   # Right bot
}

func _ready():
	print("Starting 3D perspective rhythm game...")

	# Set up input actions dynamically if needed
	_setup_input_actions()

	# Start spawning notes after a short delay
	await get_tree().create_timer(0.5).timeout
	if note_spawner and note_spawner.has_method("start_spawning"):
		note_spawner.start_spawning()

func _setup_input_actions():
	# Define the input map for the pads
	# This would normally be in project settings, but we can check them here
	pass

func _input(event):
	# Check for pad inputs
	if event is InputEventKey and event.pressed:
		var key = OS.get_keycode_string(event.keycode)

		# Map keys to pad indices
		var pad_index = -1
		match key:
			"Q": pad_index = 0
			"A": pad_index = 1
			"Z": pad_index = 2
			"P": pad_index = 3
			"L": pad_index = 4
			"M": pad_index = 5

		if pad_index >= 0:
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

func _miss_hit(pad_index: int):
	combo = 0
	hud.update_combo(combo)
	hud.show_judgment("MISS")