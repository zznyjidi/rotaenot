extends Node2D

# Pad positions and info
var pads = []
var track_lines = []
var track_fills = []  # Store track area fills for highlighting
var active_tweens = {}  # Store active tweens for each pad

# Vertical ellipse - TALL and THIN with 1:2 ratio, scaled by 0.8
var ellipse_width = 460.8  # Width - scaled by 1.2 * 1.2 (384 * 1.2)
var ellipse_height = 640.0  # Height - the LARGER dimension (tall)

# Pad configuration - positioned on LEFT and RIGHT sides of horizontal olive
var pad_config = [
	{"side": "left", "pos": "top", "key": "Q", "y_offset": -120},  # Scaled by 0.6 (200 * 0.6)
	{"side": "left", "pos": "mid", "key": "A", "y_offset": 0},
	{"side": "left", "pos": "bot", "key": "Z", "y_offset": 120},   # Scaled by 0.6
	{"side": "right", "pos": "top", "key": "P", "y_offset": -120}, # Scaled by 0.6
	{"side": "right", "pos": "mid", "key": "L", "y_offset": 0},
	{"side": "right", "pos": "bot", "key": "M", "y_offset": 120}   # Scaled by 0.6
]

func _ready():
	_create_playfield()
	_create_pads()  # Create pads first since track lines need them
	_create_track_fills()  # Create track fills
	_create_track_lines()  # Create track lines after pads
	_create_center_mask()

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
	pad.z_index = 2  # Put pads above the ellipse boundary

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

	# Create pad visual (curved segment on ellipse edge)
	var pad_visual = Line2D.new()
	pad_visual.width = 8.0  # Thicker for visibility
	pad_visual.default_color = Color(0.2, 0.5, 0.8, 0.9)
	pad_visual.add_to_group("pads")
	pad_visual.z_index = 2  # Above ellipse

	# Create arc segment for the pad on the ellipse edge
	var arc_points = []
	var pad_arc_angle = 9.6  # Scaled by 0.8 (12.0 * 0.8)
	var segments = 8

	# Calculate the angle of this pad position
	var base_angle = atan2(y_pos, x_pos)

	for j in range(segments + 1):
		# Create arc around this position
		var t = (j / float(segments)) - 0.5  # -0.5 to 0.5
		var angle = base_angle + (t * deg_to_rad(pad_arc_angle))

		# Calculate point on ellipse at this angle
		var point_x = cos(angle) * ellipse_width
		var point_y = sin(angle) * ellipse_height

		# This gives us a point on the ellipse
		# Now convert to local coordinates (pad is already on ellipse)
		var global_point = Vector2(point_x, point_y)
		var local_point = global_point - pad_pos

		arc_points.append(local_point)

	pad_visual.points = arc_points
	pad.add_child(pad_visual)

	# Add key label outside the ellipse
	var label = Label.new()
	label.text = config.key
	label.add_theme_font_size_override("font_size", 18)
	# Position label outside based on side
	var label_offset = 40.0
	if config.side == "left":
		label.position = Vector2(-label_offset, -10)
	else:
		label.position = Vector2(label_offset - 10, -10)
	pad.add_child(label)

	# Store pad data
	pad.set_meta("config", config)
	pad.set_meta("index", index)
	pad.set_meta("visual", pad_visual)

	return pad

func _create_track_fills():
	# Create polygons that fill the track areas (between the two lines of each track)
	for i in range(pad_config.size()):
		var config = pad_config[i]

		# Calculate pad position
		var x_pos = ellipse_width * (1.0 if config.side == "right" else -1.0)
		var y_pos = config.y_offset

		# Adjust X to be on the ellipse curve at this Y position
		var y_normalized = y_pos / ellipse_height
		var x_factor = sqrt(max(0, 1.0 - y_normalized * y_normalized))
		x_pos *= x_factor

		# Calculate the arc endpoints for this pad (similar to pad visual)
		var pad_arc_angle = 9.6
		var base_angle = atan2(y_pos, x_pos)

		# Get the top and bottom points of the pad arc
		var angle_top = base_angle - deg_to_rad(pad_arc_angle / 2.0)
		var angle_bottom = base_angle + deg_to_rad(pad_arc_angle / 2.0)

		var top_point = Vector2(cos(angle_top) * ellipse_width, sin(angle_top) * ellipse_height)
		var bottom_point = Vector2(cos(angle_bottom) * ellipse_width, sin(angle_bottom) * ellipse_height)

		# Create polygon for track fill
		var track_fill = Polygon2D.new()
		track_fill.color = Color(0.0, 0.0, 0.0, 0.0)  # Start transparent
		track_fill.z_index = 0  # Below lines and pads

		# Create the polygon points (trapezoid from center to pad)
		var points = PackedVector2Array()
		points.append(Vector2.ZERO)  # Center point
		points.append(top_point)  # Top edge of pad
		points.append(bottom_point)  # Bottom edge of pad

		track_fill.polygon = points
		add_child(track_fill)
		track_fills.append(track_fill)

