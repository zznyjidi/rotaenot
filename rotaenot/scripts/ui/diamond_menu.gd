extends Control

# Diamond (45-degree square) menu with slide animation and magnetic effects

# Diamond properties
@onready var diamond_container: Control
@onready var diamond_button: TextureButton
@onready var game_title: Label
@onready var menu_options: Control
@onready var background_effects: Node2D
@onready var audio_visualizer: Node2D

# Animation states
var is_menu_open: bool = false
var is_animating: bool = false

# Positions
var diamond_center_pos: Vector2 = Vector2(640, 360)  # Center of screen
var diamond_left_pos: Vector2 = Vector2(200, 360)    # Left position after slide
var diamond_size: float = 400.0  # Size of the square 2x bigger (before rotation)

# Menu options data
var menu_items = [
	{"text": "START", "action": "_on_start"},
	{"text": "SETTINGS", "action": "_on_settings"},
	{"text": "QUIT", "action": "_on_quit"}
]
var option_buttons = []

# Magnetic effect variables
var mouse_influence_radius: float = 250.0  # Bigger radius for bigger diamond
var magnetic_strength: float = 0.3
var return_speed: float = 10.0

# Visual properties
var primary_color = Color(0.4, 0.8, 1.0)  # Cyan
var hover_color = Color(1.0, 0.6, 0.8)    # Pink
var bg_color = Color(0.08, 0.08, 0.12)

# Animation
var slide_duration: float = 0.6

func _ready():
	# Create background effects first (lowest layer)
	_create_background_effects()

	# Create the UI elements
	_create_background()
	_create_menu_options()  # Create options first so they're behind
	_create_audio_visualizer()  # Create visualizer before diamond
	_create_diamond()  # Create diamond last so it's on top

	# Start processing for magnetic effects
	set_process(true)

func _create_background_effects():
	# Create the background effects node
	var effects_script = load("res://scripts/ui/menu_background_effects.gd")
	background_effects = Node2D.new()
	background_effects.name = "BackgroundEffects"
	background_effects.set_script(effects_script)
	background_effects.z_index = -1  # Behind everything else
	add_child(background_effects)

func _create_audio_visualizer():
	# Create the audio visualizer that follows the diamond
	var visualizer_script = load("res://scripts/ui/diamond_audio_visualizer.gd")
	audio_visualizer = Node2D.new()
	audio_visualizer.name = "AudioVisualizer"
	audio_visualizer.set_script(visualizer_script)
	audio_visualizer.position = diamond_center_pos
	audio_visualizer.z_index = 8  # Behind diamond (10) but above options (5)
	add_child(audio_visualizer)

func _create_background():
	# Create dark background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = bg_color
	bg.modulate.a = 0.85  # Slight transparency to see effects through
	bg.z_index = 0  # Above background effects but below UI
	add_child(bg)

