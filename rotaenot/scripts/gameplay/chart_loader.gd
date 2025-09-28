extends Node

class_name ChartLoader

# Chart data structure
var metadata: Dictionary = {}
var notes: Array = []
var current_note_index: int = 0
var is_loaded: bool = false

func load_chart(chart_path: String) -> bool:
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
	current_note_index = 0
	is_loaded = true

	print("Chart loaded: ", metadata.get("title", "Unknown"))
	print("Total notes: ", notes.size())

	# Sort notes by time to ensure proper order
	notes.sort_custom(_sort_notes_by_time)

	return true

func _sort_notes_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a.get("time", 0.0) < b.get("time", 0.0)

func get_next_note_time() -> float:
	if not is_loaded or current_note_index >= notes.size():
		return -1.0

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
	return metadata.get("offset", 0.0)

func get_title() -> String:
	return metadata.get("title", "Unknown")

func get_difficulty() -> String:
	return metadata.get("difficulty", "Normal")
