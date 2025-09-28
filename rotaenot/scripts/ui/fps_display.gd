extends Control

# FPS Display Singleton
# Shows FPS counter in the top right corner of the screen

@onready var fps_label = Label.new()

func _ready():
	# Set as a singleton by keeping it persistent
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Configure control to be in top right
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	custom_minimum_size = Vector2(100, 30)
	position = Vector2(-120, 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Set high z_index to appear above everything
	z_index = 1000

	# Configure label
	fps_label.name = "FPSLabel"
	fps_label.add_theme_font_size_override("font_size", 16)
	fps_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))  # Yellow
	fps_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	fps_label.add_theme_constant_override("shadow_offset_x", 2)
	fps_label.add_theme_constant_override("shadow_offset_y", 2)
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(fps_label)

	# Load setting and set initial visibility
	visible = SettingsManager.show_fps

func _process(_delta):
	if visible:
		# Update FPS display
		var fps = Engine.get_frames_per_second()
		fps_label.text = "FPS: %d" % fps

		# Color code based on performance
		if fps >= 55:
			fps_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))  # Green
		elif fps >= 30:
			fps_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))  # Yellow
		else:
			fps_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))  # Red

func toggle_visibility(show: bool):
	visible = show