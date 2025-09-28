extends Node

# Universal Chart Loader
# Loads charts from both JSON and CSV/OSU formats
# Uses milliseconds for timing and 0-5 for tracks

class_name UniversalChartLoader

# Load any chart format and return normalized JSON structure
static func load_chart(path: String) -> Dictionary:
	if path.ends_with(".json"):
		return load_json_chart(path)
	elif path.ends_with(".chart") or path.ends_with(".osu") or path.ends_with(".csv"):
		return load_csv_chart(path)
	else:
		print("Unknown chart format: ", path)
		return {}

# Load JSON chart and convert to milliseconds if needed
static func load_json_chart(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Failed to open JSON chart: ", path)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Failed to parse JSON: ", json.get_error_message())
		return {}

	var chart_data = json.data

	# Convert timing to milliseconds if it's in seconds
	if chart_data.has("notes"):
		for note in chart_data.notes:
			# Check if timing seems to be in seconds (values < 1000 likely seconds)
			if note.has("time") and note.time < 1000:
				note.time = int(note.time * 1000)  # Convert to milliseconds

			# Ensure track is 0-5
			if note.has("track"):
				note.track = clamp(note.track, 0, 5)

			# Convert hold length to milliseconds if needed
			if note.has("hold_length") and note.hold_length < 1000:
				note.hold_length = int(note.hold_length * 1000)

	return chart_data

# Load CSV/OSU chart format and convert to JSON structure
static func load_csv_chart(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Failed to open CSV chart: ", path)
		return {}

	var chart_data = {
		"metadata": {
			"title": path.get_file().get_basename(),
			"artist": "Unknown",
			"bpm": 120,
			"duration": "0:00",
			"audio_file": "",
			"difficulty": extract_difficulty_from_path(path),
			"format": "csv"
		},
		"notes": []
	}

	# Parse CSV lines
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 5:
			continue

		var note = parse_csv_note(line)
		if not note.is_empty():
			chart_data.notes.append(note)

	file.close()

	# Sort notes by time
	chart_data.notes.sort_custom(func(a, b): return a.time < b.time)

	# Calculate duration from last note
	if chart_data.notes.size() > 0:
		var last_time_ms = chart_data.notes[-1].time
		var duration_sec = last_time_ms / 1000
		var minutes = int(duration_sec / 60)
		var seconds = int(duration_sec) % 60
		chart_data.metadata.duration = "%d:%02d" % [minutes, seconds]

	return chart_data

# Parse a single CSV note line
static func parse_csv_note(line: Array) -> Dictionary:
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
	if object_type & 0b00000001:  # Tap note (bit 0)
		note.type = "tap"
	elif object_type & 0b10000000:  # Hold note (bit 7)
		note.type = "hold"
		if line.size() > 5 and line[5] != "":
			var extras = line[5].split(':')
			if extras.size() > 0 and extras[0] != "0":
				var end_time_ms = int(extras[0])
				note["hold_length"] = end_time_ms - time_ms
	elif object_type & 0b00000010:  # Swap note (bit 1)
		note.type = "swap"
		if line.size() > 5 and line[5] != "":
			var extras = line[5].split(':')
			if extras.size() > 0:
				# Convert target x position to track
				var target_x = float(extras[0])
				var target_track = int(floor(target_x * 6.0 / 512.0))
				note["target_track"] = clamp(target_track, 0, 5)

	return note

# Extract difficulty from file path
static func extract_difficulty_from_path(path: String) -> String:
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

# Save chart in JSON format with millisecond timing
static func save_chart(chart_data: Dictionary, output_path: String) -> bool:
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		print("Failed to create file: ", output_path)
		return false

	# Ensure all timings are in milliseconds
	var save_data = chart_data.duplicate(true)
	for note in save_data.notes:
		# Ensure timing is integer milliseconds
		if note.has("time"):
			note.time = int(note.time)
		if note.has("hold_length"):
			note.hold_length = int(note.hold_length)

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("Chart saved to: ", output_path)
	return true

# Convert old seconds-based charts to milliseconds
static func migrate_chart_to_milliseconds(input_path: String, output_path: String = "") -> bool:
	if output_path == "":
		output_path = input_path.get_basename() + "_ms.json"

	var chart = load_chart(input_path)
	if chart.is_empty():
		return false

	# Mark as millisecond format
	if not chart.has("metadata"):
		chart["metadata"] = {}
	chart.metadata["timing_format"] = "milliseconds"

	return save_chart(chart, output_path)