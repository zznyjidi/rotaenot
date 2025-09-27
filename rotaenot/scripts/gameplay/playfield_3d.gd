extends Node2D

# Pad positions and info
var pads = []
var track_lines = []

# Olive/ellipse parameters
var ellipse_width = 500.0
var ellipse_height = 800.0  # Taller than screen
var center_pinch = 0.7  # How much to pinch the middle (0.7 = 30% thinner)

# 3D perspective parameters
var vanishing_point = Vector2(0, 0)
var perspective_strength = 0.4

# Pad configuration
var pad_config = [
	{"side": "left", "pos": "top", "key": "Q", "angle": -60},
	{"side": "left", "pos": "mid", "key": "A", "angle": -90},
	{"side": "left", "pos": "bot", "key": "Z", "angle": -120},
	{"side": "right", "pos": "top", "key": "P", "angle": 60},
	{"side": "right", "pos": "mid", "key": "L", "angle": 90},
	{"side": "right", "pos": "bot", "key": "M", "angle": 120}
]

func _ready():
	_create_playfield()
	_create_pads()
	_create_track_lines()

func _create_playfield():
	# Create the olive-shaped boundary
	var boundary = Line2D.new()
	boundary.width = 3.0
	boundary.default_color = Color(0.3, 0.4, 0.6, 0.8)
	boundary.closed = true

	var points = []
	var segments = 64

	for i in range(segments):
		var t = (i / float(segments)) * TAU

		# Basic ellipse
		var x = cos(t) * ellipse_width
		var y = sin(t) * ellipse_height

		# Apply pinch effect (make middle thinner)
		var pinch_factor = 1.0 - (center_pinch * (1.0 - abs(sin(t))))
		x *= pinch_factor

		# Apply perspective transformation
		var depth = (y / ellipse_height + 1.0) * 0.5  # 0 at top, 1 at bottom
		var perspective_scale = lerp(0.6, 1.0, depth)
		x *= perspective_scale

		points.append(Vector2(x, y * 0.5))  # Compress Y for screen fit

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

	# Calculate position on ellipse
	var angle_rad = deg_to_rad(config.angle)
	var base_x = cos(angle_rad) * ellipse_width
	var base_y = sin(angle_rad) * ellipse_height * 0.5

	# Apply pinch effect
	var pinch_factor = 1.0 - (center_pinch * (1.0 - abs(sin(angle_rad))))
	base_x *= pinch_factor

	# Apply perspective
	var depth = (base_y / (ellipse_height * 0.5) + 1.0) * 0.5
	var perspective_scale = lerp(0.6, 1.0, depth)
	base_x *= perspective_scale

	pad.position = Vector2(base_x, base_y)

	# Create pad visual
	var pad_visual = ColorRect.new()
	pad_visual.size = Vector2(60 * perspective_scale, 60 * perspective_scale)
	pad_visual.position = -pad_visual.size / 2
	pad_visual.color = Color(0.2, 0.5, 0.8, 0.6)
	pad.add_child(pad_visual)

	# Add key label
	var label = Label.new()
	label.text = config.key
	label.add_theme_font_size_override("font_size", int(24 * perspective_scale))
	label.position = Vector2(-15, -15) * perspective_scale
	pad.add_child(label)

	# Store pad data
	pad.set_meta("config", config)
	pad.set_meta("index", index)
	pad.set_meta("visual", pad_visual)

	return pad

func _create_track_lines():
	var lines_container = $TrackLines

	for i in range(pad_config.size()):
		var config = pad_config[i]
		var pad = pads[i]

		# Create track line from center area to pad
		var track_line = Line2D.new()
		track_line.width = 2.0
		track_line.default_color = Color(0.3, 0.3, 0.5, 0.3)

		# Start point (near center but offset)
		var start_offset = Vector2(0, 0)
		if config.side == "left":
			start_offset.x = -30
		else:
			start_offset.x = 30

		if config.pos == "top":
			start_offset.y = -20
		elif config.pos == "bot":
			start_offset.y = 20

		# End point (pad position)
		var end_point = pad.position

		# Create intermediate points for curved track
		var points = []
		for j in range(11):
			var t = j / 10.0
			var point = start_offset.lerp(end_point, t)

			# Add slight curve
			var curve_offset = sin(t * PI) * 20.0
			if config.side == "left":
				point.x -= curve_offset
			else:
				point.x += curve_offset

			points.append(point)

		track_line.points = points
		lines_container.add_child(track_line)
		track_lines.append(track_line)

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
	if index >= 0 and index < track_lines.size():
		return track_lines[index].points
	return PackedVector2Array()