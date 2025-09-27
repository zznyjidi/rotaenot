extends Node2D

@onready var playfield = $Playfield
@onready var note_spawner = $Playfield/NoteSpawner
@onready var hud = $HUD
@onready var pause_menu = $HUD/PauseMenu

var game_manager
var is_paused = false
var score = 0
var combo = 0
var max_combo = 0
var total_notes = 0
var hit_notes = 0

func _ready():
	# Initialize game manager
	game_manager = load("res://scripts/core/game_manager.gd").new()
	add_child(game_manager)

	# Connect signals if they exist
	if game_manager.has_signal("score_updated"):
		game_manager.score_updated.connect(_on_score_updated)
	if game_manager.has_signal("combo_updated"):
		game_manager.combo_updated.connect(_on_combo_updated)

	# Start demo after a short delay to ensure everything is loaded
	await get_tree().create_timer(0.1).timeout
	_start_demo()

func _start_demo():
	print("Starting demo gameplay...")

	var demo_chart = {
		"title": "Demo Song",
		"bpm": 120,
		"difficulty": 5
	}

	game_manager.start_game({}, demo_chart)

	# Make sure note_spawner exists before calling
	if note_spawner and note_spawner.has_method("start_spawning"):
		note_spawner.start_spawning()
	else:
		print("Note spawner not ready")

func _input(event):
	if event.is_action_pressed("pause_game"):
		toggle_pause()
	elif event.is_action_pressed("tap_note") and not is_paused:
		_try_hit_notes()

func toggle_pause():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused

	if is_paused:
		game_manager.pause_game()
	else:
		game_manager.resume_game()

func _try_hit_notes():
	var notes = get_tree().get_nodes_in_group("notes")
	var closest_note = null
	var min_distance = 999999

	for note in notes:
		if note.has_method("get_distance_to_judgment"):
			var dist = note.get_distance_to_judgment()
			if dist < min_distance:
				min_distance = dist
				closest_note = note

	if closest_note and closest_note.has_method("try_hit"):
		var judgment = closest_note.try_hit()
		if judgment != "":
			game_manager.process_note_hit(judgment)
			_show_judgment(judgment)

func _show_judgment(judgment: String):
	var judgment_label = $HUD/JudgmentLabel

	match judgment:
		"perfect":
			judgment_label.text = "PERFECT!"
			judgment_label.modulate = Color.GOLD
		"great":
			judgment_label.text = "GREAT!"
			judgment_label.modulate = Color.GREEN
		"good":
			judgment_label.text = "GOOD"
			judgment_label.modulate = Color.CYAN
		"miss":
			judgment_label.text = "MISS"
			judgment_label.modulate = Color.RED

	judgment_label.visible = true

	var tween = get_tree().create_tween()
	tween.tween_property(judgment_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): judgment_label.visible = false; judgment_label.modulate.a = 1.0)

func _on_score_updated(new_score: int):
	score = new_score
	hud.update_score(score)

func _on_combo_updated(new_combo: int):
	combo = new_combo
	max_combo = max(max_combo, combo)
	hud.update_combo(combo)

	if total_notes > 0:
		var accuracy = (float(hit_notes) / float(total_notes)) * 100.0
		hud.update_accuracy(accuracy)

func _on_resume_pressed():
	toggle_pause()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")