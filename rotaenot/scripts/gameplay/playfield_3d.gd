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
	# Create initial mask (will be updated if background loads)
	_create_center_mask()
	# Add music visualizer ring
	_create_audio_visualizer()

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

	# Add key label ON the pad itself
	var label = Label.new()
	# Get actual keybinding from SettingsManager
	var keymap = {}
	if SettingsManager:
		keymap = SettingsManager.get_keymap_dict()
	else:
		# Fallback to defaults
		keymap = {"W": 0, "E": 1, "F": 2, "J": 3, "I": 4, "O": 5}

	# Find the actual key for this pad
	var actual_key = config.key  # Default
	for key in keymap:
		if keymap[key] == index:
			actual_key = key
			break

	label.text = actual_key
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.5))  # Grey with lower opacity
	# Position label slightly inside the ellipse from the pad
	# Offset based on which side the pad is on
	if config.side == "left":
		label.position = Vector2(25, -10)  # Move right and slightly up for left pads
	else:
		label.position = Vector2(-35, -10)  # Move left and slightly up for right pads
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
	# Create a simple solid mask that blocks the center portions
	# This will be updated later if a background image loads

	# Get background info to match color
	var gameplay_scene = get_parent().get_parent() if get_parent() else null
	var bg_layer = gameplay_scene.get_node_or_null("BackgroundLayer") if gameplay_scene else null
	var bg_image = bg_layer.get_node_or_null("BackgroundImage") if bg_layer else null
	var blur_overlay = bg_layer.get_node_or_null("BlurOverlay") if bg_layer else null

	print("Creating initial center mask, bg_image texture: ", bg_image.texture if bg_image else null)

	# Create the center mask polygon
	var mask = Polygon2D.new()
	mask.name = "CenterMask"
	mask.z_index = 5  # High z-index to cover track lines and notes

	# Create a circular shape to match the visualizer ring
	var points = PackedVector2Array()
	var mask_radius = 112.0  # 70% of original size (160 * 0.7)
	var segments = 32

	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		var x = cos(angle) * mask_radius
		var y = sin(angle) * mask_radius
		points.append(Vector2(x, y))

	mask.polygon = points

	# Set the mask color to blend with background
	if bg_image and bg_image.texture:
		# If there's a background image, create a sprite that shows it
		var mask_sprite = Sprite2D.new()
		mask_sprite.name = "CenterMaskSprite"
		mask_sprite.texture = bg_image.texture
		mask_sprite.centered = true
		mask_sprite.z_index = 5  # Above tracks and notes

		# Scale to match the background size
		var tex_size = bg_image.texture.get_size()
		var scale_x = 1280.0 / tex_size.x
		var scale_y = 720.0 / tex_size.y
		mask_sprite.scale = Vector2(scale_x, scale_y)

		# Apply a clip mask using a shader that only shows ellipse area
		var clip_shader = Shader.new()
		clip_shader.code = """
shader_type canvas_item;

uniform float circle_radius = 112.0;
uniform float blur_amount : hint_range(0.0, 10.0) = 2.0;
uniform float darken : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Apply a stronger gaussian blur
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec4 color = vec4(0.0);
	float total = 0.0;

	// Larger blur kernel for more pronounced effect
	for(float x = -4.0; x <= 4.0; x += 1.0) {
		for(float y = -4.0; y <= 4.0; y += 1.0) {
			float d = length(vec2(x, y));
			float weight = exp(-d * d / 8.0); // Gaussian weight
			vec2 offset = vec2(x, y) * pixel_size * blur_amount;
			color += texture(TEXTURE, UV + offset) * weight;
			total += weight;
		}
	}

	color /= total;
	color.rgb *= (1.0 - darken);  // Apply darkening

	// Calculate position relative to sprite center (in pixels)
	vec2 tex_size = vec2(1280.0, 720.0);
	vec2 world_pos = (UV - 0.5) * tex_size;

	// Check if inside circle
	float dist = length(world_pos);

	if (dist <= circle_radius) {
		// Inside circle - show the blurred texture with soft edge
		float edge_fade = smoothstep(circle_radius * 0.95, circle_radius, dist);
		COLOR = vec4(color.rgb, 1.0 - edge_fade);
	} else {
		// Outside circle - transparent
		COLOR = vec4(0.0);
	}
}
"""
		var clip_material = ShaderMaterial.new()
		clip_material.shader = clip_shader
		clip_material.set_shader_parameter("circle_radius", 112.0)
		clip_material.set_shader_parameter("blur_amount", 3.0)  # Increased blur to match background
		clip_material.set_shader_parameter("darken", 0.6)  # Match the blur overlay's 0.6 alpha darkening
		mask_sprite.material = clip_material

		add_child(mask_sprite)
	else:
		# No background image, use solid color
		print("No background texture found, using solid color mask")
		if blur_overlay and blur_overlay.visible:
			mask.color = blur_overlay.color
		else:
			mask.color = Color(0.02, 0.02, 0.05, 1.0)
		add_child(mask)

	# Border removed - no longer needed

	set_meta("center_mask", get_node_or_null("CenterMaskSprite") if (bg_image and bg_image.texture) else mask)

