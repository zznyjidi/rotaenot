extends Node

var python_script_path = "res://python_backend/"
var python_executable = "python3"

var chart_parser_process: Process
var score_calculator_process: Process
var gyro_processor_process: Process

func _ready():
	_check_python_availability()

func _check_python_availability():
	var output = []
	var exit_code = OS.execute(python_executable, ["--version"], output, true)

	if exit_code == 0:
		print("Python found: ", output[0])
		return true
	else:
		print("Python not found, some features will be unavailable")
		return false

func parse_chart(chart_file: String) -> Dictionary:
	var script_path = python_script_path + "chart_parser.py"
	var output = []

	var args = [script_path, "parse", chart_file]
	var exit_code = OS.execute(python_executable, args, output, true)

	if exit_code == 0:
		var json = JSON.new()
		var parse_result = json.parse(output[0])
		if parse_result == OK:
			return json.data
	else:
		print("Failed to parse chart: ", output)

	return {}

func calculate_score(note_data: Dictionary) -> Dictionary:
	var script_path = python_script_path + "score_system.py"
	var output = []

	var args = [script_path, "calculate", JSON.stringify(note_data)]
	var exit_code = OS.execute(python_executable, args, output, true)

	if exit_code == 0:
		var json = JSON.new()
		var parse_result = json.parse(output[0])
		if parse_result == OK:
			return json.data
	else:
		print("Failed to calculate score: ", output)

	return {}

func process_gyro_data(gyro_data: Dictionary) -> Dictionary:
	var script_path = python_script_path + "gyro_processor.py"
	var output = []

	var args = [script_path, "process", JSON.stringify(gyro_data)]
	var exit_code = OS.execute(python_executable, args, output, true)

	if exit_code == 0:
		var json = JSON.new()
		var parse_result = json.parse(output[0])
		if parse_result == OK:
			return json.data
	else:
		print("Failed to process gyro data: ", output)

	return {}

func generate_test_chart(duration: float, difficulty: int) -> Dictionary:
	var script_path = python_script_path + "chart_parser.py"
	var output = []

	var args = [script_path, "generate", str(duration), str(difficulty)]
	var exit_code = OS.execute(python_executable, args, output, true)

	if exit_code == 0:
		var json = JSON.new()
		var parse_result = json.parse(output[0])
		if parse_result == OK:
			return json.data
	else:
		print("Failed to generate chart: ", output)

	return _generate_fallback_chart(duration, difficulty)

func _generate_fallback_chart(duration: float, difficulty: int) -> Dictionary:
	var chart = {
		"title": "Test Chart",
		"artist": "Unknown",
		"bpm": 120,
		"difficulty": difficulty,
		"audio_file": "",
		"notes": []
	}

	var note_density = 2.0 + (difficulty * 0.5)
	var total_notes = int(duration * note_density)

	for i in range(total_notes):
		var time = i / note_density
		var angle = fmod(i * 45, 360)

		var note = {
			"time": time,
			"position": angle,
			"type": "tap"
		}

		if difficulty > 5 and i % 7 == 0:
			note["type"] = "flick"
		elif difficulty > 3 and i % 5 == 0:
			note["type"] = "catch"
		elif difficulty > 7 and i % 11 == 0:
			note["type"] = "hold"
			note["duration"] = 0.5

		chart["notes"].append(note)

	return chart