extends Node2D

signal rotation_changed(angle: float)

var current_rotation: float = 0.0
var target_rotation: float = 0.0
var rotation_speed: float = 5.0
var smoothing_factor: float = 0.2

var mouse_control: bool = true
var judgment_radius: float = 300.0

func _ready():
	_setup_visuals()

func _setup_visuals():
	# Setup is done in the parent scene now
	pass

func _process(delta):
	_handle_input(delta)

	# Smooth rotation
	current_rotation = lerp_angle(current_rotation, target_rotation, smoothing_factor)
	rotation = current_rotation

	# Emit rotation in degrees for UI
	rotation_changed.emit(rad_to_deg(current_rotation))

func _handle_input(delta):
	if mouse_control:
		_handle_mouse_rotation()

	_handle_keyboard_rotation(delta)

func _handle_mouse_rotation():
	var mouse_pos = get_global_mouse_position()
	var center = get_viewport().get_visible_rect().size / 2
	var angle_to_mouse = (mouse_pos - center).angle()
	# Adjust for top-facing orientation
	target_rotation = angle_to_mouse + PI/2

func _handle_keyboard_rotation(delta):
	var rotation_input = 0.0

	if Input.is_action_pressed("rotate_left"):
		rotation_input -= 1.0
	if Input.is_action_pressed("rotate_right"):
		rotation_input += 1.0

	if rotation_input != 0:
		target_rotation += rotation_input * rotation_speed * delta
		mouse_control = false
	elif Input.is_action_just_released("rotate_left") or Input.is_action_just_released("rotate_right"):
		# Re-enable mouse control when keyboard rotation stops
		await get_tree().create_timer(0.1).timeout
		mouse_control = true

func get_rotation_deg() -> float:
	return rad_to_deg(current_rotation)

func get_judgment_radius() -> float:
	return judgment_radius

func is_in_hit_zone(note_angle: float, zone: String) -> bool:
	"""Check if a note at given angle is in the specified hit zone"""
	var current_deg = rad_to_deg(current_rotation)
	var note_deg = note_angle

	# Normalize angles
	while current_deg < 0:
		current_deg += 360
	while current_deg >= 360:
		current_deg -= 360

	# Calculate relative position of note
	var relative_angle = note_deg - current_deg
	while relative_angle < -180:
		relative_angle += 360
	while relative_angle > 180:
		relative_angle -= 360

	# Check if in hit zone
	match zone:
		"top":  # Green zone - regular tap notes
			return abs(relative_angle) < 30  # ±30 degrees from top
		"bottom":  # Orange zone - catch notes
			var bottom_diff = abs(relative_angle - 180)
			var bottom_diff_alt = abs(relative_angle + 180)
			return min(bottom_diff, bottom_diff_alt) < 30  # ±30 degrees from bottom
		_:
			return false