func _create_combo_display():
	# Create a label to show combo number in the center
	var combo_label = Label.new()
	combo_label.name = "ComboDisplay"
	combo_label.text = "0"
	combo_label.add_theme_font_size_override("font_size", 50)  # Large font (70% of original)
	combo_label.z_index = 10  # Above everything

	# Center the label
	combo_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_label.position = Vector2(-35, -28)  # Adjust to center the text (70% of original)
	combo_label.size = Vector2(70, 56)  # 70% of original size

	# Style the text
	combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	combo_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	combo_label.add_theme_constant_override("shadow_offset_x", 2)
	combo_label.add_theme_constant_override("shadow_offset_y", 2)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	add_child(combo_label)
	set_meta("combo_display", combo_label)

func update_combo_display(combo: int):
	# Update the combo number in the center
	var combo_label = get_node_or_null("ComboDisplay")
	if combo_label:
		combo_label.text = str(combo)

		# Animate on combo change
		if combo > 0:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_ELASTIC)
			tween.set_ease(Tween.EASE_OUT)
			# Pulse effect
			tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)

			# Color change based on combo level
			if combo >= 100:
				combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))  # Gold
			elif combo >= 50:
				combo_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0, 1.0))  # Purple
			elif combo >= 20:
				combo_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))  # Cyan
			else:
				combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))  # White

func _create_audio_visualizer():
	# Create the audio visualizer ring around the center mask
	var visualizer = Node2D.new()
	visualizer.name = "AudioVisualizerRing"
	visualizer.script = load("res://scripts/gameplay/audio_visualizer_ring.gd")
	visualizer.z_index = 8  # Above everything else for visibility

	# Configure visualizer parameters
	visualizer.set("radius_base", 112.0)  # Match the circle mask (70% of original)
	visualizer.set("radius_response", 35.0)  # How far bars can extend (70% of original)
	visualizer.set("bar_count", 48)  # Number of frequency bars
	visualizer.set("bar_width", 2.5)
	visualizer.set("smoothing", 0.25)  # Smooth animation

	add_child(visualizer)
	set_meta("audio_visualizer", visualizer)

	# Add combo number display in the center
	_create_combo_display()

func update_center_mask_with_texture(texture: Texture2D):
	# Called when background is loaded, update the mask to show the background
	print("Updating center mask with texture: ", texture)

	# Remove existing mask
	var old_mask = get_node_or_null("CenterMask")
	if old_mask:
		old_mask.queue_free()
	var old_sprite = get_node_or_null("CenterMaskSprite")
	if old_sprite:
		old_sprite.queue_free()

	if texture:
		# Create a sprite that shows the background
		var mask_sprite = Sprite2D.new()
		mask_sprite.name = "CenterMaskSprite"
		mask_sprite.texture = texture
		mask_sprite.centered = true
		mask_sprite.z_index = 5  # Above tracks and notes

		# Scale to match the background size
		var tex_size = texture.get_size()
		var scale_x = 1280.0 / tex_size.x
		var scale_y = 720.0 / tex_size.y
		mask_sprite.scale = Vector2(scale_x, scale_y)

		# Apply a clip mask using a shader that only shows ellipse area
		var clip_shader = Shader.new()
		clip_shader.code = """
shader_type canvas_item;

uniform float circle_radius = 112.0;
uniform float blur_amount : hint_range(0.0, 10.0) = 2.0;
uniform float darken : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Apply a stronger gaussian blur
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec4 color = vec4(0.0);
	float total = 0.0;

	// Larger blur kernel for more pronounced effect
	for(float x = -4.0; x <= 4.0; x += 1.0) {
		for(float y = -4.0; y <= 4.0; y += 1.0) {
			float d = length(vec2(x, y));
			float weight = exp(-d * d / 8.0); // Gaussian weight
			vec2 offset = vec2(x, y) * pixel_size * blur_amount;
			color += texture(TEXTURE, UV + offset) * weight;
			total += weight;
		}
	}

	color /= total;
	color.rgb *= (1.0 - darken);  // Apply darkening

	// Calculate position relative to sprite center (in pixels)
	vec2 tex_size = vec2(1280.0, 720.0);
	vec2 world_pos = (UV - 0.5) * tex_size;

	// Check if inside circle
	float dist = length(world_pos);

	if (dist <= circle_radius) {
		// Inside circle - show the blurred texture with soft edge
		float edge_fade = smoothstep(circle_radius * 0.95, circle_radius, dist);
		COLOR = vec4(color.rgb, 1.0 - edge_fade);
	} else {
		// Outside circle - transparent
		COLOR = vec4(0.0);
	}
}
"""
		var clip_material = ShaderMaterial.new()
		clip_material.shader = clip_shader
		clip_material.set_shader_parameter("circle_radius", 112.0)
		clip_material.set_shader_parameter("blur_amount", 3.0)  # Increased blur to match background
		clip_material.set_shader_parameter("darken", 0.6)  # Match the blur overlay's 0.6 alpha darkening
		mask_sprite.material = clip_material

		add_child(mask_sprite)
		set_meta("center_mask", mask_sprite)
		print("Successfully created mask with background texture")
	else:
		print("No texture provided, keeping solid mask")