func _create_diamond():
	# Create container for the diamond
	diamond_container = Control.new()
	diamond_container.name = "DiamondContainer"
	diamond_container.position = diamond_center_pos - Vector2(diamond_size/2, diamond_size/2)
	diamond_container.size = Vector2(diamond_size, diamond_size)
	diamond_container.rotation_degrees = 45  # Rotate 45 degrees to make diamond
	diamond_container.pivot_offset = Vector2(diamond_size/2, diamond_size/2)  # Rotate from center
	diamond_container.z_index = 10  # Put on top of everything
	add_child(diamond_container)

	# Create the square button (will appear as diamond due to rotation)
	diamond_button = TextureButton.new()
	diamond_button.name = "DiamondButton"
	diamond_button.position = Vector2.ZERO
	diamond_button.size = Vector2(diamond_size, diamond_size)
	diamond_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	# Create square texture programmatically
	var image = Image.create(int(diamond_size), int(diamond_size), false, Image.FORMAT_RGBA8)

	# Fill with solid color
	for x in range(int(diamond_size)):
		for y in range(int(diamond_size)):
			# Add slight border softening
			var dist_to_edge = min(min(x, diamond_size - x), min(y, diamond_size - y))
			var alpha = 1.0
			if dist_to_edge < 3:
				alpha = dist_to_edge / 3.0

			image.set_pixel(x, y, Color(0.2, 0.2, 0.25, alpha))

	var texture = ImageTexture.create_from_image(image)
	diamond_button.texture_normal = texture

	# Add hover texture (brighter)
	var hover_image = Image.create(int(diamond_size), int(diamond_size), false, Image.FORMAT_RGBA8)
	for x in range(int(diamond_size)):
		for y in range(int(diamond_size)):
			var dist_to_edge = min(min(x, diamond_size - x), min(y, diamond_size - y))
			var alpha = 1.0
			if dist_to_edge < 3:
				alpha = dist_to_edge / 3.0

			hover_image.set_pixel(x, y, Color(0.3, 0.3, 0.35, alpha))

	var hover_texture = ImageTexture.create_from_image(hover_image)
	diamond_button.texture_hover = hover_texture

	# Connect button signal
	diamond_button.pressed.connect(_on_diamond_clicked)
	diamond_button.mouse_entered.connect(_on_diamond_hover)
	diamond_button.mouse_exited.connect(_on_diamond_unhover)

	diamond_container.add_child(diamond_button)

	# Add game title in the center (need to rotate back to be readable)
	game_title = Label.new()
	game_title.name = "GameTitle"
	game_title.text = "ROTAENOT"
	game_title.add_theme_font_size_override("font_size", 48)  # Bigger font for bigger diamond
	game_title.add_theme_color_override("font_color", primary_color)
	# Center the label properly
	game_title.size = Vector2(diamond_size, diamond_size)
	game_title.position = Vector2(0, 0)
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_title.rotation_degrees = -45  # Counter-rotate to keep text horizontal
	# Fix the pivot point for proper rotation
	game_title.pivot_offset = Vector2(diamond_size/2, diamond_size/2)

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

	diamond_container.add_child(game_title)

	# Add border to diamond
	var border = Line2D.new()
	border.name = "DiamondBorder"
	border.width = 3.0
	border.default_color = primary_color * 0.8
	border.closed = true

	# Create border points (square that will be rotated)
	border.add_point(Vector2(2, 2))
	border.add_point(Vector2(diamond_size - 2, 2))
	border.add_point(Vector2(diamond_size - 2, diamond_size - 2))
	border.add_point(Vector2(2, diamond_size - 2))
	border.add_point(Vector2(2, 2))  # Close the shape

	diamond_container.add_child(border)

func _create_menu_options():
	# Create container for menu options DIRECTLY ATTACHED to diamond's right edge
	menu_options = Control.new()
	menu_options.name = "MenuOptions"
	# Position options to start from CENTER of diamond after it slides
	menu_options.position = Vector2(diamond_left_pos.x, diamond_left_pos.y - diamond_size/2)
	menu_options.size = Vector2(960, diamond_size)
	menu_options.modulate.a = 0.0  # Start invisible
	menu_options.visible = false
	menu_options.z_index = 5  # Below diamond but above background
	add_child(menu_options)

	# Calculate button dimensions
	var button_height = diamond_size / 4.0  # 1/4 of diamond height (100 pixels for 400px diamond)
	var screen_width = 1280
	var three_quarters_screen = screen_width * 0.75  # 960 pixels
	var button_width = three_quarters_screen - diamond_left_pos.x  # Width from center to 3/4 screen
	# Center the middle button (SETTINGS) with the diamond center
	# Since we have 3 buttons, the middle one should be at diamond_size/2
	var y_offset = (diamond_size/2) - button_height * 1.5  # Start position for first button

	for i in range(menu_items.size()):
		var item = menu_items[i]

		# Create button
		var button = Button.new()
		button.name = item.text + "Button"
		button.text = item.text
		button.position = Vector2(0, y_offset)
		button.size = Vector2(button_width, button_height - 5)  # -5 for small gap

		# Style the button with rounded corners
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		style_normal.border_width_left = 2
		style_normal.border_width_top = 1
		style_normal.border_width_bottom = 1
		style_normal.border_width_right = 2
		style_normal.border_color = primary_color * 0.6
		style_normal.corner_radius_top_left = 8
		style_normal.corner_radius_bottom_left = 8
		style_normal.corner_radius_top_right = 8
		style_normal.corner_radius_bottom_right = 8

		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.2, 0.2, 0.3, 1.0)
		style_hover.border_width_left = 3
		style_hover.border_width_top = 2
		style_hover.border_width_bottom = 2
		style_hover.border_width_right = 3
		style_hover.border_color = hover_color
		style_hover.corner_radius_top_left = 8
		style_hover.corner_radius_bottom_left = 8
		style_hover.corner_radius_top_right = 8
		style_hover.corner_radius_bottom_right = 8

		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_hover)

		# Font settings - bigger for bigger buttons
		button.add_theme_font_size_override("font_size", 32)
		button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		button.add_theme_color_override("font_hover_color", hover_color)

		# Connect button signal
		button.pressed.connect(Callable(self, item.action))
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

		menu_options.add_child(button)
		option_buttons.append(button)

		y_offset += button_height  # Next button position

