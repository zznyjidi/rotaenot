extends Control

@onready var score_label = $ScoreLabel
@onready var combo_label = $ComboLabel
@onready var accuracy_label = $AccuracyLabel

func _ready():
	pass

func update_score(score: int):
	score_label.text = "Score: " + str(score)

	var tween = get_tree().create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func update_combo(combo: int):
	combo_label.text = "Combo: " + str(combo)

	if combo > 0:
		combo_label.modulate = Color(1, 1, 1, 1)
		if combo >= 50:
			combo_label.modulate = Color.GOLD
		elif combo >= 25:
			combo_label.modulate = Color.YELLOW
		elif combo >= 10:
			combo_label.modulate = Color.GREEN_YELLOW

		var tween = get_tree().create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		combo_label.modulate = Color(0.7, 0.7, 0.7, 1)

func update_accuracy(accuracy: float):
	accuracy_label.text = "Accuracy: %.1f%%" % accuracy

	if accuracy >= 95:
		accuracy_label.modulate = Color.GOLD
	elif accuracy >= 90:
		accuracy_label.modulate = Color.GREEN
	elif accuracy >= 80:
		accuracy_label.modulate = Color.YELLOW
	else:
		accuracy_label.modulate = Color.RED