func update_center_mask():
	# Called when background is loaded, update the mask to show the background
	print("Updating center mask with loaded background")

	# Remove existing mask
	var old_mask = get_node_or_null("CenterMask")
	if old_mask:
		old_mask.queue_free()
	var old_sprite = get_node_or_null("CenterMaskSprite")
	if old_sprite:
		old_sprite.queue_free()

	# Get background info
	var gameplay_scene = get_parent().get_parent() if get_parent() else null
	var bg_layer = gameplay_scene.get_node_or_null("BackgroundLayer") if gameplay_scene else null
	var bg_image = bg_layer.get_node_or_null("BackgroundImage") if bg_layer else null
	# blur_overlay not needed in this function

	print("Update mask - bg_image texture: ", bg_image.texture if bg_image else null)

	if bg_image and bg_image.texture:
		# Create a sprite that shows the background
		var mask_sprite = Sprite2D.new()
		mask_sprite.name = "CenterMaskSprite"
		mask_sprite.texture = bg_image.texture
		mask_sprite.centered = true
		mask_sprite.z_index = 5  # Above tracks and notes

		# Scale to match the background size
		var tex_size = bg_image.texture.get_size()
		var scale_x = 1280.0 / tex_size.x
		var scale_y = 720.0 / tex_size.y
		mask_sprite.scale = Vector2(scale_x, scale_y)

		# Apply a clip mask using a shader that only shows ellipse area
		var clip_shader = Shader.new()
		clip_shader.code = """
shader_type canvas_item;

uniform float circle_radius = 112.0;
uniform float blur_amount : hint_range(0.0, 10.0) = 2.0;
uniform float darken : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Apply a stronger gaussian blur
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec4 color = vec4(0.0);
	float total = 0.0;

	// Larger blur kernel for more pronounced effect
	for(float x = -4.0; x <= 4.0; x += 1.0) {
		for(float y = -4.0; y <= 4.0; y += 1.0) {
			float d = length(vec2(x, y));
			float weight = exp(-d * d / 8.0); // Gaussian weight
			vec2 offset = vec2(x, y) * pixel_size * blur_amount;
			color += texture(TEXTURE, UV + offset) * weight;
			total += weight;
		}
	}

	color /= total;
	color.rgb *= (1.0 - darken);  // Apply darkening

	// Calculate position relative to sprite center (in pixels)
	vec2 tex_size = vec2(1280.0, 720.0);
	vec2 world_pos = (UV - 0.5) * tex_size;

	// Check if inside circle
	float dist = length(world_pos);

	if (dist <= circle_radius) {
		// Inside circle - show the blurred texture with soft edge
		float edge_fade = smoothstep(circle_radius * 0.95, circle_radius, dist);
		COLOR = vec4(color.rgb, 1.0 - edge_fade);
	} else {
		// Outside circle - transparent
		COLOR = vec4(0.0);
	}
}
"""
		var clip_material = ShaderMaterial.new()
		clip_material.shader = clip_shader
		clip_material.set_shader_parameter("circle_radius", 112.0)
		clip_material.set_shader_parameter("blur_amount", 3.0)  # Increased blur to match background
		clip_material.set_shader_parameter("darken", 0.6)  # Match the blur overlay's 0.6 alpha darkening
		mask_sprite.material = clip_material

		add_child(mask_sprite)
		set_meta("center_mask", mask_sprite)
		print("Successfully created mask with background texture")
	else:
		print("No background texture available, keeping solid mask")
