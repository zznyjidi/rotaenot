extends Node2D

# Audio spectrum analyzer for music-reactive ring visualization
# Creates a circular visualization similar to NCS-style music videos

@export var radius_base: float = 112.0  # Base radius of the ring (70% of original)
@export var radius_response: float = 35.0  # How much the bars can extend (scaled down)
@export var bar_count: int = 64  # Number of bars in the ring
@export var bar_width: float = 3.0  # Width of each bar
@export var smoothing: float = 0.3  # Smoothing factor for animation
@export var color_gradient: Gradient  # Color gradient for the bars

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var bar_heights: Array[float] = []
var bar_targets: Array[float] = []
var bars: Array[Line2D] = []

# Colors for the visualizer
var color_low = Color(0.2, 0.6, 1.0, 0.8)  # Blue for bass
var color_mid = Color(0.4, 0.8, 1.0, 0.8)  # Cyan for mids
var color_high = Color(0.6, 1.0, 1.0, 0.8)  # Light cyan for highs

func _ready():
	# Initialize arrays
	for i in range(bar_count):
		bar_heights.append(0.0)
		bar_targets.append(0.0)

		# Create visual bar
		var bar = Line2D.new()
		bar.width = bar_width
		bar.add_point(Vector2.ZERO)
		bar.add_point(Vector2.ZERO)
		bar.z_index = 7  # Above the mask
		add_child(bar)
		bars.append(bar)

	# Set up audio spectrum analyzer
	_setup_audio_analyzer()

func _setup_audio_analyzer():
	# Get the audio bus with the spectrum analyzer effect
	var bus_idx = AudioServer.get_bus_index("Master")

	# Check if spectrum analyzer already exists
	var effect_count = AudioServer.get_bus_effect_count(bus_idx)
	var spectrum_effect = null

	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_effect = effect
			break

	# If not found, add one
	if not spectrum_effect:
		spectrum_effect = AudioEffectSpectrumAnalyzer.new()
		spectrum_effect.buffer_length = 0.05  # 50ms buffer
		spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
		AudioServer.add_bus_effect(bus_idx, spectrum_effect)
		AudioServer.set_bus_effect_enabled(bus_idx, AudioServer.get_bus_effect_count(bus_idx) - 1, true)

	# Get the analyzer instance
	spectrum_analyzer = AudioServer.get_bus_effect_instance(bus_idx, AudioServer.get_bus_effect_count(bus_idx) - 1)

func _process(delta):
	if not spectrum_analyzer:
		return

	# Update spectrum data
	_update_spectrum_data()

	# Smooth animations
	for i in range(bar_count):
		bar_heights[i] = lerp(bar_heights[i], bar_targets[i], smoothing)

		# Update visual bars
		_update_bar_visual(i)

func _update_spectrum_data():
	# Frequency ranges for visualization
	var min_freq = 20.0  # 20 Hz
	var max_freq = 20000.0  # 20 kHz

	for i in range(bar_count):
		# Calculate frequency for this bar (logarithmic scale)
		var t = float(i) / float(bar_count)
		var freq = min_freq * pow(max_freq / min_freq, t)

		# Get magnitude at this frequency
		var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(freq - 10, freq + 10).length()

		# Convert to decibels and normalize
		var db = 0.0
		if magnitude > 0.0:
			db = 20.0 * log(magnitude) / log(10.0)  # Manual conversion to avoid issues
		else:
			db = -80.0
		var normalized = clamp((db + 80.0) / 80.0, 0.0, 1.0)  # Normalize from -80db to 0db

		# Apply some scaling for visual appeal
		normalized = pow(normalized, 0.5)  # Square root for better visual distribution

		# Set target height
		bar_targets[i] = normalized

func _update_bar_visual(index: int):
	var angle = (float(index) / float(bar_count)) * TAU - PI/2  # Start from top
	var height = bar_heights[index] * radius_response

	# Calculate bar positions
	var inner_radius = radius_base
	var outer_radius = radius_base + height + 10  # Always show at least a small bar

	var inner_pos = Vector2(cos(angle), sin(angle)) * inner_radius
	var outer_pos = Vector2(cos(angle), sin(angle)) * outer_radius

	# Update bar line
	var bar = bars[index]
	bar.clear_points()
	bar.add_point(inner_pos)
	bar.add_point(outer_pos)

	# Color based on frequency range
	var t = float(index) / float(bar_count)
	if t < 0.15:  # Bass
		bar.default_color = color_low
	elif t < 0.5:  # Mids
		bar.default_color = color_mid
	else:  # Highs
		bar.default_color = color_high

	# Fade based on intensity
	bar.default_color.a = 0.3 + bar_heights[index] * 0.7

	# Add glow effect for active bars
	if bar_heights[index] > 0.3:
		bar.width = bar_width * (1.0 + bar_heights[index] * 0.5)
	else:
		bar.width = bar_width

# Optional: Create particle effects for strong beats
func create_beat_particle(intensity: float):
	if intensity < 0.7:
		return

	# This could spawn particles or other effects
	# For now, we'll just pulse the entire ring
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)