extends Control

@onready var score_label = $CenterDisplay/ScoreLabel
@onready var combo_label = $CenterDisplay/ComboLabel
@onready var life_label = $CenterDisplay/LifeLabel
@onready var miss_label = $CenterDisplay/MissLabel
@onready var judgment_label = $JudgmentLabel

var current_life: int = 100
var miss_count: int = 0

func _ready():
	# Add key hints for each pad
	_create_key_hints()

func _create_key_hints():
	var key_hints_container = $KeyHints

	# Pad positions (approximate screen positions)
	var hint_positions = [
		{"key": "Q", "pos": Vector2(320, 200)},   # Left top
		{"key": "A", "pos": Vector2(280, 360)},   # Left mid
		{"key": "Z", "pos": Vector2(320, 520)},   # Left bot
		{"key": "P", "pos": Vector2(960, 200)},   # Right top
		{"key": "L", "pos": Vector2(1000, 360)},  # Right mid
		{"key": "M", "pos": Vector2(960, 520)}    # Right bot
	]

	for hint in hint_positions:
		var hint_label = Label.new()
		hint_label.text = "[" + hint.key + "]"
		hint_label.add_theme_font_size_override("font_size", 16)
		hint_label.modulate = Color(0.7, 0.7, 0.7, 0.5)
		hint_label.position = hint.pos
		key_hints_container.add_child(hint_label)

func update_score(score: int):
	if score_label:
		score_label.text = "SCORE: " + str(score)

		# Pulse effect
		var tween = get_tree().create_tween()
		tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func update_life(life: int):
	current_life = life
	if life_label:
		life_label.text = "LIFE: " + str(life) + "%"

		# Color based on life
		if life > 60:
			life_label.modulate = Color.GREEN
		elif life > 30:
			life_label.modulate = Color.YELLOW
		else:
			life_label.modulate = Color.RED

func update_miss(misses: int):
	miss_count = misses
	if miss_label:
		miss_label.text = "MISS: " + str(misses)

		# Flash red on new miss
		if misses > 0:
			miss_label.modulate = Color.RED
			var tween = get_tree().create_tween()
			tween.tween_property(miss_label, "modulate", Color.WHITE, 0.3)

func update_combo(combo: int):
	if combo_label:
		if combo > 0:
			combo_label.text = "COMBO: " + str(combo)
			combo_label.visible = true

			# Color based on combo
			if combo >= 50:
				combo_label.modulate = Color.GOLD
			elif combo >= 25:
				combo_label.modulate = Color.YELLOW
			elif combo >= 10:
				combo_label.modulate = Color.GREEN
			else:
				combo_label.modulate = Color.WHITE

			# Pulse effect
			var tween = get_tree().create_tween()
			tween.tween_property(combo_label, "scale", Vector2(1.1, 1.1), 0.05)
			tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.05)
		else:
			combo_label.text = ""

func show_judgment(judgment: String):
	if not judgment_label:
		return

	judgment_label.text = judgment
	judgment_label.visible = true

	# Set color based on judgment
	match judgment:
		"PERFECT":
			judgment_label.modulate = Color.GOLD
		"GREAT":
			judgment_label.modulate = Color.GREEN
		"GOOD":
			judgment_label.modulate = Color.CYAN
		"BAD":
			judgment_label.modulate = Color.ORANGE
		"MISS":
			judgment_label.modulate = Color.RED
		_:
			judgment_label.modulate = Color.WHITE

	# Animate
	var tween = get_tree().create_tween()
	tween.tween_property(judgment_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.parallel().tween_property(judgment_label, "modulate:a", 1.0, 0.1)
	tween.tween_property(judgment_label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(judgment_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_hide_judgment)

func _hide_judgment():
	if judgment_label:
		judgment_label.visible = false
