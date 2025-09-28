extends Control

# Clean, minimal main menu with centered layout and smooth animations

@onready var title_label = $VBoxContainer/TitleContainer/TitleLabel
@onready var subtitle_label = $VBoxContainer/TitleContainer/SubtitleLabel
@onready var start_button = $VBoxContainer/ButtonContainer/StartButton
@onready var settings_button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button = $VBoxContainer/ButtonContainer/QuitButton
@onready var quit_dialog = $QuitConfirmDialog
@onready var background = $Background

# Animation variables
var time: float = 0.0
var title_glow_speed: float = 2.0
var title_pulse_speed: float = 1.5
var button_hover_scale: float = 1.08
var button_press_scale: float = 0.95

# Colors
var primary_color = Color(0.4, 0.8, 1.0)  # Cyan
var secondary_color = Color(0.8, 0.4, 1.0)  # Purple
var hover_color = Color(1.0, 0.6, 0.8)  # Pink
var text_color = Color(0.95, 0.95, 0.95)
var bg_color = Color(0.08, 0.08, 0.12)

func _ready():
	# Set up the UI
	_setup_background()
	_setup_title()
	_setup_buttons()
	_setup_quit_dialog()

	# Start with fade in animation
	modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Focus on start button
	start_button.grab_focus()

func _setup_background():
	# Create animated gradient background
	if not has_node("Background"):
		background = ColorRect.new()
		background.name = "Background"
		add_child(background)
		move_child(background, 0)  # Move to back

	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Create gradient shader
	var bg_shader = Shader.new()
	bg_shader.code = """
shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.08, 0.08, 0.12, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.12, 0.10, 0.18, 1.0);
uniform float wave_speed = 0.3;
uniform float wave_amplitude = 0.05;

void fragment() {
	float wave = sin(TIME * wave_speed) * wave_amplitude;
	float gradient = UV.y + wave;
	COLOR = mix(color_top, color_bottom, gradient);
}
"""

	var bg_material = ShaderMaterial.new()
	bg_material.shader = bg_shader
	bg_material.set_shader_parameter("color_top", bg_color)
	bg_material.set_shader_parameter("color_bottom", bg_color * 1.5)
	background.material = bg_material

func _setup_title():
	# Main container
	if not has_node("VBoxContainer"):
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.position = Vector2(0, -50)  # Slightly higher than center
		vbox.add_theme_constant_override("separation", 60)
		add_child(vbox)

		# Title container
		var title_container = VBoxContainer.new()
		title_container.name = "TitleContainer"
		title_container.add_theme_constant_override("separation", 10)
		vbox.add_child(title_container)

		# Main title
		title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.text = "ROTAENOT"
		title_label.add_theme_font_size_override("font_size", 96)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_container.add_child(title_label)

		# Subtitle
		subtitle_label = Label.new()
		subtitle_label.name = "SubtitleLabel"
		subtitle_label.text = "RHYTHM EXPERIENCE"
		subtitle_label.add_theme_font_size_override("font_size", 18)
		subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_container.add_child(subtitle_label)

		# Button container
		var button_container = VBoxContainer.new()
		button_container.name = "ButtonContainer"
		button_container.add_theme_constant_override("separation", 15)
		button_container.custom_minimum_size = Vector2(300, 0)
		vbox.add_child(button_container)

	# Apply glow effect to title
	_apply_title_glow()

func _setup_buttons():
	var button_container = $VBoxContainer/ButtonContainer

	# Create buttons with consistent styling
	var buttons = [
		{"name": "StartButton", "text": "START", "action": _on_start_pressed},
		{"name": "SettingsButton", "text": "SETTINGS", "action": _on_settings_pressed},
		{"name": "QuitButton", "text": "QUIT", "action": _on_quit_pressed}
	]

	for btn_data in buttons:
		var button = Button.new()
		button.name = btn_data.name
		button.text = btn_data.text
		button.custom_minimum_size = Vector2(300, 60)
		button_container.add_child(button)

		# Style the button
		_style_button(button)

		# Connect signals
		button.pressed.connect(btn_data.action)
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))

		# Store reference
		if btn_data.name == "StartButton":
			start_button = button
		elif btn_data.name == "SettingsButton":
			settings_button = button
		elif btn_data.name == "QuitButton":
			quit_button = button

