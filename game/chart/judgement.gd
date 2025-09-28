extends Node

var track_status: Array[bool] = [false, false, false, false, false, false]
var key_track_map: Array[int] = [1, 2, 3, 4, 5, 6]
var frame_count: int = 0

signal key_status_updated(frame: int, track_status: Array[bool])

func _ready() -> void:
	frame_count = 0

func frame() -> void:
	var key_status = [
		Input.is_action_pressed('gameplay.left_top'),
		Input.is_action_pressed('gameplay.left_middle'),
		Input.is_action_pressed('gameplay.left_bottom'),
		Input.is_action_pressed('gameplay.right_top'),
		Input.is_action_pressed('gameplay.right_middle'),
		Input.is_action_pressed('gameplay.right_bottom'),
	]
	
	for key_index in range(key_status.size()):
		track_status[key_track_map[key_index] - 1] = key_status[key_index]
	
	frame_count += 1
	key_status_updated.emit(frame_count - 1, track_status)

func swap(track1: int, track2: int) -> void:
	var track1_prev = key_track_map[track1 - 1]
	key_track_map[track1 - 1] = key_track_map[track2 - 1]
	key_track_map[track2 - 1] = track1_prev
