extends Control

# Interactive circular menu with roll animation and magnetic effects

# Circle properties
@onready var circle_container: Control
@onready var circle_button: TextureButton
@onready var game_title: Label
@onready var menu_options: Control

# Animation states
var is_menu_open: bool = false
var is_animating: bool = false

# Positions
var circle_center_pos: Vector2 = Vector2(640, 360)  # Center of screen
var circle_left_pos: Vector2 = Vector2(200, 360)    # Left position after roll
var circle_radius: float = 180.0  # 1.8x bigger circle (was 100, now 180)

# Menu options data
var menu_items = [
	{"text": "START", "action": "_on_start"},
	{"text": "SETTINGS", "action": "_on_settings"},
	{"text": "QUIT", "action": "_on_quit"}
]
var option_buttons = []

# Magnetic effect variables
var mouse_influence_radius: float = 150.0
var magnetic_strength: float = 0.3
var return_speed: float = 10.0

# Visual properties
var primary_color = Color(0.4, 0.8, 1.0)  # Cyan
var hover_color = Color(1.0, 0.6, 0.8)    # Pink
var bg_color = Color(0.08, 0.08, 0.12)

# Roll animation
var roll_duration: float = 0.8
var roll_rotations: int = 2

func _ready():
	# Create the UI elements
	_create_background()
	_create_center_circle()
	_create_menu_options()

	# Start processing for magnetic effects
	set_process(true)

func _create_background():
	# Create dark background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = bg_color
	add_child(bg)

func _create_center_circle():
	# Create container for the circle
	circle_container = Control.new()
	circle_container.name = "CircleContainer"
	circle_container.position = circle_center_pos - Vector2(circle_radius, circle_radius)
	circle_container.size = Vector2(circle_radius * 2, circle_radius * 2)
	add_child(circle_container)

	# Create the circular button
	circle_button = TextureButton.new()
	circle_button.name = "CircleButton"
	circle_button.position = Vector2.ZERO
	circle_button.size = Vector2(circle_radius * 2, circle_radius * 2)
	circle_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	# Create circle texture programmatically (solid circle)
	var image = Image.create(360, 360, false, Image.FORMAT_RGBA8)
	var center = Vector2(180, 180)

	for x in range(360):
		for y in range(360):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 180:
				# Solid circle with clean edge
				var alpha = 1.0
				if dist > 175:  # Smooth edge
					alpha = 1.0 - (dist - 175) / 5.0

				# Solid color, no gradient
				image.set_pixel(x, y, Color(0.2, 0.2, 0.25, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	var texture = ImageTexture.create_from_image(image)
	circle_button.texture_normal = texture

	# Add hover texture (brighter solid)
	var hover_image = Image.create(360, 360, false, Image.FORMAT_RGBA8)
	for x in range(360):
		for y in range(360):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 180:
				var alpha = 1.0
				if dist > 175:
					alpha = 1.0 - (dist - 175) / 5.0

				# Solid brighter color for hover
				hover_image.set_pixel(x, y, Color(0.3, 0.3, 0.35, alpha))
			else:
				hover_image.set_pixel(x, y, Color(0, 0, 0, 0))

	var hover_texture = ImageTexture.create_from_image(hover_image)
	circle_button.texture_hover = hover_texture

	# Connect button signal
	circle_button.pressed.connect(_on_circle_clicked)
	circle_button.mouse_entered.connect(_on_circle_hover)
	circle_button.mouse_exited.connect(_on_circle_unhover)

	circle_container.add_child(circle_button)

	# Add game title in the center
	game_title = Label.new()
	game_title.name = "GameTitle"
	game_title.text = "ROTAENOT"
	game_title.add_theme_font_size_override("font_size", 42)  # Bigger font for bigger circle
	game_title.add_theme_color_override("font_color", primary_color)
	game_title.size = Vector2(circle_radius * 2, circle_radius * 2)
	game_title.position = Vector2(0, 0)
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Add glow effect to title
	var glow_shader = Shader.new()
	glow_shader.code = """
shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(0.4, 0.8, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
	COLOR = tex_color + vec4(glow_color.rgb * tex_color.a * glow_strength * pulse * 0.5, 0.0);
}
"""

	var glow_material = ShaderMaterial.new()
	glow_material.shader = glow_shader
	glow_material.set_shader_parameter("glow_strength", 0.8)
	glow_material.set_shader_parameter("glow_color", primary_color)
	game_title.material = glow_material

	circle_container.add_child(game_title)

func _create_menu_options():
	# Create container for menu options at the FINAL position (where circle ends)
	menu_options = Control.new()
	menu_options.name = "MenuOptions"
	# Position options to the right of where circle ends
	menu_options.position = Vector2(circle_left_pos.x + circle_radius + 20, circle_left_pos.y - 100)
	menu_options.size = Vector2(300, 300)
	menu_options.modulate.a = 0.0  # Start invisible
	menu_options.visible = false
	add_child(menu_options)

	var y_offset = 0.0
	for i in range(menu_items.size()):
		var item = menu_items[i]

		# Create button
		var button = Button.new()
		button.name = item.text + "Button"
		button.text = item.text
		button.position = Vector2(0, y_offset)
		button.size = Vector2(200, 50)

		# Style the button
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.8)
		style_normal.border_width_left = 3
		style_normal.border_color = primary_color * 0.6
		style_normal.corner_radius_top_left = 25
		style_normal.corner_radius_bottom_left = 25
		style_normal.corner_radius_top_right = 5
		style_normal.corner_radius_bottom_right = 5

		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.2, 0.2, 0.3, 0.9)
		style_hover.border_width_left = 4
		style_hover.border_color = hover_color
		style_hover.corner_radius_top_left = 25
		style_hover.corner_radius_bottom_left = 25
		style_hover.corner_radius_top_right = 5
		style_hover.corner_radius_bottom_right = 5

		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_hover)

		# Font settings
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		button.add_theme_color_override("font_hover_color", hover_color)

		# Connect button signal
		button.pressed.connect(Callable(self, item.action))
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

		menu_options.add_child(button)
		option_buttons.append(button)

		y_offset += 70  # Spacing between buttons

