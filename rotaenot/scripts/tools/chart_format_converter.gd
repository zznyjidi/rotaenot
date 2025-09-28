extends Node

# Chart Format Converter
# Converts between different chart formats (JSON <-> CSV/OSU)

class_name ChartFormatConverter

# Convert JSON chart to CSV format (OSU-like)
static func json_to_csv(json_path: String, output_path: String) -> bool:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("Failed to open JSON file: ", json_path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Failed to parse JSON: ", json.get_error_message())
		return false

	var chart_data = json.data
	if not chart_data.has("notes"):
		print("No notes found in chart")
		return false

	# Create CSV output
	var csv_file = FileAccess.open(output_path, FileAccess.WRITE)
	if not csv_file:
		print("Failed to create CSV file: ", output_path)
		return false

	# Convert each note
	for note in chart_data.notes:
		var csv_line = convert_note_to_csv(note)
		csv_file.store_line(csv_line)

	csv_file.close()
	print("Successfully converted JSON to CSV: ", output_path)
	return true

# Convert a single note from JSON format to CSV format
static func convert_note_to_csv(note: Dictionary) -> String:
	# Calculate x position from track (0-5 -> 0-512 range)
	var x_position = int((note.track * 512.0) / 6.0) + 42  # Add offset to center
	var y_position = 192  # Standard y position
	var time_ms = int(note.time * 1000)  # Convert seconds to milliseconds
	var note_type = 1  # Default to tap note

	# Determine note type
	if note.has("type"):
		match note.type:
			"tap":
				note_type = 1
			"hold":
				note_type = 128
			"swap":
				note_type = 2

	# Build extras field for hold notes
	var extras = "0:0:0:0:"
	if note.has("hold_length"):
		var end_time = time_ms + int(note.hold_length * 1000)
		extras = str(end_time) + ":0:0:0:"
	elif note.has("target_track"):
		extras = str(note.target_track) + ":0:0:0:"

	# Format: x,y,time,type,hitsound,extras
	return "%d,%d,%d,%d,0,%s" % [x_position, y_position, time_ms, note_type, extras]

# Convert CSV/OSU format to JSON format
static func csv_to_json(csv_path: String, output_path: String) -> bool:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		print("Failed to open CSV file: ", csv_path)
		return false

	var chart_data = {
		"metadata": {
			"title": csv_path.get_file().get_basename(),
			"artist": "Unknown",
			"bpm": 120,
			"duration": "0:00",
			"audio_file": "",
			"difficulty": "Normal"
		},
		"notes": []
	}

	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 5:
			continue

		var note = convert_csv_to_note(line)
		if note:
			chart_data.notes.append(note)

	file.close()

	# Sort notes by time
	chart_data.notes.sort_custom(func(a, b): return a.time < b.time)

	# Save as JSON
	var json_file = FileAccess.open(output_path, FileAccess.WRITE)
	if not json_file:
		print("Failed to create JSON file: ", output_path)
		return false

	json_file.store_string(JSON.stringify(chart_data, "\t"))
	json_file.close()
	print("Successfully converted CSV to JSON: ", output_path)
	return true

# Convert a single CSV line to JSON note format
static func convert_csv_to_note(line: Array) -> Dictionary:
	if line.size() < 5:
		return {}

	var x_position = float(line[0])
	var time_ms = int(line[2])
	var object_type = int(line[3])

	# Convert x position (0-512) to track (0-5)
	var track = floor(x_position * 6.0 / 512.0)
	track = clamp(track, 0, 5)

	# Convert time from milliseconds to seconds
	var time_sec = time_ms / 1000.0

	var note = {
		"time": time_sec,
		"track": int(track),
		"type": "tap"  # Default
	}

	# Determine note type from object_type bitfield
	if object_type & 0b00000001:  # Tap note
		note.type = "tap"
	elif object_type & 0b10000000:  # Hold note
		note.type = "hold"
		if line.size() > 5:
			var extras = line[5].split(':')
			if extras.size() > 0:
				var end_time_ms = int(extras[0])
				var hold_length_sec = (end_time_ms - time_ms) / 1000.0
				note["hold_length"] = hold_length_sec
	elif object_type & 0b00000010:  # Swap note
		note.type = "swap"
		if line.size() > 5:
			var extras = line[5].split(':')
			if extras.size() > 0:
				note["target_track"] = int(extras[0])

	return note

# Integrate friend's judgment system with your game
static func create_judgment_adapter() -> Node:
	# This would create an adapter node that translates between the two systems
# Note: Use UniversalChartLoader for loading both formats
	var adapter = Node.new()
	adapter.name = "JudgmentAdapter"

	# Add script to handle the conversion
	adapter.set_script(preload("res://scripts/tools/judgment_adapter.gd"))

	return adapter