extends Area2D

class_name NoteBase

signal note_hit(judgment: String)
signal note_missed

enum NoteType {
	TAP,
	HOLD,
	CATCH,
	FLICK,
	ROTATION
}

@export var note_type: NoteType = NoteType.TAP
@export var hit_time: float = 0.0
@export var position_angle: float = 0.0
@export var note_speed: float = 200.0

var spawn_time: float
var spawn_distance: float = 400.0
var judgment_radius: float = 320.0
var is_active: bool = true
var was_hit: bool = false

var perfect_window: float = 0.04
var great_window: float = 0.08
var good_window: float = 0.12

func _ready():
	spawn_time = Time.get_ticks_msec() / 1000.0
	_setup_note()
	area_entered.connect(_on_area_entered)

func _setup_note():
	var angle_rad = deg_to_rad(position_angle)
	position = Vector2(
		cos(angle_rad) * spawn_distance,
		sin(angle_rad) * spawn_distance
	)

	look_at(Vector2.ZERO, Vector2.UP)

	match note_type:
		NoteType.TAP:
			modulate = Color.CYAN
		NoteType.HOLD:
			modulate = Color.GREEN
		NoteType.CATCH:
			modulate = Color.YELLOW
		NoteType.FLICK:
			modulate = Color.MAGENTA
		NoteType.ROTATION:
			modulate = Color.ORANGE

func _process(delta):
	if not is_active:
		return

	var direction = -position.normalized()
	position += direction * note_speed * delta

	var distance_to_center = position.length()

	if distance_to_center <= judgment_radius:
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_difference = abs(current_time - hit_time)

		if not was_hit and time_difference > good_window:
			_on_miss()

	if distance_to_center < 50:
		queue_free()

func try_hit() -> String:
	if not is_active or was_hit:
		return ""

	var current_time = Time.get_ticks_msec() / 1000.0
	var time_difference = abs(current_time - hit_time)

	var judgment = ""

	if time_difference <= perfect_window:
		judgment = "perfect"
	elif time_difference <= great_window:
		judgment = "great"
	elif time_difference <= good_window:
		judgment = "good"
	else:
		judgment = "miss"

	if judgment != "miss":
		was_hit = true
		is_active = false
		note_hit.emit(judgment)
		_play_hit_effect(judgment)
		queue_free()
	else:
		_on_miss()

	return judgment

func _on_miss():
	if was_hit:
		return

	was_hit = true
	is_active = false
	note_missed.emit()
	modulate = Color.RED
	modulate.a = 0.5

	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _play_hit_effect(judgment: String):
	var effect_color = Color.WHITE

	match judgment:
		"perfect":
			effect_color = Color.GOLD
			scale = Vector2(1.5, 1.5)
		"great":
			effect_color = Color.GREEN
			scale = Vector2(1.3, 1.3)
		"good":
			effect_color = Color.BLUE
			scale = Vector2(1.1, 1.1)

	modulate = effect_color

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2, 2), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _on_area_entered(area):
	pass