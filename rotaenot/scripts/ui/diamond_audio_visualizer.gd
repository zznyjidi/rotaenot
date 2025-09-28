extends Node2D

# Audio visualizer that surrounds the diamond and moves with it

# Audio analysis
var audio_bus_index: int = 0
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance

# Visualization properties
var num_bars: int = 32  # Number of bars around the diamond
var radius_base: float = 250.0  # Base radius from diamond center (bigger than diamond)
var radius_response: float = 60.0  # Max extension of bars
var bar_width: float = 4.0
var bar_base_height: float = 8.0
var bar_max_height: float = 40.0

# Visual colors - matching the futuristic theme
var bar_color_base = Color(0.4, 0.8, 1.0, 0.3)  # Cyan with low opacity
var bar_color_active = Color(0.5, 0.9, 1.0, 0.8)  # Brighter cyan when active

# Bars array
var bars = []
var bar_values = []  # Smoothed values for each bar
var bar_targets = []  # Target values for smooth animation

# Rotation for visual interest
var rotation_speed: float = 0.5  # Slow rotation
var auto_rotate: bool = true

# Diamond reference
var diamond_size: float = 400.0  # Size of the diamond

# Autonomous animation when no audio
var time_elapsed: float = 0.0
var wave_speed: float = 2.0  # Speed of wave animation
var wave_frequency: float = 3.0  # Number of waves around the circle
var idle_animation: bool = true  # Enable idle animation when no audio

class VisualizerBar:
	var line: Line2D
	var angle: float
	var current_height: float = 0.0
	var target_height: float = 0.0

	func _init():
		line = Line2D.new()
		line.width = 4.0
		line.default_color = Color(0.4, 0.8, 1.0, 0.3)
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)

func _ready():
	# Set z_index to be behind menu options but above background
	z_index = 8  # Diamond is at 10, options at 5, so 8 puts us between

	# Setup audio analyzer
	_setup_audio_analyzer()

	# Create visualization bars
	_create_bars()

	# Initialize value arrays
	for i in range(num_bars):
		bar_values.append(0.0)
		bar_targets.append(0.0)

