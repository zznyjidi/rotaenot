extends Node2D

var target_pad: int = 0
var track_index: int = 0  # Which track pair this note uses
var progress: float = 0.0
var speed: float = 0.5  # Progress per second - FASTER

# Store the two track lines for this note
var top_track_points: PackedVector2Array
var bottom_track_points: PackedVector2Array

# Track switching variables
var is_switching: bool = false
var switch_start_progress: float = 0.45  # Start switch at 45% progress
var switch_duration: float = 0.15  # Shorter, snappier switch
var switch_progress: float = 0.0
var original_pad: int = 0
var new_pad: int = -1  # -1 means no switch planned
var original_top_track: PackedVector2Array
var original_bottom_track: PackedVector2Array
var new_top_track: PackedVector2Array
var new_bottom_track: PackedVector2Array

# Jelly effect variables
var jelly_amplitude: float = 0.0
var jelly_frequency: float = 8.0  # Lower frequency for subtler wobble
var jelly_decay: float = 20.0  # Much faster decay (stops in ~0.1-0.15s)
var jelly_time: float = 0.0
var jelly_duration: float = 0.1  # Max duration for effect

# Textures for notes
var note_textures = [
	preload("res://assets_textures_notes_Node_1.png"),
	preload("res://assets_textures_notes_Node_2.png"),
	preload("res://assets_textures_notes_Node_3.png")
]

func _ready():
	set_meta("target_pad", target_pad)

	# Set z-index so notes appear below the center mask
	z_index = 0  # Notes at base level

	# Create visual using Polygon2D with texture
	var visual = $Visual if has_node("Visual") else null
	if not visual:
		visual = Polygon2D.new()
		visual.name = "Visual"
		# Pick a random texture and apply it
		visual.texture = note_textures[randi() % note_textures.size()]
		visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		add_child(visual)

	set_meta("visual", visual)

func setup(pad_index: int, track_idx: int, top_points: PackedVector2Array, bottom_points: PackedVector2Array):
	target_pad = pad_index
	original_pad = pad_index
	track_index = track_idx
	top_track_points = top_points
	bottom_track_points = bottom_points
	set_meta("target_pad", target_pad)

func set_track_switch(target_pad_index: int):
	# Set up a track switch to the specified pad
	if target_pad_index != original_pad:
		new_pad = target_pad_index

func _process(delta):
	if top_track_points.size() < 2 or bottom_track_points.size() < 2:
		return

	# Move along track
	progress += speed * delta

	# Check if we should start switching
	if not is_switching and new_pad >= 0 and progress >= switch_start_progress:
		_initiate_track_switch()

	# Handle track switching animation
	if is_switching:
		switch_progress += delta / switch_duration
		if switch_progress >= 1.0:
			# Complete the switch
			switch_progress = 1.0
			is_switching = false
			target_pad = new_pad
			set_meta("target_pad", target_pad)
			# Update the track points to the new ones
			top_track_points = new_top_track
			bottom_track_points = new_bottom_track

	# Update jelly effect
	if jelly_amplitude > 0.01 and jelly_time < jelly_duration:
		jelly_time += delta
		jelly_amplitude *= exp(-jelly_decay * delta)  # Exponential decay
	else:
		jelly_amplitude = 0.0

	# Continue past the pad for gradual disappearance
	if progress >= 1.5:  # Go 50% past the pad before removing
		queue_free()
		return

	# Update position and visual
	_update_visual_from_tracks()

