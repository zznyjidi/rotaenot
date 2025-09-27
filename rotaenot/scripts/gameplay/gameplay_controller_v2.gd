extends Node2D

@onready var playfield = $PlayfieldContainer/RotatingPlayfield
@onready var note_spawner = $PlayfieldContainer/RotatingPlayfield/NoteSpawner
@onready var note_container = $PlayfieldContainer/RotatingPlayfield/NoteContainer
@onready var hud = $HUD
@onready var pause_menu = $HUD/PauseMenu
@onready var rotation_label = $HUD/RotationLabel
@onready var judgment_circle = $PlayfieldContainer/StaticElements/JudgmentCircle
@onready var inner_circle = $PlayfieldContainer/StaticElements/InnerCircle

var game_manager
var is_paused = false
var score = 0
var combo = 0
var max_combo = 0
var total_notes = 0
var hit_notes = 0

func _ready():
	# Initialize circles
	_setup_circles()

	# Initialize game manager
	game_manager = load("res://scripts/core/game_manager.gd").new()
	add_child(game_manager)

	# Connect signals
	if game_manager.has_signal("score_updated"):
		game_manager.score_updated.connect(_on_score_updated)
	if game_manager.has_signal("combo_updated"):
		game_manager.combo_updated.connect(_on_combo_updated)

	if playfield.has_signal("rotation_changed"):
		playfield.rotation_changed.connect(_on_rotation_changed)

	# Start demo after a short delay
	await get_tree().create_timer(0.1).timeout
	_start_demo()

func _setup_circles():
	var points_judgment = []
	var points_inner = []
	var segments = 64
	var judgment_radius = 300.0
	var inner_radius = 50.0

	for i in range(segments + 1):
		var angle = (TAU * i) / segments

		var judgment_point = Vector2(
			cos(angle) * judgment_radius,
			sin(angle) * judgment_radius
		)
		points_judgment.append(judgment_point)

		var inner_point = Vector2(
			cos(angle) * inner_radius,
			sin(angle) * inner_radius
		)
		points_inner.append(inner_point)

	judgment_circle.points = points_judgment
	inner_circle.points = points_inner

func _start_demo():
	print("Starting improved demo gameplay...")

	var demo_chart = {
		"title": "Demo Song",
		"bpm": 120,
		"difficulty": 5
	}

	game_manager.start_game({}, demo_chart)

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
	var notes = note_container.get_children()
	var best_note = null
	var best_score = -1

	for note in notes:
		if not note.has_method("get_distance_to_judgment"):
			continue

		var dist = note.get_distance_to_judgment()

		# Skip notes too far from judgment
		if dist > 60:
			continue

		# Calculate hit score (closer = better)
		var distance_score = max(0, 60 - dist) / 60.0

		# Check if note is in correct position for its type
		var position_score = 1.0
		if note.note_type == 2:  # CATCH note
			if not playfield.is_in_hit_zone(note.position_angle, "bottom"):
				continue  # Can't hit catch notes outside bottom zone
		else:  # TAP note
			if not playfield.is_in_hit_zone(note.position_angle, "top"):
				continue  # Can't hit tap notes outside top zone

		var total_score = distance_score * position_score

		if total_score > best_score:
			best_score = total_score
			best_note = note

	if best_note and best_note.has_method("try_hit"):
		var judgment = best_note.try_hit()
		if judgment != "" and judgment != "miss":
			game_manager.process_note_hit(judgment)
			_show_judgment(judgment)
			hit_notes += 1
		elif judgment == "miss":
			_show_judgment("miss")

	total_notes = hit_notes + game_manager.note_counts.miss

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

func _on_rotation_changed(angle: float):
	rotation_label.text = "Rotation: %d°" % int(angle)

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