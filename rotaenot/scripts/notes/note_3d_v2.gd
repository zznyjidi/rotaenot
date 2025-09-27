extends Node2D

var target_pad: int = 0
var track_index: int = 0  # Which track pair this note uses
var progress: float = 0.0
var speed: float = 0.5  # Progress per second - FASTER

# Store the two track lines for this note
var top_track_points: PackedVector2Array
var bottom_track_points: PackedVector2Array

# Textures for notes
var note_textures = [
	preload("res://assets/textures/notes/Node_1.png"),
	preload("res://assets/textures/notes/Node_2.png"),
	preload("res://assets/textures/notes/Node_3.png")
]

func _ready():
	set_meta("target_pad", target_pad)

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
	track_index = track_idx
	top_track_points = top_points
	bottom_track_points = bottom_points
	set_meta("target_pad", target_pad)

func _process(delta):
	if top_track_points.size() < 2 or bottom_track_points.size() < 2:
		return

	# Move along track
	progress += speed * delta

	# Continue past the pad for gradual disappearance
	if progress >= 1.2:  # Go 20% past the pad before removing
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

	# REVERSED: Notes now travel from center (0) to pad (1)
	# Get positions on both tracks at current progress
	var index = int(pos_progress * (top_track_points.size() - 1))
	var next_index = min(index + 1, top_track_points.size() - 1)
	var t = (pos_progress * (top_track_points.size() - 1)) - index

	# Interpolate positions on both tracks (front of note)
	var top_front = top_track_points[index].lerp(top_track_points[next_index], t)
	var bottom_front = bottom_track_points[index].lerp(bottom_track_points[next_index], t)

	# For the back end (rear of note), use earlier progress
	# Note starts as a point and grows, then shrinks when entering pad
	var note_length = 0.15
	if progress < 0.85:
		# Growing phase
		note_length = min(0.15, progress * 2.0)
	else:
		# Shrinking phase as it enters the pad
		var shrink_factor = 1.0 - ((progress - 0.85) / 0.35)  # From 1.0 to 0 between 0.85 and 1.2
		note_length = 0.15 * max(0, shrink_factor)

	var back_progress = max(0, min(pos_progress - note_length, 1.0))
	var back_index = int(back_progress * (top_track_points.size() - 1))
	var back_next = min(back_index + 1, top_track_points.size() - 1)
	var back_t = (back_progress * (top_track_points.size() - 1)) - back_index

	var top_back = top_track_points[back_index].lerp(top_track_points[back_next], back_t)
	var bottom_back = bottom_track_points[back_index].lerp(bottom_track_points[back_next], back_t)

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
	if progress > 0.9:
		# Fade out as note enters pad
		alpha = max(0, 1.0 - ((progress - 0.9) / 0.3))
	else:
		alpha = lerp(0.6, 1.0, progress)

	# Apply tint with transparency
	visual.modulate = Color(1.0, 1.0, 1.0, alpha)

func get_hit_distance() -> float:
	# Distance from the pad (end of track)
	return abs(1.0 - progress) * 100.0  # Convert to pixel-like distance