func _setup_audio_analyzer():
	# Get the audio bus
	audio_bus_index = AudioServer.get_bus_index("Master")

	# Add spectrum analyzer effect if not present
	var effect_count = AudioServer.get_bus_effect_count(audio_bus_index)
	var analyzer_found = false

	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(audio_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_analyzer = AudioServer.get_bus_effect_instance(audio_bus_index, i)
			analyzer_found = true
			break

	if not analyzer_found:
		var spectrum_effect = AudioEffectSpectrumAnalyzer.new()
		spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
		AudioServer.add_bus_effect(audio_bus_index, spectrum_effect)
		spectrum_analyzer = AudioServer.get_bus_effect_instance(audio_bus_index, AudioServer.get_bus_effect_count(audio_bus_index) - 1)

func _create_bars():
	for i in range(num_bars):
		var bar = VisualizerBar.new()
		bar.angle = (i * TAU / num_bars) - PI/2  # Start from top

		# Style the line
		bar.line.width = bar_width
		bar.line.default_color = bar_color_base
		bar.line.joint_mode = Line2D.LINE_JOINT_ROUND
		# Note: Line2D doesn't have cap_mode in Godot 4

		# Add antialiasing
		bar.line.antialiased = true

		# Position will be updated in _process
		add_child(bar.line)
		bars.append(bar)

func _process(delta):
	# Update time for autonomous animation
	time_elapsed += delta

	# Auto rotation
	if auto_rotate:
		rotation += rotation_speed * delta

	# Check if we have audio or should use idle animation
	var has_audio = false
	if spectrum_analyzer:
		# Try to detect if there's any audio playing
		var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(20, 20000).length()
		has_audio = magnitude > 0.001

		if has_audio:
			# Update spectrum data from actual audio
			_update_spectrum_data()

	# If no audio or no analyzer, use idle animation
	if not has_audio or not spectrum_analyzer:
		_update_idle_animation()

	# Update bar positions and heights
	for i in range(bars.size()):
		var bar = bars[i]

		# Smooth animation
		bar_values[i] = lerp(bar_values[i], bar_targets[i], 10.0 * delta)

		# Calculate bar position
		var angle = bar.angle + rotation
		var inner_radius = radius_base
		var outer_radius = inner_radius + bar_base_height + bar_values[i] * bar_max_height

		# Update line points
		var inner_point = Vector2(cos(angle), sin(angle)) * inner_radius
		var outer_point = Vector2(cos(angle), sin(angle)) * outer_radius

		bar.line.clear_points()
		bar.line.add_point(inner_point)
		bar.line.add_point(outer_point)

		# Update color based on intensity
		var intensity = bar_values[i]
		bar.line.default_color = bar_color_base.lerp(bar_color_active, intensity)

		# Add glow effect for high intensity
		if intensity > 0.7:
			bar.line.width = bar_width * (1.0 + intensity * 0.3)
		else:
			bar.line.width = bar_width

func _update_spectrum_data():
	# Define frequency ranges for visualization
	var min_freq = 20.0
	var max_freq = 8000.0

	# Calculate frequency range per bar
	var freq_range = (max_freq - min_freq) / num_bars

	for i in range(num_bars):
		# Calculate frequency range for this bar
		var start_freq = min_freq + i * freq_range
		var end_freq = start_freq + freq_range

		# Get magnitude for this frequency range
		var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(start_freq, end_freq)

		# Convert to decibels and normalize
		var db = linear_to_db(magnitude.length())
		var normalized = clamp((db + 60.0) / 60.0, 0.0, 1.0)

		# Apply logarithmic scaling for better visual response
		normalized = pow(normalized, 0.8)

		# Mirror effect for symmetry (optional)
		# Makes opposite sides respond similarly
		if i < int(num_bars / 2):
			var mirror_index = num_bars - 1 - i
			var avg = (normalized + bar_targets[mirror_index]) * 0.5
			bar_targets[i] = avg
			bar_targets[mirror_index] = avg
		else:
			bar_targets[i] = normalized

# Create pulsing effect on beat
func pulse_on_beat():
	for i in range(bars.size()):
		bar_targets[i] = min(1.0, bar_targets[i] + 0.3)

# Set position to follow diamond
func set_visualizer_position(pos: Vector2):
	position = pos

# Enable/disable rotation
func set_rotation_enabled(enabled: bool):
	auto_rotate = enabled

# Adjust visualizer intensity
func set_intensity(intensity: float):
	radius_response = 60.0 * intensity
	bar_max_height = 40.0 * intensity

# Create autonomous wave animation when no audio
func _update_idle_animation():
	if not idle_animation:
		return

	# Create multiple overlapping wave patterns
	for i in range(bars.size()):
		var bar_angle = (i * TAU / num_bars)

		# Primary wave - travels around the circle
		var wave1 = sin(time_elapsed * wave_speed + bar_angle * wave_frequency) * 0.5 + 0.5

		# Secondary wave - different frequency for complexity
		var wave2 = sin(time_elapsed * wave_speed * 1.3 + bar_angle * 2.0) * 0.3

		# Pulsing wave - creates breathing effect
		var pulse = sin(time_elapsed * 1.5) * 0.2 + 0.3

		# Combine waves for final effect
		var combined = clamp((wave1 + wave2) * pulse, 0.0, 1.0)

		# Apply some randomness for organic feel
		combined *= (0.8 + randf() * 0.2)

		# Smooth transition
		bar_targets[i] = combined

		# Create symmetric patterns
		if i < int(num_bars / 2):
			var mirror_index = num_bars - 1 - i
			var avg = (bar_targets[i] + bar_targets[mirror_index]) * 0.5
			bar_targets[i] = avg
			bar_targets[mirror_index] = avg