extends Node2D

var note_scene = preload("res://scenes_notes_note_3d.tscn")
var is_spawning: bool = false
var chart_finished: bool = false

# Chart system
var chart_loader: ChartLoader
var song_time_ms: float = 0.0  # Time in milliseconds
var spawn_offset_ms: float = 800.0  # Spawn notes 800ms early for travel time
var chart_loaded: bool = false
var default_chart_path = "charts_demo_chart.json"

# Fallback pattern if no chart is loaded
var use_fallback: bool = false
var fallback_timer: float = 0.0
var fallback_interval: float = 1.0
var pattern_index: int = 0
var fallback_pattern = [
	{"pad": 0, "switch_to": -1},
	{"pad": 3, "switch_to": -1},
	{"pad": 1, "switch_to": 2},
	{"pad": 4, "switch_to": 3},
	{"pad": 2, "switch_to": -1},
	{"pad": 5, "switch_to": -1}
]

func _ready():
	# Create and load chart
	chart_loader = ChartLoader.new()
	add_child(chart_loader)

	if chart_loader.load_chart(default_chart_path):
		chart_loaded = true
		print("Chart loaded successfully: ", chart_loader.get_title())
	else:
		print("Failed to load chart, using fallback pattern")
		use_fallback = true

func start_spawning():
	is_spawning = true
	print("Started spawning notes")

func stop_spawning():
	is_spawning = false

func is_finished() -> bool:
	return chart_finished

func load_chart(chart_path: String) -> bool:
	# Load a specific chart file
	song_time_ms = 0.0

	if chart_loader.load_chart(chart_path):
		chart_loaded = true
		use_fallback = false
		print("Chart loaded: ", chart_loader.get_title())
		return true
	else:
		print("Failed to load chart: ", chart_path)
		use_fallback = true
		return false

func reset():
	# Reset the spawner for replay
	song_time_ms = 0.0
	chart_finished = false
	if chart_loader:
		chart_loader.reset()
	pattern_index = 0
	fallback_timer = 0.0

func _process(delta):
	if not is_spawning:
		return

	# Update time in milliseconds
	song_time_ms += delta * 1000.0

	if chart_loaded and not use_fallback:
		# Use chart-based spawning
		_process_chart()
	else:
		# Use fallback pattern spawning
		_process_fallback(delta)

func _process_chart():
	# Check if it's time to spawn the next note
	while chart_loader.has_more_notes():
		var next_time_ms = chart_loader.get_next_note_time()
		# Spawn notes early so they have time to travel
		if next_time_ms <= song_time_ms + spawn_offset_ms:
			var note_data = chart_loader.get_next_note()
			# Add the actual hit time to the note data
			note_data["hit_time_ms"] = note_data.get("time", 0)
			_spawn_note_from_data(note_data)
		else:
			break

	# Check if chart is finished
	if not chart_loader.has_more_notes() and not chart_finished:
		chart_finished = true
		print("All notes spawned, waiting for last notes to complete")

func _process_fallback(delta: float):
	# Use the old timer-based system for fallback
	fallback_timer += delta
	if fallback_timer >= fallback_interval:
		fallback_timer = 0.0
		var note_info = fallback_pattern[pattern_index]
		pattern_index = (pattern_index + 1) % fallback_pattern.size()
		_spawn_note_from_data(note_info)
		fallback_interval = randf_range(0.5, 1.5)

func _spawn_note_from_data(note_data: Dictionary):
	var playfield = get_parent()
	var note_container = playfield.get_node("NoteContainer")

	if not playfield or not note_container:
		return

	# Get track from note data (0-5)
	var target_pad = note_data.get("track", note_data.get("pad", 0))
	var switch_to_pad = note_data.get("target_track", note_data.get("switch_to", -1))

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
		note.set_script(load("scripts_notes_note_3d_v2.gd"))
		note_container.add_child(note)

		if note.has_method("setup"):
			note.setup(target_pad, track_idx, top_track, bottom_track)

			# Set up track switching if specified
			if switch_to_pad >= 0 and note.has_method("set_track_switch"):
				note.set_track_switch(switch_to_pad)
