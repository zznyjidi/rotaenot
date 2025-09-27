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

	# Create visual using Sprite2D with texture instead of Polygon2D
	var visual = $Visual if has_node("Visual") else null
	if not visual:
		visual = Sprite2D.new()
		visual.name = "Visual"
		# Pick a random texture
		visual.texture = note_textures[randi() % note_textures.size()]
		visual.centered = true
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
	var visual = get_meta("visual") as Sprite2D
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

	# Position note at center between track lines
	position = (top_front + bottom_front) / 2.0

	# Calculate the width between track lines for scaling
	var track_width = (top_front - bottom_front).length()

	# Scale the sprite based on progress and track width
	var scale_factor = lerp(0.1, 1.2, progress)  # Start small, grow larger

	# Scale width to fit between tracks, height proportionally
	# The texture is about 200x17, so maintain aspect ratio
	var texture_aspect = 200.0 / 17.0
	var desired_width = track_width * scale_factor
	var desired_height = desired_width / texture_aspect

	visual.scale.x = desired_width / 200.0  # Scale relative to texture width
	visual.scale.y = visual.scale.x  # Keep aspect ratio

	# Rotation to align with track direction
	if index < top_track_points.size() - 1:
		var direction = (top_front + bottom_front) / 2.0 - position
		if direction.length() > 0:
			visual.rotation = direction.angle()

	# Use region_rect to show only part of the texture (fade effect)
	if progress < 0.85:
		# Show full texture when approaching
		visual.region_enabled = false
	else:
		# Start cropping as it enters pad to create disappearing effect
		visual.region_enabled = true
		var crop_factor = (progress - 0.85) / 0.35
		var texture_width = visual.texture.get_width()
		# Show less of the texture as it enters (from right side)
		visual.region_rect = Rect2(0, 0, texture_width * (1.0 - crop_factor), visual.texture.get_height())

	# Transparency based on distance
	var alpha = 1.0
	if progress > 0.9:
		# Fade out as note enters pad
		alpha = max(0, 1.0 - ((progress - 0.9) / 0.3))
	else:
		alpha = lerp(0.6, 1.0, progress)

	visual.modulate = Color(1.0, 1.0, 1.0, alpha)

func get_hit_distance() -> float:
	# Distance from the pad (end of track)
	return abs(1.0 - progress) * 100.0  # Convert to pixel-like distance