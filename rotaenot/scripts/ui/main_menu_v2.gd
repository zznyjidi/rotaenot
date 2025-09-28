extends Control

# osu!-inspired main menu with rotating diamond and magnetic effects

@onready var diamond_container = $DiamondContainer
@onready var menu_buttons = $MenuButtons
@onready var background = $Background
@onready var logo_container = $LogoContainer
@onready var particles = $ParticleContainer

# Diamond rotation
var diamond_rotation_speed: float = 15.0  # Degrees per second
var diamond_hover_scale: float = 1.0
var diamond_target_scale: float = 1.0

# Menu button data
var menu_items = [
	{"text": "PLAY", "action": "_on_play"},
	{"text": "EDITOR", "action": "_on_editor"},
	{"text": "SETTINGS", "action": "_on_settings"},
	{"text": "EXIT", "action": "_on_exit"}
]

# Magnetic effect variables
var mouse_influence_radius: float = 200.0
var mouse_push_strength: float = 30.0
var button_return_speed: float = 8.0
var button_original_positions = {}

# Visual effects
var parallax_strength: float = 0.02
var breathing_scale: float = 0.05
var breathing_speed: float = 1.0
var time_elapsed: float = 0.0

# Colors
var accent_color = Color(1.0, 0.4, 0.6)  # Pink accent like osu!
var hover_color = Color(1.0, 0.6, 0.8)
var default_color = Color(0.9, 0.9, 0.9)

func _ready():
	# Set up the UI
	_create_background()
	_create_diamond()
	_create_menu_buttons()
	_create_logo()
	_create_particles()

	# Start animations
	set_process(true)

func _create_background():
	# Create animated background with gradient
	var bg_rect = ColorRect.new()
	bg_rect.name = "BackgroundGradient"
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Create gradient shader for animated background
	var bg_shader = Shader.new()
	bg_shader.code = """
shader_type canvas_item;

uniform vec2 gradient_center = vec2(0.5, 0.5);
uniform float time_scale = 0.5;
uniform vec4 color1 : source_color = vec4(0.08, 0.08, 0.12, 1.0);
uniform vec4 color2 : source_color = vec4(0.15, 0.10, 0.20, 1.0);

void fragment() {
	vec2 uv = UV;
	float dist = distance(uv, gradient_center);

	// Animate gradient
	float wave = sin(dist * 3.0 - TIME * time_scale) * 0.5 + 0.5;

	vec4 final_color = mix(color1, color2, wave * dist);
	COLOR = final_color;
}
"""

	var bg_material = ShaderMaterial.new()
	bg_material.shader = bg_shader
	bg_rect.material = bg_material

	if not has_node("Background"):
		var bg_node = Node2D.new()
		bg_node.name = "Background"
		add_child(bg_node)
		bg_node.add_child(bg_rect)

func _create_diamond():
	# Create the rotating diamond centerpiece
	if not has_node("DiamondContainer"):
		diamond_container = Control.new()
		diamond_container.name = "DiamondContainer"
		diamond_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		diamond_container.size = Vector2(300, 300)
		diamond_container.position = Vector2(-150, -150)
		add_child(diamond_container)

	# Create diamond shape (rotated square)
	var diamond = Polygon2D.new()
	diamond.name = "Diamond"

	# Square points (will be rotated 45 degrees)
	var size = 120.0
	var points = PackedVector2Array([
		Vector2(-size, 0),
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size)
	])
	diamond.polygon = points
	diamond.color = Color(1.0, 1.0, 1.0, 0.1)
	diamond.position = Vector2(150, 150)  # Center in container

	# Add border
	var border = Line2D.new()
	border.name = "DiamondBorder"
	border.points = points
	border.closed = true
	border.width = 3.0
	border.default_color = accent_color
	border.position = Vector2(150, 150)

	# Add inner decorations
	var inner_diamond = Polygon2D.new()
	inner_diamond.name = "InnerDiamond"
	var inner_size = 80.0
	var inner_points = PackedVector2Array([
		Vector2(-inner_size, 0),
		Vector2(0, -inner_size),
		Vector2(inner_size, 0),
		Vector2(0, inner_size)
	])
	inner_diamond.polygon = inner_points
	inner_diamond.color = Color(1.0, 1.0, 1.0, 0.05)
	inner_diamond.position = Vector2(150, 150)

	diamond_container.add_child(diamond)
	diamond_container.add_child(inner_diamond)
	diamond_container.add_child(border)

	# Add glow effect
	_add_glow_effect(diamond_container)

func _create_menu_buttons():
	# Create menu buttons container
	if not has_node("MenuButtons"):
		menu_buttons = VBoxContainer.new()
		menu_buttons.name = "MenuButtons"
		menu_buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		menu_buttons.position = Vector2(-400, -100)
		menu_buttons.add_theme_constant_override("separation", 20)
		add_child(menu_buttons)

	for i in range(menu_items.size()):
		var item = menu_items[i]

		# Create button container for magnetic effect
		var button_container = Control.new()
		button_container.custom_minimum_size = Vector2(250, 60)

		# Create the actual button
		var button = Button.new()
		button.name = item.text + "Button"
		button.text = item.text
		button.custom_minimum_size = Vector2(250, 60)
		button.flat = true

		# Style the button
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style_normal.border_width_left = 4
		style_normal.border_color = accent_color
		style_normal.corner_radius_top_left = 0
		style_normal.corner_radius_bottom_left = 0
		style_normal.corner_radius_top_right = 8
		style_normal.corner_radius_bottom_right = 8

		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.2, 0.2, 0.3, 0.9)
		style_hover.border_width_left = 6
		style_hover.border_color = hover_color
		style_hover.corner_radius_top_left = 0
		style_hover.corner_radius_bottom_left = 0
		style_hover.corner_radius_top_right = 8
		style_hover.corner_radius_bottom_right = 8

		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_hover)
		button.add_theme_stylebox_override("focus", style_normal)

		# Font settings
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_color", default_color)
		button.add_theme_color_override("font_hover_color", hover_color)

		# Connect button signal
		button.pressed.connect(Callable(self, item.action))

		# Add hover effects
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

		button_container.add_child(button)
		menu_buttons.add_child(button_container)

		# Store original position for magnetic effect
		button_original_positions[button] = Vector2.ZERO