func _on_circle_clicked():
	if is_animating:
		return

	is_animating = true

	if not is_menu_open:
		# Roll circle to the left and show menu
		_roll_circle_left()
	else:
		# Roll circle back to center and hide menu
		_roll_circle_center()

func _roll_circle_left():
	# Calculate how far the circle needs to roll
	var roll_distance = circle_center_pos.x - circle_left_pos.x
	# Calculate rotations based on circumference (distance = rotations * circumference)
	var circumference = TAU * circle_radius
	var actual_rotations = roll_distance / circumference

	# Create rolling animation like a wheel
	var tween = create_tween()
	tween.set_parallel(false)

	# Roll animation (rotate and move together like a wheel rolling)
	# In Godot, positive rotation is clockwise, and we're moving left, so we rotate negative
	tween.set_parallel(true)
	tween.tween_property(circle_container, "position:x", circle_left_pos.x - circle_radius, roll_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# Negative rotation for rolling left (counter-clockwise)
	tween.tween_property(circle_container, "rotation", -actual_rotations * TAU, roll_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# After roll, show menu options with slide animation
	tween.set_parallel(false)
	tween.tween_callback(_show_menu_options)
	tween.tween_callback(func(): is_animating = false)

	is_menu_open = true

func _roll_circle_center():
	# Hide menu first
	_hide_menu_options()

	# Wait a bit then roll back
	await get_tree().create_timer(0.3).timeout

	# Calculate roll distance for return
	var roll_distance = circle_center_pos.x - circle_left_pos.x
	var circumference = TAU * circle_radius
	var actual_rotations = roll_distance / circumference

	# Create rolling animation back (roll right to return to center)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(circle_container, "position:x", circle_center_pos.x - circle_radius, roll_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# Roll back to rotation 0 (clockwise since moving right)
	tween.tween_property(circle_container, "rotation", 0, roll_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false)
	tween.tween_callback(func(): is_animating = false)

	is_menu_open = false

func _show_menu_options():
	menu_options.visible = true

	# Start buttons with scale 0
	for button in option_buttons:
		button.scale = Vector2.ZERO

	# Fade in container and scale up each button from the center
	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(menu_options, "modulate:a", 1.0, 0.3)

	for i in range(option_buttons.size()):
		var button = option_buttons[i]
		var delay = i * 0.1

		# Scale up from center with elastic effect
		tween.set_parallel(true)
		tween.tween_property(button, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)

func _hide_menu_options():
	var tween = create_tween()

	# Scale down each button back to center
	for i in range(option_buttons.size()):
		var button = option_buttons[i]
		tween.set_parallel(true)
		tween.tween_property(button, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.set_parallel(false)
	tween.tween_property(menu_options, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): menu_options.visible = false)

func _process(_delta):
	# Apply magnetic effect to circle and buttons
	_apply_magnetic_effect()

func _apply_magnetic_effect():
	var mouse_pos = get_global_mouse_position()

	# Magnetic effect on circle
	if circle_container:
		var target_pos = circle_left_pos - Vector2(circle_radius, circle_radius) if is_menu_open else circle_center_pos - Vector2(circle_radius, circle_radius)
		var circle_center = circle_container.global_position + Vector2(circle_radius, circle_radius)
		var dist = mouse_pos.distance_to(circle_center)

		if dist < mouse_influence_radius and not is_animating:
			# Calculate repulsion
			var direction = (circle_center - mouse_pos).normalized()
			var strength = 1.0 - (dist / mouse_influence_radius)
			strength = pow(strength, 2.0) * magnetic_strength

			var offset = direction * strength * 30
			circle_container.position = target_pos + offset
		else:
			# Return to target position
			circle_container.position = circle_container.position.lerp(target_pos, return_speed * get_process_delta_time())

	# Magnetic effect on menu buttons
	if is_menu_open and menu_options.visible:
		for button in option_buttons:
			var button_center = button.global_position + button.size / 2.0
			var dist = mouse_pos.distance_to(button_center)

			if dist < mouse_influence_radius:
				var direction = (button_center - mouse_pos).normalized()
				var strength = 1.0 - (dist / mouse_influence_radius)
				strength = pow(strength, 2.0) * magnetic_strength * 0.5

				var offset = direction.x * strength * 20
				button.position.x = max(0, offset)  # Only push right

# Hover effects
func _on_circle_hover():
	var tween = create_tween()
	tween.tween_property(circle_container, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_ELASTIC)

func _on_circle_unhover():
	var tween = create_tween()
	tween.tween_property(circle_container, "scale", Vector2.ONE, 0.2)

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_ELASTIC)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.2)

# Button actions
func _on_start():
	print("Starting game...")
	get_tree().change_scene_to_file("res://scenes/ui/song_select.tscn")

func _on_settings():
	print("Opening settings...")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_quit():
	get_tree().quit()