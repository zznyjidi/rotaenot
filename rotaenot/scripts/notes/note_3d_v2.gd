extends Node2D

var target_pad: int = 0
var track_index: int = 0  # Which track pair this note uses
var progress: float = 0.0
var speed: float = 0.3  # Progress per second

# Store the two track lines for this note
var top_track_points: PackedVector2Array
var bottom_track_points: PackedVector2Array

func _ready():
	set_meta("target_pad", target_pad)

	# Get or create visual
	var visual = $Visual if has_node("Visual") else null
	if not visual:
		visual = Polygon2D.new()
		visual.name = "Visual"
		visual.color = Color(0.5, 0.8, 1.0, 0.9)
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

	if progress >= 1.0:
		queue_free()
		return

	# Update position and visual
	_update_visual_from_tracks()

func _update_visual_from_tracks():
	var visual = get_meta("visual") as Polygon2D
	if not visual:
		return

	# REVERSED: Notes now travel from center (0) to pad (1)
	# Get positions on both tracks at current progress
	var index = int(progress * (top_track_points.size() - 1))
	var next_index = min(index + 1, top_track_points.size() - 1)
	var t = (progress * (top_track_points.size() - 1)) - index

	# Interpolate positions on both tracks (front of note)
	var top_front = top_track_points[index].lerp(top_track_points[next_index], t)
	var bottom_front = bottom_track_points[index].lerp(bottom_track_points[next_index], t)

	# For the back end (rear of note), use earlier progress
	var back_progress = max(0, progress - 0.15)  # Note length
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

	# Color and transparency based on distance
	var color_intensity = lerp(0.5, 1.0, progress)
	visual.color = Color(0.5 * color_intensity, 0.8 * color_intensity, 1.0, lerp(0.6, 1.0, progress))

func get_hit_distance() -> float:
	# Distance from the pad (end of track)
	return abs(1.0 - progress) * 100.0  # Convert to pixel-like distance