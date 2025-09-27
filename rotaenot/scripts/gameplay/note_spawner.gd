extends Node2D

@export var note_scene: PackedScene
@export var spawn_rate: float = 1.0
@export var note_speed: float = 200.0

var spawn_timer: Timer
var is_spawning: bool = false
var demo_pattern_index: int = 0

var demo_patterns = [
	{"angle": 0, "type": "tap"},
	{"angle": 45, "type": "tap"},
	{"angle": 90, "type": "catch"},
	{"angle": 135, "type": "tap"},
	{"angle": 180, "type": "tap"},
	{"angle": 225, "type": "tap"},
	{"angle": 270, "type": "catch"},
	{"angle": 315, "type": "tap"},
	{"angle": 30, "type": "tap"},
	{"angle": 60, "type": "tap"},
	{"angle": 120, "type": "tap"},
	{"angle": 150, "type": "tap"},
	{"angle": 210, "type": "tap"},
	{"angle": 240, "type": "tap"},
	{"angle": 300, "type": "tap"},
	{"angle": 330, "type": "tap"},
]

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0 / spawn_rate
	spawn_timer.timeout.connect(_spawn_note)
	add_child(spawn_timer)

func start_spawning():
	is_spawning = true
	spawn_timer.start()
	print("Note spawning started")

func stop_spawning():
	is_spawning = false
	spawn_timer.stop()

func _spawn_note():
	if not is_spawning or not note_scene:
		return

	var pattern = demo_patterns[demo_pattern_index]
	demo_pattern_index = (demo_pattern_index + 1) % demo_patterns.size()

	var note = note_scene.instantiate()
	note.position_angle = pattern.angle
	note.note_speed = note_speed

	match pattern.type:
		"tap":
			note.note_type = 0  # NoteType.TAP
		"catch":
			note.note_type = 2  # NoteType.CATCH

	get_parent().get_node("NoteContainer").add_child(note)
	note.add_to_group("notes")

	spawn_timer.wait_time = randf_range(0.5, 1.5)