func _create_track_lines():
	var lines_container = $TrackLines

	for i in range(pad_config.size()):
		var pad = pads[i]
		var pad_pos = pad.position

		# Get the actual pad arc endpoints from the pad visual
		var pad_visual = pad.get_meta("visual") as Line2D
		if not pad_visual or pad_visual.points.size() < 2:
			continue

		# Get first and last points of the pad arc (in local coordinates)
		# Convert to global coordinates
		var top_pad_point = pad_pos + pad_visual.points[0]
		var bottom_pad_point = pad_pos + pad_visual.points[pad_visual.points.size() - 1]

		# Top edge line - from center to top edge of pad arc
		var line_top = Line2D.new()
		line_top.width = 1.0  # Thinner line
		line_top.default_color = Color(0.3, 0.3, 0.5, 0.5)
		line_top.z_index = 1  # Above track fill

		line_top.points = PackedVector2Array([Vector2.ZERO, top_pad_point])
		lines_container.add_child(line_top)
		track_lines.append(line_top)

		# Bottom edge line - from center to bottom edge of pad arc
		var line_bottom = Line2D.new()
		line_bottom.width = 1.0  # Thinner line
		line_bottom.default_color = Color(0.3, 0.3, 0.5, 0.5)
		line_bottom.z_index = 1  # Above track fill

		line_bottom.points = PackedVector2Array([Vector2.ZERO, bottom_pad_point])
		lines_container.add_child(line_bottom)
		track_lines.append(line_bottom)

func highlight_pad(index: int):
	if index >= 0 and index < pads.size():
		var pad = pads[index]
		var visual = pad.get_meta("visual") as Line2D

		# Store original colors
		var original_pad_color = Color(0.2, 0.5, 0.8, 0.9)
		var original_track_fill_color = Color(0.0, 0.0, 0.0, 0.0)  # Transparent
		var highlight_color = Color(0.9, 0.95, 1.0, 0.6)  # Softer, translucent white
		var track_highlight_color = Color(0.8, 0.85, 0.9, 0.2)  # Very faint white for track area

		# Kill any existing tween for this pad
		if index in active_tweens and is_instance_valid(active_tweens[index]):
			active_tweens[index].kill()

		# Highlight pad
		visual.default_color = highlight_color

		# Highlight track fill area
		if index < track_fills.size():
			var track_fill = track_fills[index]
			track_fill.color = track_highlight_color

		# Create tween for smooth fade back
		var tween = create_tween()
		tween.set_parallel(true)
		active_tweens[index] = tween

		# Fade pad back to original color over 0.25 seconds
		tween.tween_property(visual, "default_color", original_pad_color, 0.25)

		# Fade track fill back to transparent
		if index < track_fills.size():
			var track_fill = track_fills[index]
			tween.tween_property(track_fill, "color", original_track_fill_color, 0.25)

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

func _create_center_mask():
	# Create an olive-shaped mask in the center to hide note spawn
	var mask = Polygon2D.new()
	mask.name = "CenterMask"
	mask.color = Color(0, 0, 0, 1.0)  # Black background color
	mask.z_index = 3  # Above track fills and lines, but below HUD

	# Create an olive shape with same ratio as outer ellipse
	var points = PackedVector2Array()
	var mask_width = 144.0  # Width of the mask olive (scaled by 1.2: 120 * 1.2)
	var mask_height = 200.0  # Height maintains 1:2 ratio (approx 120 * 1.67)
	var segments = 32

	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		var x = cos(angle) * mask_width
		var y = sin(angle) * mask_height
		points.append(Vector2(x, y))

	mask.polygon = points

	# Add it as last child so it renders on top of notes but below UI
	add_child(mask)
