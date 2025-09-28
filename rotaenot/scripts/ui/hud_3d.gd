extends Control

@onready var score_label = $TopDisplay/ScoreLabel
@onready var combo_label = $ComboLabel  # Now separate, shown in center
@onready var life_label = $TopDisplay/LifeLabel
@onready var miss_label = $MissLabel  # Hidden by default
@onready var judgment_label = $JudgmentLabel

var current_life: int = 100
var miss_count: int = 0
var judgment_original_y: float = 0.0

func _ready():
	# Simple HUD with just score and life at the top
	# Set high z_index to appear above playfield elements
	z_index = 50

	# Store original judgment label position
	if judgment_label:
		judgment_original_y = 100.0  # 50px more down
		# Reset position to ensure proper centering
		judgment_label.position = Vector2(540, judgment_original_y)  # 100px to the left of center
		judgment_label.z_index = 100  # Even higher for judgment popups

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
			combo_label.visible = false

func show_judgment(judgment: String):
	if not judgment_label:
		return

	# Kill any existing tween on the judgment label
	if judgment_label.has_meta("tween"):
		var old_tween = judgment_label.get_meta("tween")
		if old_tween and is_instance_valid(old_tween):
			old_tween.kill()

	judgment_label.text = judgment
	judgment_label.visible = true
	judgment_label.z_index = 100  # Ensure it's on top
	judgment_label.scale = Vector2(0.8, 0.8)  # Start smaller
	judgment_label.modulate.a = 0.0  # Start transparent

	# Set color and size based on judgment
	var target_color = Color.WHITE
	var font_size = 36

	match judgment:
		"PERFECT":
			target_color = Color(1.0, 0.9, 0.1)  # Gold
			font_size = 42
			judgment_label.text = "PERFECT!"
		"GREAT":
			target_color = Color(0.2, 1.0, 0.3)  # Bright green
			font_size = 40
			judgment_label.text = "GREAT!"
		"GOOD":
			target_color = Color(0.3, 0.8, 1.0)  # Bright cyan
			font_size = 36
			judgment_label.text = "GOOD"
		"BAD":
			target_color = Color(1.0, 0.6, 0.2)  # Orange
			font_size = 34
			judgment_label.text = "BAD"
		"MISS":
			target_color = Color(1.0, 0.2, 0.2)  # Red
			font_size = 38
			judgment_label.text = "MISS"
		_:
			target_color = Color.WHITE

	judgment_label.add_theme_font_size_override("font_size", font_size)
	judgment_label.modulate = target_color
	judgment_label.modulate.a = 0.0

	# Create more dynamic animation
	var tween = get_tree().create_tween()
	judgment_label.set_meta("tween", tween)

	# Pop in effect
	tween.set_parallel(true)
	tween.tween_property(judgment_label, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(judgment_label, "modulate:a", 1.0, 0.1)

	# Hold and shrink
	tween.set_parallel(false)
	tween.tween_property(judgment_label, "scale", Vector2(0.9, 0.9), 0.1)

	# Fade out with slight upward movement
	tween.set_parallel(true)
	tween.tween_property(judgment_label, "modulate:a", 0.0, 0.4)
	tween.tween_property(judgment_label, "position", Vector2(540, judgment_original_y - 30), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.set_parallel(false)
	tween.tween_callback(_hide_judgment)

func _hide_judgment():
	if judgment_label:
		judgment_label.visible = false
		# Reset position for next judgment
		judgment_label.position = Vector2(540, judgment_original_y)  # Keep at 540