func _update_visual_from_tracks():
	var visual = get_meta("visual") as Polygon2D
	if not visual:
		return

	# Clamp progress for position calculation
	var pos_progress = min(progress, 1.0)

	# Get the actual track points to use (interpolated if switching)
	var current_top_track = top_track_points
	var current_bottom_track = bottom_track_points

	if is_switching and new_top_track.size() > 0 and new_bottom_track.size() > 0:
		# Interpolate between original and new tracks during switch
		current_top_track = _interpolate_track_points(original_top_track, new_top_track, switch_progress)
		current_bottom_track = _interpolate_track_points(original_bottom_track, new_bottom_track, switch_progress)

	# Normal interpolation along track (0 to 1)
	var index = int(pos_progress * (current_top_track.size() - 1))
	var next_index = min(index + 1, current_top_track.size() - 1)
	var t = (pos_progress * (current_top_track.size() - 1)) - index

	# Interpolate positions on both tracks (front of note)
	var top_front = current_top_track[index].lerp(current_top_track[next_index], t)
	var bottom_front = current_bottom_track[index].lerp(current_bottom_track[next_index], t)

	# For the back end (rear of note), use earlier progress
	# Note starts as a point and grows, then passes through pad
	var note_length = 0.15
	if progress < 0.15:
		# Growing phase at the beginning
		note_length = progress
	elif progress > 1.2:
		# Shrinking phase after passing pad
		var shrink_factor = 1.0 - ((progress - 1.2) / 0.3)  # From 1.0 to 0 between 1.2 and 1.5
		note_length = 0.15 * max(0, shrink_factor)
	else:
		# Maintain full length through the middle
		note_length = 0.15

	var back_progress = max(0, min(pos_progress - note_length, 1.0))
	var back_index = int(back_progress * (current_top_track.size() - 1))
	var back_next = min(back_index + 1, current_top_track.size() - 1)
	var back_t = (back_progress * (current_top_track.size() - 1)) - back_index

	var top_back = current_top_track[back_index].lerp(current_top_track[back_next], back_t)
	var bottom_back = current_bottom_track[back_index].lerp(current_bottom_track[back_next], back_t)

	# Position note at center of the front edge
	position = (top_front + bottom_front) / 2.0

	# Create rectangle with four corners on the track lines
	# Convert to local coordinates
	var points = PackedVector2Array([
		top_back - position,      # Top left (back/center)
		top_front - position,     # Top right (front/pad)
		bottom_front - position,  # Bottom right (front/pad)
		bottom_back - position    # Bottom left (back/center)
	])

	# Apply jelly effect if active
	if jelly_amplitude > 0:
		var oscillation = sin(jelly_time * jelly_frequency * TAU) * jelly_amplitude
		var perpendicular = Vector2(-(top_front.y - bottom_front.y), top_front.x - bottom_front.x).normalized()

		# Much subtler deformation
		points[1] += perpendicular * oscillation * 3.0  # Top front (was 10.0)
		points[2] -= perpendicular * oscillation * 3.0  # Bottom front (was 10.0)
		# Even lighter deformation for back points
		points[0] += perpendicular * oscillation * 1.5   # Top back (was 5.0)
		points[3] -= perpendicular * oscillation * 1.5   # Bottom back (was 5.0)

	visual.polygon = points

	# Set UV coordinates to map texture across the polygon
	# Map texture from left (solid) to right (fade) along the note's length
	var uvs = PackedVector2Array([
		Vector2(0, 0),    # Top left - start of texture (solid)
		Vector2(1, 0),    # Top right - end of texture (fade)
		Vector2(1, 1),    # Bottom right
		Vector2(0, 1)     # Bottom left
	])
	visual.uv = uvs

	# Transparency based on distance
	var alpha = 1.0
	if progress > 1.0:
		# Fade out after passing through pad (from 1.0 to 1.5)
		alpha = max(0, 1.0 - ((progress - 1.0) / 0.5))
	elif progress < 0.2:
		# Fade in at the beginning
		alpha = lerp(0.3, 1.0, progress * 5.0)
	else:
		alpha = 1.0

	# Apply tint with transparency
	visual.modulate = Color(1.0, 1.0, 1.0, alpha)

func get_hit_distance() -> float:
	# Distance from the pad (end of track)
	# This represents timing distance - positive means note hasn't reached pad yet,
	# negative means it's past the pad
	return (1.0 - progress) * 100.0  # Convert to standardized distance units

func _initiate_track_switch():
	if new_pad < 0 or new_pad == original_pad:
		return

	# Get the playfield to fetch new track points
	var playfield = get_parent().get_parent()
	if not playfield:
		return

	# Store original tracks
	original_top_track = top_track_points
	original_bottom_track = bottom_track_points

	# Get new track points for target pad
	var new_track_idx = new_pad * 2
	new_top_track = playfield.get_track_line_points(new_track_idx)
	new_bottom_track = playfield.get_track_line_points(new_track_idx + 1)

	if new_top_track.size() > 0 and new_bottom_track.size() > 0:
		is_switching = true
		switch_progress = 0.0

		# Trigger jelly effect (smaller initial amplitude)
		jelly_amplitude = 0.5  # Start with less intensity
		jelly_time = 0.0

func _interpolate_track_points(from_track: PackedVector2Array, to_track: PackedVector2Array, t: float) -> PackedVector2Array:
	# Interpolate between two track point arrays
	var result = PackedVector2Array()
	var min_size = min(from_track.size(), to_track.size())

	for i in range(min_size):
		# Use an easing curve for smoother transition
		var eased_t = _ease_in_out_cubic(t)
		result.append(from_track[i].lerp(to_track[i], eased_t))

	return result

func _ease_in_out_cubic(t: float) -> float:
	# More aggressive ease for snappier switching
	if t < 0.3:
		# Slower acceleration at start
		return 3.33 * t * t * t
	elif t > 0.7:
		# Slower deceleration at end
		var p = (t - 0.7) / 0.3
		return 0.7 + 0.3 * (1.0 - (1.0 - p) * (1.0 - p) * (1.0 - p))
	else:
		# Linear in the middle for faster transition
		return (t - 0.3) * 1.75 + 0.3