func _create_logo():
	# Create game logo/title
	if not has_node("LogoContainer"):
		logo_container = Control.new()
		logo_container.name = "LogoContainer"
		logo_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		logo_container.position = Vector2(50, 50)
		add_child(logo_container)

	var title = Label.new()
	title.name = "GameTitle"
	title.text = "ROTAENOT"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", accent_color)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)

	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "RHYTHM GAME"
	subtitle.position = Vector2(0, 70)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	logo_container.add_child(title)
	logo_container.add_child(subtitle)

func _create_particles():
	# Create floating particle effects
	if not has_node("ParticleContainer"):
		particles = Node2D.new()
		particles.name = "ParticleContainer"
		add_child(particles)

	# Create several floating orbs
	for i in range(5):
		var orb = Sprite2D.new()
		orb.name = "Orb" + str(i)

		# Create a simple circle texture
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for x in range(32):
			for y in range(32):
				var dist = Vector2(x - 16, y - 16).length()
				if dist < 16:
					var alpha = 1.0 - (dist / 16.0)
					image.set_pixel(x, y, Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.3))

		var texture = ImageTexture.create_from_image(image)
		orb.texture = texture
		orb.position = Vector2(randf() * 1280, randf() * 720)
		orb.scale = Vector2(0.5, 0.5) + Vector2.ONE * randf() * 0.5

		particles.add_child(orb)

func _add_glow_effect(node: Node):
	# Add a glow shader to the node
	var glow_shader = Shader.new()
	glow_shader.code = """
shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.4, 0.6, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Add glow
	float glow = tex_color.a * glow_intensity;
	COLOR = mix(tex_color, glow_color, glow * 0.3);
}
"""

	var glow_material = ShaderMaterial.new()
	glow_material.shader = glow_shader
	glow_material.set_shader_parameter("glow_intensity", 1.0)
	glow_material.set_shader_parameter("glow_color", accent_color)

	if node is CanvasItem:
		node.material = glow_material

func _process(delta):
	time_elapsed += delta

	# Rotate diamond
	if diamond_container:
		diamond_container.rotation_degrees += diamond_rotation_speed * delta

		# Breathing effect
		var breathing = 1.0 + sin(time_elapsed * breathing_speed) * breathing_scale
		diamond_container.scale = Vector2.ONE * breathing * diamond_hover_scale

	# Update magnetic effect for buttons
	_update_magnetic_effect()

	# Parallax effect
	_update_parallax()

	# Floating particles
	_update_particles(delta)

func _update_magnetic_effect():
	var mouse_pos = get_global_mouse_position()

	for button in button_original_positions.keys():
		if not is_instance_valid(button):
			continue

		var button_center = button.global_position + button.size / 2.0
		var distance = mouse_pos.distance_to(button_center)

		if distance < mouse_influence_radius:
			# Calculate push direction (away from mouse)
			var direction = (button_center - mouse_pos).normalized()
			var influence = 1.0 - (distance / mouse_influence_radius)
			influence = pow(influence, 2.0)  # Quadratic falloff

			var offset = direction * influence * mouse_push_strength
			button.position = button_original_positions[button] + offset
		else:
			# Return to original position
			button.position = button.position.lerp(button_original_positions[button], button_return_speed * get_process_delta_time())

func _update_parallax():
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().size
	var offset = (mouse_pos - viewport_size / 2.0) * parallax_strength

	if logo_container:
		logo_container.position = Vector2(50, 50) + offset * 0.5

	if diamond_container:
		var base_pos = Vector2(-150, -150)
		diamond_container.position = base_pos - offset

func _update_particles(delta):
	if not particles:
		return

	for child in particles.get_children():
		if child is Sprite2D:
			# Float upwards and loop
			child.position.y -= 30.0 * delta
			if child.position.y < -50:
				child.position.y = 770
				child.position.x = randf() * 1280

			# Slight horizontal wobble
			child.position.x += sin(time_elapsed * 2.0 + child.position.y * 0.01) * 20.0 * delta

func _on_button_hover(button: Button):
	# Animate diamond on hover
	var tween = create_tween()
	tween.tween_property(self, "diamond_hover_scale", 1.1, 0.2).set_trans(Tween.TRANS_ELASTIC)

	# Add sound effect if available
	_play_hover_sound()

func _on_button_unhover(button: Button):
	# Return diamond to normal
	var tween = create_tween()
	tween.tween_property(self, "diamond_hover_scale", 1.0, 0.2)

func _play_hover_sound():
	# Play hover sound effect if available
	pass

# Button actions
func _on_play():
	print("Opening song selection...")
	get_tree().change_scene_to_file("res://scenes/ui/song_select.tscn")

func _on_editor():
	print("Editor not yet implemented")
	# TODO: Implement level editor

func _on_settings():
	print("Opening settings menu...")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_exit():
	get_tree().quit()