extends Node

class_name ChartLoader

# Chart data structure
var metadata: Dictionary = {}
var notes: Array = []
var current_note_index: int = 0
var is_loaded: bool = false
var uses_milliseconds: bool = true  # Default to milliseconds

func load_chart(chart_path: String) -> bool:
	# Detect file format
	if chart_path.ends_with(".json"):
		return _load_json_chart(chart_path)
	elif chart_path.ends_with(".chart") or chart_path.ends_with(".csv") or chart_path.ends_with(".osu"):
		return _load_csv_chart(chart_path)
	else:
		print("Unknown chart format: ", chart_path)
		return false

func _load_json_chart(chart_path: String) -> bool:
	var file = FileAccess.open(chart_path, FileAccess.READ)
	if not file:
		print("Failed to open chart file: ", chart_path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		print("Failed to parse JSON: ", json.get_error_message())
		return false

	var data = json.data
	if not data.has("metadata") or not data.has("notes"):
		print("Invalid chart format - missing metadata or notes")
		return false

	metadata = data["metadata"]
	notes = data["notes"]

	# Convert timing to milliseconds if needed
	_convert_to_milliseconds()

	current_note_index = 0
	is_loaded = true

	print("Chart loaded: ", metadata.get("title", "Unknown"))
	print("Total notes: ", notes.size())

	# Sort notes by time to ensure proper order
	notes.sort_custom(_sort_notes_by_time)

	return true

func _load_csv_chart(chart_path: String) -> bool:
	var file = FileAccess.open(chart_path, FileAccess.READ)
	if not file:
		print("Failed to open CSV chart: ", chart_path)
		return false

	# Initialize metadata from filename
	metadata = {
		"title": chart_path.get_file().get_basename(),
		"artist": "Unknown",
		"bpm": 120,
		"duration": "0:00",
		"audio_file": "",
		"difficulty": _extract_difficulty_from_path(chart_path),
		"format": "csv"
	}

	notes = []

	# Parse CSV lines
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 5:
			continue

		var note = _parse_csv_note(line)
		if not note.is_empty():
			notes.append(note)

	file.close()

	# Sort notes by time
	notes.sort_custom(_sort_notes_by_time)

	# Calculate duration from last note
	if notes.size() > 0:
		var last_time_ms = notes[-1].time
		var duration_sec = last_time_ms / 1000.0
		var minutes = int(duration_sec / 60)
		var seconds = int(duration_sec) % 60
		metadata.duration = "%d:%02d" % [minutes, seconds]

	current_note_index = 0
	is_loaded = true
	uses_milliseconds = true  # CSV format is always in milliseconds

	print("CSV Chart loaded: ", metadata.get("title", "Unknown"))
	print("Total notes: ", notes.size())

	return true

func _parse_csv_note(line: Array) -> Dictionary:
	if line.size() < 5:
		return {}

	var x_position = float(line[0])
	var time_ms = int(line[2])
	var object_type = int(line[3])

	# Convert x position (0-512) to track (0-5)
	var track = int(floor(x_position * 6.0 / 512.0))
	track = clamp(track, 0, 5)

	var note = {
		"time": time_ms,  # Already in milliseconds
		"track": track,
		"type": "tap"
	}

	# Determine note type from bitfield
	if object_type & 0b00000001:  # Tap note
		note.type = "tap"
	elif object_type & 0b10000000:  # Hold note
		note.type = "hold"
		if line.size() > 5 and line[5] != "":
			var extras = line[5].split(':')
			if extras.size() > 0 and extras[0] != "0":
				var end_time_ms = int(extras[0])
				note["hold_length"] = end_time_ms - time_ms
	elif object_type & 0b00000010:  # Swap note
		note.type = "swap"
		if line.size() > 5 and line[5] != "":
			var extras = line[5].split(':')
			if extras.size() > 0:
				var target_x = float(extras[0])
				var target_track = int(floor(target_x * 6.0 / 512.0))
				note["target_track"] = clamp(target_track, 0, 5)

	return note

func _extract_difficulty_from_path(path: String) -> String:
	var filename = path.get_file().to_lower()
	if "easy" in filename:
		return "Easy"
	elif "normal" in filename:
		return "Normal"
	elif "hard" in filename:
		return "Hard"
	elif "expert" in filename or "insane" in filename:
		return "Expert"
	elif "hell" in filename or "extreme" in filename:
		return "Hell"
	else:
		return "Normal"

func _convert_to_milliseconds():
	# Check if notes are in seconds (values < 1000 likely seconds)
	if notes.size() > 0:
		var first_time = notes[0].get("time", 0)
		var last_time = notes[-1].get("time", 0)

		# If the last note is less than 1000, it's likely in seconds
		if last_time < 1000:
			print("Converting chart timing from seconds to milliseconds")
			for note in notes:
				if note.has("time"):
					note.time = int(note.time * 1000)
				if note.has("hold_length"):
					note.hold_length = int(note.hold_length * 1000)
			uses_milliseconds = true

func _sort_notes_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a.get("time", 0.0) < b.get("time", 0.0)

func get_next_note_time() -> float:
	if not is_loaded or current_note_index >= notes.size():
		return -1.0

	# Always return time in milliseconds
	return notes[current_note_index].get("time", 0.0)

func get_next_note() -> Dictionary:
	if not is_loaded or current_note_index >= notes.size():
		return {}

	var note = notes[current_note_index]
	current_note_index += 1
	return note

func peek_next_note() -> Dictionary:
	if not is_loaded or current_note_index >= notes.size():
		return {}

	return notes[current_note_index]

func has_more_notes() -> bool:
	return is_loaded and current_note_index < notes.size()

func reset():
	current_note_index = 0

func get_bpm() -> float:
	return metadata.get("bpm", 120.0)

func get_offset() -> float:
	# Return offset in milliseconds
	var offset = metadata.get("offset", 0.0)
	if offset < 100:  # Likely in seconds
		offset *= 1000
	return offset

func get_title() -> String:
	return metadata.get("title", "Unknown")

func get_difficulty() -> String:
	return metadata.get("difficulty", "Normal")