func _on_diamond_clicked():
	if is_animating:
		return

	is_animating = true

	if not is_menu_open:
		# Slide diamond to the left and show menu
		_slide_diamond_left()
	else:
		# Just slide diamond back to center and hide menu
		# Don't trigger shape return - they should stay floating
		_slide_diamond_center()

func _slide_diamond_left():
	# Simple slide animation
	var tween = create_tween()
	tween.set_parallel(false)

	# Slide both diamond and visualizer to the left
	tween.set_parallel(true)
	tween.tween_property(diamond_container, "position:x", diamond_left_pos.x - diamond_size/2, slide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(audio_visualizer, "position:x", diamond_left_pos.x, slide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# After slide, show menu options
	tween.set_parallel(false)
	tween.tween_callback(_show_menu_options)
	tween.tween_callback(func(): is_animating = false)

	is_menu_open = true

func _slide_diamond_center():
	# Hide menu first
	_hide_menu_options()

	# Wait a bit then slide back
	await get_tree().create_timer(0.3).timeout

	# Slide both diamond and visualizer back to center
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(diamond_container, "position:x", diamond_center_pos.x - diamond_size/2, slide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(audio_visualizer, "position:x", diamond_center_pos.x, slide_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false)
	tween.tween_callback(func(): is_animating = false)

	is_menu_open = false

func _show_menu_options():
	menu_options.visible = true

	# Start buttons collapsed (width 0)
	for button in option_buttons:
		button.scale.x = 0.0
		button.scale.y = 1.0

	# Fade in and extend each button horizontally
	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(menu_options, "modulate:a", 1.0, 0.3)

	for i in range(option_buttons.size()):
		var button = option_buttons[i]
		var delay = i * 0.08

		# Extend horizontally from the diamond
		tween.set_parallel(true)
		tween.tween_property(button, "scale:x", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)

func _hide_menu_options():
	var tween = create_tween()

	# Collapse each button horizontally
	for i in range(option_buttons.size()):
		var button = option_buttons[i]
		tween.set_parallel(true)
		tween.tween_property(button, "scale:x", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.set_parallel(false)
	tween.tween_property(menu_options, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): menu_options.visible = false)

func _process(_delta):
	# Apply magnetic effect to diamond and buttons
	_apply_magnetic_effect()

func _apply_magnetic_effect():
	var mouse_pos = get_global_mouse_position()

	# Magnetic effect on diamond and visualizer
	if diamond_container and audio_visualizer:
		var target_pos = diamond_left_pos - Vector2(diamond_size/2, diamond_size/2) if is_menu_open else diamond_center_pos - Vector2(diamond_size/2, diamond_size/2)
		var visualizer_target = diamond_left_pos if is_menu_open else diamond_center_pos
		var diamond_center = diamond_container.global_position + Vector2(diamond_size/2, diamond_size/2)
		var dist = mouse_pos.distance_to(diamond_center)

		if dist < mouse_influence_radius and not is_animating:
			# Calculate repulsion
			var direction = (diamond_center - mouse_pos).normalized()
			var strength = 1.0 - (dist / mouse_influence_radius)
			strength = pow(strength, 2.0) * magnetic_strength

			var offset = direction * strength * 30
			diamond_container.position = target_pos + offset
			audio_visualizer.position = visualizer_target + offset
		else:
			# Return to target position
			diamond_container.position = diamond_container.position.lerp(target_pos, return_speed * get_process_delta_time())
			audio_visualizer.position = audio_visualizer.position.lerp(visualizer_target, return_speed * get_process_delta_time())

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
func _on_diamond_hover():
	var tween = create_tween()
	tween.tween_property(diamond_container, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_ELASTIC)

func _on_diamond_unhover():
	var tween = create_tween()
	tween.tween_property(diamond_container, "scale", Vector2.ONE, 0.2)

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