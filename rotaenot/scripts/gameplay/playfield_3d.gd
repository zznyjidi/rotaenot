extends Node2D

# Pad positions and info
var pads = []
var track_lines = []

# Horizontal ellipse parameters (wide olive)
var ellipse_width = 800.0  # Much wider to fill screen
var ellipse_height = 500.0  # Height (but will be horizontal)

# Pad configuration - positioned on top and bottom curves of horizontal olive
var pad_config = [
	{"side": "top", "pos": "left", "key": "Q", "x_offset": -250},
	{"side": "top", "pos": "mid", "key": "A", "x_offset": 0},
	{"side": "top", "pos": "right", "key": "Z", "x_offset": 250},
	{"side": "bottom", "pos": "left", "key": "P", "x_offset": -250},
	{"side": "bottom", "pos": "mid", "key": "L", "x_offset": 0},
	{"side": "bottom", "pos": "right", "key": "M", "x_offset": 250}
]

func _ready():
	_create_playfield()
	_create_pads()
	_create_track_lines()

func _create_playfield():
	# Create horizontal ellipse boundary (rotated 90 degrees)
	var boundary = Line2D.new()
	boundary.width = 4.0
	boundary.default_color = Color(0.3, 0.4, 0.6, 0.8)
	boundary.closed = true

	var points = []
	var segments = 64

	for i in range(segments):
		var t = (i / float(segments)) * TAU

		# Horizontal ellipse (swap x and y)
		var x = sin(t) * ellipse_width  # Use sin for x (horizontal stretch)
		var y = cos(t) * ellipse_height  # Use cos for y

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

	# Position pads on top or bottom of horizontal ellipse
	var x_pos = config.x_offset
	var y_pos = ellipse_height * (1.0 if config.side == "bottom" else -1.0)

	# Adjust Y to be on the ellipse curve at this X position
	# x^2/a^2 + y^2/b^2 = 1, solve for y
	var x_normalized = x_pos / ellipse_width
	var y_factor = sqrt(max(0, 1.0 - x_normalized * x_normalized))
	y_pos *= y_factor

	pad.position = Vector2(x_pos, y_pos)

	# Create pad visual (rectangular pad)
	var pad_visual = ColorRect.new()
	var pad_size = Vector2(80, 50)
	pad_visual.size = pad_size
	pad_visual.position = -pad_size / 2
	pad_visual.color = Color(0.2, 0.5, 0.8, 0.6)
	pad.add_child(pad_visual)

	# Add key label
	var label = Label.new()
	label.text = "[" + config.key + "]"
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(-15, -12)
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

		# Create TWO straight lines per pad (from left and right edges of pad)
		var pad_half_width = 40  # Half of pad width

		# Left edge line
		var line_left = Line2D.new()
		line_left.width = 2.0
		line_left.default_color = Color(0.3, 0.3, 0.5, 0.3)

		var start_left = pad_pos + Vector2(-pad_half_width, 0)
		var end_left = Vector2(start_left.x * 0.1, 0)  # Converge toward center

		line_left.points = PackedVector2Array([start_left, end_left])
		lines_container.add_child(line_left)
		track_lines.append(line_left)

		# Right edge line
		var line_right = Line2D.new()
		line_right.width = 2.0
		line_right.default_color = Color(0.3, 0.3, 0.5, 0.3)

		var start_right = pad_pos + Vector2(pad_half_width, 0)
		var end_right = Vector2(start_right.x * 0.1, 0)  # Converge toward center

		line_right.points = PackedVector2Array([start_right, end_right])
		lines_container.add_child(line_right)
		track_lines.append(line_right)

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