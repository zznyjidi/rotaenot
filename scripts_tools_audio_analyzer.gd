extends Node

# Audio Analyzer for Chart Generation
# Analyzes audio files to detect beats and generate chart data

class_name AudioAnalyzer

# Analysis parameters
const FFT_SIZE = 2048
const SAMPLE_RATE = 44100.0
const BEAT_THRESHOLD = 0.15  # Sensitivity for beat detection
const MIN_BEAT_INTERVAL = 0.1  # Minimum time between beats (seconds)

# Frequency bands for different detection
const BAND_SUB_BASS = [20, 60]      # Sub-bass (kick drums)
const BAND_BASS = [60, 250]         # Bass
const BAND_LOW_MID = [250, 500]     # Low midrange
const BAND_MID = [500, 2000]        # Midrange (snares, vocals)
const BAND_HIGH_MID = [2000, 4000]  # High midrange
const BAND_HIGH = [4000, 20000]     # High frequencies (cymbals)

var audio_stream: AudioStream
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var audio_player: AudioStreamPlayer

# Analysis results
var beats: Array = []  # Array of beat timestamps
var energy_levels: Array = []  # Energy over time
var bpm: float = 0.0
var onset_times: Array = []  # Detected onsets/transients

func _init():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	# Setup spectrum analyzer on a bus
	var bus_idx = AudioServer.bus_count
	AudioServer.add_bus(bus_idx)
	AudioServer.set_bus_name(bus_idx, "AnalysisBus")

	var spectrum_effect = AudioEffectSpectrumAnalyzer.new()
	spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
	AudioServer.add_bus_effect(bus_idx, spectrum_effect)

	spectrum_analyzer = AudioServer.get_bus_effect_instance(bus_idx, 0)
	audio_player.bus = "AnalysisBus"

func analyze_audio_file(file_path: String) -> Dictionary:
	"""Main analysis function - returns chart data"""

	# Load the audio file
	audio_stream = load(file_path)
	if not audio_stream:
		print("Failed to load audio: ", file_path)
		return {}

	audio_player.stream = audio_stream

	# Get basic info
	var length = audio_stream.get_length()

	# Perform analysis
	beats = await detect_beats()
	bpm = calculate_bpm(beats)
	onset_times = detect_onsets()
	energy_levels = analyze_energy_profile()

	# Generate chart data based on analysis
	var chart_data = generate_chart_data()

	return chart_data

func detect_beats() -> Array:
	"""Detect beats using spectral flux method"""
	var detected_beats = []
	var last_beat_time = -MIN_BEAT_INTERVAL

	# We need to play the audio to analyze it
	# This is a simplified version - in practice you'd want more sophisticated analysis

	audio_player.play()
	var time = 0.0
	var dt = 0.05  # Sample every 50ms
	var prev_flux = 0.0

	while time < audio_stream.get_length():
		await get_tree().create_timer(dt).timeout

		# Get spectral flux (change in spectrum)
		var flux = calculate_spectral_flux()

		# Detect peaks in flux (these are likely beats)
		if flux > BEAT_THRESHOLD and flux > prev_flux and time - last_beat_time > MIN_BEAT_INTERVAL:
			detected_beats.append(time)
			last_beat_time = time

		prev_flux = flux
		time += dt

		# Skip ahead in audio to match our sampling
		if audio_player.playing:
			audio_player.seek(time)

	audio_player.stop()
	return detected_beats

func calculate_spectral_flux() -> float:
	"""Calculate spectral flux for beat detection"""
	if not spectrum_analyzer:
		return 0.0

	var flux = 0.0

	# Focus on bass frequencies for beat detection
	var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(
		BAND_BASS[0], BAND_BASS[1]
	)

	flux = magnitude.length()

	# Also check sub-bass for kick drums
	var sub_bass = spectrum_analyzer.get_magnitude_for_frequency_range(
		BAND_SUB_BASS[0], BAND_SUB_BASS[1]
	)

	flux += sub_bass.length() * 1.5  # Weight sub-bass more heavily

	return flux

func detect_onsets() -> Array:
	"""Detect note onsets using high-frequency content"""
	var onsets = []

	# Simplified onset detection
	# In practice, you'd want to use more sophisticated methods
	for beat_time in beats:
		# Add some variation around beats for more interesting patterns
		onsets.append(beat_time)

		# Sometimes add off-beat notes
		if randf() > 0.5:
			onsets.append(beat_time + (60.0 / bpm) / 2.0)  # Add half-beat

	return onsets

func calculate_bpm(beat_times: Array) -> float:
	"""Calculate BPM from beat timestamps"""
	if beat_times.size() < 2:
		return 120.0  # Default BPM

	# Calculate average time between beats
	var intervals = []
	for i in range(1, beat_times.size()):
		intervals.append(beat_times[i] - beat_times[i-1])

	# Get median interval (more robust than mean)
	intervals.sort()
	var median_interval = intervals[intervals.size() / 2]

	# Convert to BPM
	return 60.0 / median_interval

func analyze_energy_profile() -> Array:
	"""Analyze overall energy/intensity over time"""
	var profile = []

	# Sample energy at regular intervals
	var sample_rate = 0.25  # Sample every 250ms
	var time = 0.0

	while time < audio_stream.get_length():
		# This would need actual audio data analysis
		# For now, we'll use a simplified approach
		var energy = randf()  # Placeholder
		profile.append({
			"time": time,
			"energy": energy
		})
		time += sample_rate

	return profile

func generate_chart_data() -> Dictionary:
	"""Generate chart data from analysis"""
	var chart = {
		"metadata": {
			"title": "Generated Chart",
			"artist": "Unknown",
			"bpm": bpm,
			"audio_file": audio_stream.resource_path,
			"generated": true
		},
		"notes": []
	}

	# Generate notes based on detected beats and onsets
	for i in range(onset_times.size()):
		var time = onset_times[i]

		# Determine which track (0-5) to place the note
		var track = choose_track_for_note(i, time)

		# Determine note type (could be extended for hold notes, etc.)
		var note_type = "tap"

		chart.notes.append({
			"time": time,
			"track": track,
			"type": note_type
		})

	# Sort notes by time
	chart.notes.sort_custom(func(a, b): return a.time < b.time)

	return chart

func choose_track_for_note(index: int, time: float) -> int:
	"""Choose which track to place a note on"""
	# This is where pattern generation happens
	# You can make this as sophisticated as you want

	# Simple pattern: alternate between sides with some variation
	var patterns = [
		[0, 3, 1, 4, 2, 5],  # Zigzag
		[0, 1, 2, 3, 4, 5],  # Linear
		[0, 5, 1, 4, 2, 3],  # Outside-in
		[2, 3, 1, 4, 0, 5],  # Middle-out
	]

	# Choose pattern based on section of song
	var pattern_idx = int(time / 16.0) % patterns.size()
	var pattern = patterns[pattern_idx]

	return pattern[index % pattern.size()]

# Utility functions
func save_chart_to_file(chart_data: Dictionary, output_path: String):
	"""Save generated chart to JSON file"""
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(chart_data, "\t"))
		file.close()
		print("Chart saved to: ", output_path)
	else:
		print("Failed to save chart")