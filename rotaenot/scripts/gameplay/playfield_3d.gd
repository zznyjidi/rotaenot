extends Node2D

# Pad positions and info
var pads = []
var track_lines = []

# Simple ellipse parameters (tall olive)
var ellipse_width = 400.0
var ellipse_height = 600.0  # Taller than wide

# Pad configuration - positioned on left and right sides
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
	# Create simple ellipse boundary
	var boundary = Line2D.new()
	boundary.width = 3.0
	boundary.default_color = Color(0.3, 0.4, 0.6, 0.8)
	boundary.closed = true

	var points = []
	var segments = 64

	for i in range(segments):
		var t = (i / float(segments)) * TAU

		# Simple ellipse formula
		var x = cos(t) * ellipse_width
		var y = sin(t) * ellipse_height * 0.6  # Compress Y to fit screen

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

	# Position pads on left or right side
	var x_pos = ellipse_width * (1.0 if config.side == "right" else -1.0)
	var y_pos = config.y_offset

	# Adjust X to be on the ellipse curve at this Y position
	# x^2/a^2 + y^2/b^2 = 1, solve for x
	var y_normalized = y_pos / (ellipse_height * 0.6)
	var x_factor = sqrt(max(0, 1.0 - y_normalized * y_normalized))
	x_pos *= x_factor

	pad.position = Vector2(x_pos, y_pos)

	# Create pad visual (rectangular pad)
	var pad_visual = ColorRect.new()
	var pad_size = Vector2(80, 40)
	pad_visual.size = pad_size
	pad_visual.position = -pad_size / 2
	pad_visual.color = Color(0.2, 0.5, 0.8, 0.6)
	pad.add_child(pad_visual)

	# Add key label
	var label = Label.new()
	label.text = config.key
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(-10, -10)
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

		# Create TWO straight lines per pad (from edges of pad)
		var pad_half_width = 40  # Half of pad width

		# Top edge line
		var line_top = Line2D.new()
		line_top.width = 2.0
		line_top.default_color = Color(0.3, 0.3, 0.5, 0.3)

		var start_top = pad_pos + Vector2(0, -pad_half_width/2)
		var end_top = Vector2(0, start_top.y * 0.2)  # Converge toward center

		line_top.points = PackedVector2Array([start_top, end_top])
		lines_container.add_child(line_top)
		track_lines.append(line_top)

		# Bottom edge line
		var line_bottom = Line2D.new()
		line_bottom.width = 2.0
		line_bottom.default_color = Color(0.3, 0.3, 0.5, 0.3)

		var start_bottom = pad_pos + Vector2(0, pad_half_width/2)
		var end_bottom = Vector2(0, start_bottom.y * 0.2)  # Converge toward center

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