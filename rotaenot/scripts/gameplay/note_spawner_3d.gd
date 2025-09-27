extends Node2D

var note_scene = preload("res://scenes/notes/note_3d.tscn")
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0
var is_spawning: bool = false

# Pattern for demo
var pattern_index: int = 0
var demo_pattern = [0, 3, 1, 4, 2, 5, 1, 4, 0, 3, 2, 5]  # Pad indices

func _ready():
	pass

func start_spawning():
	is_spawning = true
	print("Started spawning notes")

func stop_spawning():
	is_spawning = false

func _process(delta):
	if not is_spawning:
		return

	spawn_timer += delta

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_note()

		# Vary the spawn rate
		spawn_interval = randf_range(0.5, 1.5)

func _spawn_note():
	var playfield = get_parent()
	var note_container = playfield.get_node("NoteContainer")

	if not playfield or not note_container:
		return

	# Get next pad from pattern
	var target_pad = demo_pattern[pattern_index]
	pattern_index = (pattern_index + 1) % demo_pattern.size()

	# Get the two track lines for this pad
	var track_idx = target_pad * 2  # Each pad has 2 tracks

	# Get track line points
	if not playfield.has_method("get_track_line_points"):
		# Fallback to old method
		var track_points = playfield.get_track_points(target_pad)
		if track_points.size() == 0:
			return

		var note = note_scene.instantiate()
		note_container.add_child(note)
		if note.has_method("setup"):
			note.setup(target_pad, track_points)
	else:
		# New method with separate track lines
		var top_track = playfield.get_track_line_points(track_idx)
		var bottom_track = playfield.get_track_line_points(track_idx + 1)

		if top_track.size() == 0 or bottom_track.size() == 0:
			return

		# Create note with new script
		var note = Node2D.new()
		note.set_script(load("res://scripts/notes/note_3d_v2.gd"))
		note_container.add_child(note)

		if note.has_method("setup"):
			note.setup(target_pad, track_idx, top_track, bottom_track)