func _style_button(button: Button):
	# Create stylebox for normal state
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = primary_color * 0.6
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.content_margin_left = 15
	style_normal.content_margin_right = 15
	style_normal.content_margin_top = 15
	style_normal.content_margin_bottom = 15

	# Create stylebox for hover state
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 3
	style_hover.border_color = hover_color
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	style_hover.content_margin_left = 15
	style_hover.content_margin_right = 15
	style_hover.content_margin_top = 15
	style_hover.content_margin_bottom = 15
	style_hover.shadow_color = hover_color * 0.3
	style_hover.shadow_size = 10

	# Create stylebox for pressed state
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.25, 0.25, 0.35, 0.95)
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 3
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = hover_color * 1.2
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8
	style_pressed.content_margin_left = 15
	style_pressed.content_margin_right = 15
	style_pressed.content_margin_top = 15
	style_pressed.content_margin_bottom = 15

	# Apply styles
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_hover)

	# Font settings
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", hover_color * 1.2)

func _setup_quit_dialog():
	# Create confirmation dialog
	quit_dialog = AcceptDialog.new()
	quit_dialog.name = "QuitConfirmDialog"
	quit_dialog.dialog_text = "Are you sure you want to quit?"
	quit_dialog.title = "Confirm Exit"
	quit_dialog.size = Vector2(400, 150)
	quit_dialog.add_button("No", true, "cancel")

	# Style the dialog
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = primary_color * 0.6
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	quit_dialog.add_theme_stylebox_override("panel", panel_style)

	# Connect signals
	quit_dialog.confirmed.connect(_on_quit_confirmed)
	quit_dialog.canceled.connect(_on_quit_canceled)

	add_child(quit_dialog)

func _apply_title_glow():
	# Add glow shader to title
	var glow_shader = Shader.new()
	glow_shader.code = """
shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float pulse_speed = 2.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Pulsing glow
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float glow = tex_color.a * glow_intensity * pulse;

	// Mix original color with glow
	COLOR = tex_color + vec4(glow_color.rgb * glow * 0.5, 0.0);
}
"""

	var glow_material = ShaderMaterial.new()
	glow_material.shader = glow_shader
	glow_material.set_shader_parameter("glow_intensity", 0.8)
	glow_material.set_shader_parameter("glow_color", primary_color)
	glow_material.set_shader_parameter("pulse_speed", title_pulse_speed)

	if title_label:
		title_label.material = glow_material

func _process(delta):
	time += delta

	# Animate title pulse
	if title_label:
		var pulse = 1.0 + sin(time * title_pulse_speed) * 0.02
		title_label.scale = Vector2(pulse, pulse)

		# Subtle color shift
		var color_shift = (sin(time * 0.5) + 1.0) * 0.5
		var current_color = primary_color.lerp(secondary_color, color_shift)
		title_label.add_theme_color_override("font_color", current_color)

# Button interaction handlers
func _on_button_hover(button: Button):
	# Scale up animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * button_hover_scale, 0.3)

	# Play hover sound if available
	_play_sound("hover")

func _on_button_unhover(button: Button):
	# Scale back to normal
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.2)

func _on_button_down(button: Button):
	# Press animation - slightly shrink
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * button_press_scale, 0.05)

func _on_button_up(button: Button):
	# Release animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2.ONE * button_hover_scale, 0.1)

# Button actions
func _on_start_pressed():
	_play_sound("click")

	# Fade out before transitioning
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/ui/song_select.tscn"))

func _on_settings_pressed():
	_play_sound("click")

	# Fade out before transitioning
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn"))

func _on_quit_pressed():
	_play_sound("click")
	quit_dialog.popup_centered()

func _on_quit_confirmed():
	_play_sound("click")

	# Fade out before quitting
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): get_tree().quit())

func _on_quit_canceled():
	_play_sound("back")

func _play_sound(_sound_name: String):
	# Placeholder for sound effects
	# You can add AudioStreamPlayer nodes and play sounds here
	pass
