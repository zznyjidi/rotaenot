extends Node

signal game_started
signal game_paused
signal game_resumed
signal game_ended
signal score_updated(score: int)
signal combo_updated(combo: int)

enum GameState {
	MENU,
	LOADING,
	PLAYING,
	PAUSED,
	RESULTS
}

var current_state: GameState = GameState.MENU
var current_song: Dictionary = {}
var current_chart: Dictionary = {}
var current_score: int = 0
var current_combo: int = 0
var max_combo: int = 0
var note_counts: Dictionary = {
	"perfect": 0,
	"great": 0,
	"good": 0,
	"miss": 0
}

var python_bridge = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_python_bridge()

func _initialize_python_bridge():
	var script_path = "res://python_backend/score_system.py"
	if FileAccess.file_exists(script_path):
		print("Python backend found, initializing...")
	else:
		print("Python backend not found, using GDScript fallback")

func start_game(song_data: Dictionary, chart_data: Dictionary):
	current_song = song_data
	current_chart = chart_data
	current_state = GameState.LOADING
	_reset_game_stats()

	await get_tree().create_timer(0.5).timeout

	current_state = GameState.PLAYING
	game_started.emit()

func pause_game():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()

func resume_game():
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		game_resumed.emit()

func end_game():
	current_state = GameState.RESULTS
	get_tree().paused = false
	game_ended.emit()
	_calculate_final_score()

func process_note_hit(judgment: String, note_value: int = 1000):
	match judgment:
		"perfect":
			note_counts.perfect += 1
			current_combo += 1
			current_score += note_value
		"great":
			note_counts.great += 1
			current_combo += 1
			current_score += int(note_value * 0.8)
		"good":
			note_counts.good += 1
			current_combo += 1
			current_score += int(note_value * 0.5)
		"miss":
			note_counts.miss += 1
			current_combo = 0

	max_combo = max(max_combo, current_combo)
	score_updated.emit(current_score)
	combo_updated.emit(current_combo)

func get_accuracy() -> float:
	var total_notes = note_counts.perfect + note_counts.great + note_counts.good + note_counts.miss
	if total_notes == 0:
		return 100.0

	var weighted_hits = note_counts.perfect * 1.0 + note_counts.great * 0.8 + note_counts.good * 0.5
	return (weighted_hits / total_notes) * 100.0

func get_letter_grade() -> String:
	var accuracy = get_accuracy()

	if accuracy >= 100:
		return "SSS"
	elif accuracy >= 98:
		return "SS"
	elif accuracy >= 95:
		return "S"
	elif accuracy >= 90:
		return "A"
	elif accuracy >= 80:
		return "B"
	elif accuracy >= 70:
		return "C"
	else:
		return "D"

func _reset_game_stats():
	current_score = 0
	current_combo = 0
	max_combo = 0
	note_counts = {
		"perfect": 0,
		"great": 0,
		"good": 0,
		"miss": 0
	}

func _calculate_final_score():
	var final_data = {
		"score": current_score,
		"accuracy": get_accuracy(),
		"grade": get_letter_grade(),
		"max_combo": max_combo,
		"perfect": note_counts.perfect,
		"great": note_counts.great,
		"good": note_counts.good,
		"miss": note_counts.miss,
		"full_combo": note_counts.miss == 0
	}

	print("Final Score: ", final_data)