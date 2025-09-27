extends Area2D

enum NoteType {
	TAP,
	HOLD,
	CATCH,
	FLICK,
	ROTATION
}

@export var note_type: NoteType = NoteType.TAP
@export var position_angle: float = 0.0
@export var note_speed: float = 200.0

var spawn_distance: float = 400.0
var judgment_radius: float = 300.0
var is_active: bool = true
var was_hit: bool = false
var current_distance: float

var perfect_window: float = 40.0  # pixels
var great_window: float = 80.0
var good_window: float = 120.0

func _ready():
	# Initialize position
	current_distance = spawn_distance

	# Set initial position based on angle
	var angle_rad = deg_to_rad(position_angle)
	position = Vector2(
		cos(angle_rad) * current_distance,
		sin(angle_rad) * current_distance
	)

	_setup_visual()

func _setup_visual():
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

	current_distance -= note_speed * delta

	var angle_rad = deg_to_rad(position_angle)
	position = Vector2(
		cos(angle_rad) * current_distance,
		sin(angle_rad) * current_distance
	)

	if current_distance < 50:
		if not was_hit:
			_on_miss()
		else:
			queue_free()

	var scale_factor = 0.5 + (spawn_distance - current_distance) / spawn_distance * 0.5
	scale = Vector2(scale_factor, scale_factor)

func get_distance_to_judgment() -> float:
	return abs(current_distance - judgment_radius)

func try_hit() -> String:
	if not is_active or was_hit:
		return ""

	var distance = get_distance_to_judgment()
	var judgment = ""

	if distance <= perfect_window:
		judgment = "perfect"
	elif distance <= great_window:
		judgment = "great"
	elif distance <= good_window:
		judgment = "good"
	else:
		return ""

	was_hit = true
	is_active = false
	_play_hit_effect(judgment)

	return judgment

func _on_miss():
	if was_hit:
		return

	was_hit = true
	is_active = false
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
		"great":
			effect_color = Color.GREEN
		"good":
			effect_color = Color.BLUE

	modulate = effect_color

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 2, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain()
	tween.tween_callback(queue_free)