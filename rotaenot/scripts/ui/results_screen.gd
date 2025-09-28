extends Control

# Results screen for victory or game over

enum ResultType { VICTORY, GAME_OVER }

# UI References
@onready var background = $Background
@onready var result_panel = $CenterContainer/ResultPanel
@onready var result_title = $CenterContainer/ResultPanel/VBoxContainer/ResultTitle
@onready var song_info = $CenterContainer/ResultPanel/VBoxContainer/SongInfo
@onready var score_label = $CenterContainer/ResultPanel/VBoxContainer/StatsContainer/ScoreLabel
@onready var combo_label = $CenterContainer/ResultPanel/VBoxContainer/StatsContainer/ComboLabel
@onready var perfect_label = $CenterContainer/ResultPanel/VBoxContainer/StatsContainer/PerfectLabel
@onready var great_label = $CenterContainer/ResultPanel/VBoxContainer/StatsContainer/GreatLabel
@onready var good_label = $CenterContainer/ResultPanel/VBoxContainer/StatsContainer/GoodLabel
@onready var bad_label = $CenterContainer/ResultPanel/VBoxContainer/StatsContainer/BadLabel
@onready var miss_label = $CenterContainer/ResultPanel/VBoxContainer/StatsContainer/MissLabel
@onready var accuracy_label = $CenterContainer/ResultPanel/VBoxContainer/AccuracyLabel
@onready var rank_label = $CenterContainer/ResultPanel/VBoxContainer/RankLabel
@onready var new_record_label = $CenterContainer/ResultPanel/VBoxContainer/NewRecordLabel
@onready var retry_button = $CenterContainer/ResultPanel/VBoxContainer/ButtonContainer/RetryButton
@onready var menu_button = $CenterContainer/ResultPanel/VBoxContainer/ButtonContainer/MenuButton

var result_type: ResultType
var is_new_record = false

func _ready():
	# Start with fade in
	modulate.a = 0.0

	# Get results from GameData
	var results = GameData.last_game_results if GameData and GameData.last_game_results else {}

	if results.has("result_type"):
		result_type = results.result_type
	else:
		result_type = ResultType.VICTORY

	# Display results
	_display_results(results)

	# Animate entrance
	_animate_entrance()

func _display_results(results: Dictionary):
	# Set title based on result type
	if result_type == ResultType.VICTORY:
		result_title.text = "STAGE CLEAR!"
		result_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		background.color = Color(0.05, 0.1, 0.05, 1)  # Green tint
	else:
		result_title.text = "GAME OVER"
		result_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		background.color = Color(0.1, 0.05, 0.05, 1)  # Red tint

	# Display song info
	if GameData.selected_song:
		var song = GameData.selected_song
		song_info.text = song.title + " - " + song.artist + " [" + GameData.selected_difficulty + "]"

	# Display statistics
	score_label.text = "Score: " + str(results.get("score", 0))
	combo_label.text = "Max Combo: " + str(results.get("max_combo", 0))

	# Display hit counts
	var perfect = results.get("perfect_count", 0)
	var great = results.get("great_count", 0)
	var good = results.get("good_count", 0)
	var bad = results.get("bad_count", 0)
	var miss = results.get("miss_count", 0)

	perfect_label.text = "Perfect: " + str(perfect)
	great_label.text = "Great: " + str(great)
	good_label.text = "Good: " + str(good)
	bad_label.text = "Bad: " + str(bad)
	miss_label.text = "Miss: " + str(miss)

	# Calculate accuracy
	var total_notes = perfect + great + good + bad + miss
	var accuracy = 0.0
	if total_notes > 0:
		var weighted_score = (perfect * 100) + (great * 80) + (good * 50) + (bad * 10)
		accuracy = weighted_score / float(total_notes)

	accuracy_label.text = "Accuracy: " + str(snapped(accuracy, 0.01)) + "%"

	# Calculate rank
	var rank = _calculate_rank(accuracy, result_type)
	rank_label.text = rank
	_style_rank_label(rank)

	# Check for new record
	if GameData.selected_song and result_type == ResultType.VICTORY:
		var song_id = GameData.selected_song.id
		var difficulty = GameData.selected_difficulty
		var score = results.get("score", 0)

		if SongDatabase.update_high_score(song_id, difficulty, score):
			is_new_record = true
			new_record_label.visible = true
			new_record_label.text = "NEW RECORD!"
		else:
			new_record_label.visible = false
	else:
		new_record_label.visible = false

func _calculate_rank(accuracy: float, type: ResultType) -> String:
	if type == ResultType.GAME_OVER:
		return "F"

	if accuracy >= 100.0:
		return "SSS"
	elif accuracy >= 95.0:
		return "SS"
	elif accuracy >= 90.0:
		return "S"
	elif accuracy >= 85.0:
		return "A"
	elif accuracy >= 80.0:
		return "B"
	elif accuracy >= 70.0:
		return "C"
	elif accuracy >= 60.0:
		return "D"
	else:
		return "E"

func _style_rank_label(rank: String):
	var color = Color.WHITE
	var font_size = 48

	match rank:
		"SSS":
			color = Color(1.0, 0.9, 0.1)  # Gold
			font_size = 56
		"SS":
			color = Color(1.0, 0.8, 0.2)  # Yellow
			font_size = 52
		"S":
			color = Color(0.9, 0.9, 0.3)  # Light Yellow
			font_size = 48
		"A":
			color = Color(0.2, 1.0, 0.2)  # Green
		"B":
			color = Color(0.2, 0.8, 1.0)  # Blue
		"C":
			color = Color(0.8, 0.5, 1.0)  # Purple
		"D":
			color = Color(1.0, 0.5, 0.2)  # Orange
		"E":
			color = Color(0.8, 0.3, 0.3)  # Light Red
		"F":
			color = Color(1.0, 0.2, 0.2)  # Red

	rank_label.add_theme_color_override("font_color", color)
	rank_label.add_theme_font_size_override("font_size", font_size)

func _animate_entrance():
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Scale animation for panel
	result_panel.scale = Vector2(0.8, 0.8)
	tween.parallel().tween_property(result_panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Animate rank appearance
	await tween.finished

	if is_new_record:
		_animate_new_record()

	# Pulse rank
	_pulse_rank()

func _pulse_rank():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(rank_label, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(rank_label, "scale", Vector2(1.0, 1.0), 0.5)

func _animate_new_record():
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(new_record_label, "modulate:a", 0.5, 0.2)
	tween.tween_property(new_record_label, "modulate:a", 1.0, 0.2)

func _on_retry_button_pressed():
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Reload gameplay scene
	get_tree().change_scene_to_file("res://scenes/gameplay/gameplay_3d.tscn")

func _on_menu_button_pressed():
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Return to song select
	get_tree().change_scene_to_file("res://scenes/ui/song_select.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_retry_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_menu_button_pressed()
