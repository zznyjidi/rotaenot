extends Node2D

# Pad positions and info
var pads = []
var track_lines = []

# Vertical ellipse - TALL and THIN with 1:2 ratio, scaled by 0.8
var ellipse_width = 384.0  # Width - scaled by 1.2 (320 * 1.2)
var ellipse_height = 640.0  # Height - the LARGER dimension (tall)

# Pad configuration - positioned on LEFT and RIGHT sides of horizontal olive
var pad_config = [
	{"side": "left", "pos": "top", "key": "Q", "y_offset": -200},
	{"side": "left", "pos": "mid", "key": "A", "y_offset": 0},
	{"side": "left", "pos": "bot", "key": "Z", "y_offset": 200},
	{"side": "right", "pos": "top", "key": "P", "y_offset": -200},
	{"side": "right", "pos": "mid", "key": "L", "y_offset": 0},
	{"side": "right", "pos": "bot", "key": "M", "y_offset": 200}
]

func _ready():
	_create_playfield()
	_create_pads()
	_create_track_lines()

func _create_playfield():
	# Create VERTICAL ellipse boundary - tall and thin
	var boundary = Line2D.new()
	boundary.width = 4.0
	boundary.default_color = Color(0.3, 0.4, 0.6, 0.8)
	boundary.closed = true

	var points = []
	var segments = 64

	for i in range(segments):
		var t = (i / float(segments)) * TAU

		# VERTICAL ellipse - normal orientation
		var x = cos(t) * ellipse_width   # Width is X (smaller - thin)
		var y = sin(t) * ellipse_height  # Height is Y (larger - tall)

		points.append(Vector2(x, y))

	boundary.points = points
	add_child(boundary)

func _create_pads():
	var pads_container = $Pads

	for i in range(pad_config.size()):
		var config = pad_config[i]
		var pad = _create_single_pad(config, i)
		pads_container.add_child(pad)
		pads.append(pad)

func _create_single_pad(config: Dictionary, index: int) -> Node2D:
	var pad = Node2D.new()
	pad.name = "Pad_" + config.key

	# Position pads on LEFT or RIGHT of VERTICAL ellipse
	var x_pos = ellipse_width * (1.0 if config.side == "right" else -1.0)
	var y_pos = config.y_offset

	# Adjust X to be on the ellipse curve at this Y position
	# x^2/a^2 + y^2/b^2 = 1, solve for x
	var y_normalized = y_pos / ellipse_height
	var x_factor = sqrt(max(0, 1.0 - y_normalized * y_normalized))
	x_pos *= x_factor

	var pad_pos = Vector2(x_pos, y_pos)  # Declare pad_pos before using it
	pad.position = pad_pos

	# Create pad visual (curved segment on ellipse)
	var pad_visual = Line2D.new()
	pad_visual.width = 8.0
	pad_visual.default_color = Color(0.2, 0.5, 0.8, 0.8)

	# Create arc segment for the pad
	var arc_points = []
	var pad_arc_angle = 30.0  # Degrees of arc for each pad
	var segments = 8

	for j in range(segments + 1):
		var angle_offset = (j / float(segments) - 0.5) * deg_to_rad(pad_arc_angle)
		var base_angle = atan2(y_pos, x_pos)
		var angle = base_angle + angle_offset

		var arc_x = cos(angle) * ellipse_width
		var arc_y = sin(angle) * ellipse_height

		# Adjust for ellipse at this position
		var y_norm = arc_y / ellipse_height
		var x_fact = sqrt(max(0, 1.0 - y_norm * y_norm))
		arc_x *= x_fact

		# Convert to local coordinates relative to pad position
		arc_points.append(Vector2(arc_x, arc_y) - pad_pos)

	pad_visual.points = arc_points
	pad.add_child(pad_visual)

	# Add key label
	var label = Label.new()
	label.text = "[" + config.key + "]"
	label.add_theme_font_size_override("font_size", 20)
	label.position = Vector2(-15, -10)
	pad.add_child(label)

	# Store pad data
	pad.set_meta("config", config)
	pad.set_meta("index", index)
	pad.set_meta("visual", pad_visual)

	return pad

func _create_track_lines():
	var lines_container = $TrackLines

	for i in range(pad_config.size()):
		var pad = pads[i]
		var pad_pos = pad.position

		# Create TWO straight lines per pad (from top and bottom edges of pad)
		var pad_half_height = 22  # Half of pad height

		# Top edge line
		var line_top = Line2D.new()
		line_top.width = 2.0
		line_top.default_color = Color(0.3, 0.3, 0.5, 0.3)

		var start_top = pad_pos + Vector2(0, -pad_half_height)
		var end_top = Vector2(0, start_top.y * 0.1)  # Converge toward center

		line_top.points = PackedVector2Array([start_top, end_top])
		lines_container.add_child(line_top)
		track_lines.append(line_top)

		# Bottom edge line
		var line_bottom = Line2D.new()
		line_bottom.width = 2.0
		line_bottom.default_color = Color(0.3, 0.3, 0.5, 0.3)

		var start_bottom = pad_pos + Vector2(0, pad_half_height)
		var end_bottom = Vector2(0, start_bottom.y * 0.1)  # Converge toward center

		line_bottom.points = PackedVector2Array([start_bottom, end_bottom])
		lines_container.add_child(line_bottom)
		track_lines.append(line_bottom)

func highlight_pad(index: int):
	if index >= 0 and index < pads.size():
		var pad = pads[index]
		var visual = pad.get_meta("visual")
		visual.color = Color(0.8, 0.9, 1.0, 0.9)

		# Reset after a moment
		await get_tree().create_timer(0.1).timeout
		visual.color = Color(0.2, 0.5, 0.8, 0.6)

func get_pad_position(index: int) -> Vector2:
	if index >= 0 and index < pads.size():
		return pads[index].position
	return Vector2.ZERO

func get_track_points(index: int) -> PackedVector2Array:
	# Return points for the note to follow (straight line from center to pad)
	if index >= 0 and index < pads.size():
		var pad_pos = pads[index].position
		var start = Vector2(0, 0)  # Start from center
		var end = pad_pos

		# Create intermediate points for smooth movement
		var points = PackedVector2Array()
		for i in range(11):
			var t = i / 10.0
			points.append(start.lerp(end, t))

		return points
	return PackedVector2Array()

func get_track_line_points(track_index: int) -> PackedVector2Array:
	# Get the actual track line points
	if track_index >= 0 and track_index < track_lines.size():
		return track_lines[track_index].points
	return PackedVector2Array()