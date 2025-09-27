extends Node2D

var target_pad: int = 0
var track_points: PackedVector2Array
var progress: float = 0.0
var speed: float = 0.3  # Progress per second

# Visual properties
var base_width: float = 60.0  # Width to span between track lines
var base_height: float = 30.0  # Height of the note

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

func setup(pad_index: int, points: PackedVector2Array):
	target_pad = pad_index
	track_points = points
	set_meta("target_pad", target_pad)

	# Start at first point
	if track_points.size() > 0:
		position = track_points[0]

func _process(delta):
	if track_points.size() < 2:
		return

	# Move along track
	progress += speed * delta

	if progress >= 1.0:
		queue_free()
		return

	# Interpolate position along track points
	var total_segments = track_points.size() - 1
	var current_segment = int(progress * total_segments)
	var segment_progress = (progress * total_segments) - current_segment

	if current_segment < total_segments:
		var start_pos = track_points[current_segment]
		var end_pos = track_points[current_segment + 1]
		position = start_pos.lerp(end_pos, segment_progress)

	# Update visual with perspective effect
	_update_visual_perspective()

func _update_visual_perspective():
	var visual = get_meta("visual") as Polygon2D
	if not visual:
		return

	# Calculate size based on progress (perspective scaling)
	var scale_factor = lerp(0.2, 1.2, progress)  # Start very small, grow larger
	var width = base_width * scale_factor
	var height = base_height * scale_factor

	# Create perspective rectangle - like looking through a tube
	# The BACK (center/far) should be smaller than the FRONT (near/pad)
	var back_scale = lerp(0.3, 1.0, progress)  # Back is smaller when far
	var front_scale = 1.0  # Front stays full size

	# Define the four corners with proper tube perspective
	# When progress is 0 (far), the whole note is small
	# When progress is 1 (near), back is still smaller than front
	var points = PackedVector2Array([
		Vector2(-width / 2 * back_scale, -height / 2 * back_scale),   # Top left (back)
		Vector2(width / 2 * back_scale, -height / 2 * back_scale),    # Top right (back)
		Vector2(width / 2 * front_scale, height / 2 * front_scale),   # Bottom right (front)
		Vector2(-width / 2 * front_scale, height / 2 * front_scale)   # Bottom left (front)
	])

	visual.polygon = points

	# Color and transparency based on distance
	var color_intensity = lerp(0.5, 1.0, progress)
	visual.color = Color(0.5 * color_intensity, 0.8 * color_intensity, 1.0, lerp(0.6, 1.0, progress))

func get_hit_distance() -> float:
	# Distance from the pad (end of track)
	return abs(1.0 - progress) * 100.0  # Convert to pixel-like distance