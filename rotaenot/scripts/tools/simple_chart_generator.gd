extends Node

# Simple Chart Generator
# Generates charts based on BPM and patterns without complex audio analysis

class_name SimpleChartGenerator

func generate_chart_from_audio(audio_path: String, difficulty: String = "Normal", song_title: String = "") -> Dictionary:
	"""Generate a chart with assumed BPM and patterns"""

	# Load audio to get duration
	var audio_stream = load(audio_path) as AudioStream
	if not audio_stream:
		print("Failed to load audio: ", audio_path)
		return {}

	var duration = audio_stream.get_length()

	# Estimate BPM (default to common values)
	var bpm = estimate_bpm_from_filename(audio_path)

	# Generate chart
	var chart = {
		"metadata": {
			"title": song_title if song_title != "" else audio_path.get_file().get_basename(),
			"artist": "Unknown",
			"bpm": bpm,
			"duration": str(int(duration / 60)) + ":" + str(int(duration) % 60).pad_zeros(2),
			"audio_file": audio_path,
			"difficulty": difficulty
		},
		"notes": []
	}

	# Generate notes based on difficulty
	var notes = generate_notes_for_difficulty(duration, bpm, difficulty)
	chart.notes = notes

	return chart

func estimate_bpm_from_filename(path: String) -> int:
	"""Try to guess BPM from filename or use defaults"""
	var filename = path.get_file().to_lower()

	# Common BPM ranges for different genres
	if "fast" in filename or "speed" in filename:
		return 160
	elif "slow" in filename or "ballad" in filename:
		return 80
	elif "techno" in filename or "electronic" in filename or "electro" in filename:
		return 128
	elif "drum" in filename or "dnb" in filename:
		return 174

	# Default to 120 BPM (common tempo)
	return 120

func generate_notes_for_difficulty(duration: float, bpm: float, difficulty: String) -> Array:
	"""Generate note patterns based on difficulty"""
	var notes = []

	# Calculate timing values
	var beat_duration = 60.0 / bpm  # Duration of one beat in seconds
	var measure_duration = beat_duration * 4  # 4/4 time signature

	# Timing offset to compensate for note travel time (adjust as needed)
	var timing_offset = 0.8  # Notes spawn 0.8 seconds earlier to compensate for travel

	# Difficulty settings
	var note_density = {
		"Easy": 0.25,    # 1 note per measure on average
		"Normal": 0.5,   # 2 notes per measure
		"Hard": 1.0,     # 4 notes per measure
		"Expert": 2.0,   # 8 notes per measure
		"Hell": 3.0      # 12 notes per measure
	}.get(difficulty, 0.5)

	var pattern_complexity = {
		"Easy": 1,
		"Normal": 2,
		"Hard": 3,
		"Expert": 4,
		"Hell": 5
	}.get(difficulty, 2)

	# Generate notes throughout the song
	var current_time = 2.0 + timing_offset  # Start after 2 seconds + offset
	var pattern_index = 0
	var last_track = -1  # Track which track was used last
	var track_usage = [0, 0, 0, 0, 0, 0]  # Track usage counter for all 6 tracks

	while current_time < duration - 1.0:  # Stop 1 second before end
		# Decide if we should place a note based on density
		if randf() < note_density:
			# Choose pattern based on complexity
			var pattern = get_pattern(pattern_index, pattern_complexity)

			# Rotate patterns to use different tracks
			var track_rotation = (pattern_index * 2) % 6

			for note_data in pattern:
				if current_time + note_data.offset < duration - 1.0:
					# Apply track rotation to distribute notes across all tracks
					var final_track = (note_data.track + track_rotation) % 6

					# Add some variation based on beat position
					if pattern_complexity >= 3 and randf() < 0.3:
						# Occasionally use less common tracks
						final_track = get_least_used_track(track_usage, last_track)

					notes.append({
						"time": current_time + note_data.offset - timing_offset,  # Subtract offset for actual hit time
						"track": final_track,
						"type": "tap"
					})

					track_usage[final_track] += 1
					last_track = final_track

			pattern_index += 1

		# Move forward by beat or fraction of beat
		current_time += beat_duration / note_density

	# Sort notes by time
	notes.sort_custom(func(a, b): return a.time < b.time)

	# Remove notes that are too close together on the same track
	notes = filter_close_notes_per_track(notes, 0.15)  # Minimum 150ms between notes on same track

	return notes

func get_least_used_track(usage: Array, last_track: int) -> int:
	"""Get the track that has been used least, avoiding the last used track"""
	var min_usage = 999999
	var selected_track = 0

	for i in range(6):
		if i != last_track and usage[i] < min_usage:
			min_usage = usage[i]
			selected_track = i

	return selected_track

func get_pattern(index: int, complexity: int) -> Array:
	"""Get a note pattern based on complexity level"""

	# Pattern libraries for different complexity levels - now using all 6 tracks
	var simple_patterns = [
		[{"offset": 0.0, "track": 0}],  # Track 0
		[{"offset": 0.0, "track": 1}],  # Track 1
		[{"offset": 0.0, "track": 2}],  # Track 2
		[{"offset": 0.0, "track": 3}],  # Track 3
		[{"offset": 0.0, "track": 4}],  # Track 4
		[{"offset": 0.0, "track": 5}],  # Track 5
	]

	var normal_patterns = [
		[{"offset": 0.0, "track": 0}, {"offset": 0.2, "track": 3}],  # Left-right
		[{"offset": 0.0, "track": 1}, {"offset": 0.2, "track": 4}],  # Middle alternating
		[{"offset": 0.0, "track": 2}, {"offset": 0.2, "track": 5}],  # Bottom alternating
		[{"offset": 0.0, "track": 0}, {"offset": 0.1, "track": 1}, {"offset": 0.2, "track": 2}],  # Left cascade
		[{"offset": 0.0, "track": 3}, {"offset": 0.1, "track": 4}, {"offset": 0.2, "track": 5}],  # Right cascade
		[{"offset": 0.0, "track": 0}, {"offset": 0.15, "track": 5}],  # Diagonal
		[{"offset": 0.0, "track": 2}, {"offset": 0.15, "track": 3}],  # Center mix
	]

	var hard_patterns = [
		[{"offset": 0.0, "track": 0}, {"offset": 0.0, "track": 3}],  # Jump left-right
		[{"offset": 0.0, "track": 1}, {"offset": 0.0, "track": 4}],  # Middle jump
		[{"offset": 0.0, "track": 2}, {"offset": 0.0, "track": 5}],  # Bottom jump
		[{"offset": 0.0, "track": 0}, {"offset": 0.1, "track": 1}, {"offset": 0.2, "track": 2}, {"offset": 0.3, "track": 3}, {"offset": 0.4, "track": 4}, {"offset": 0.5, "track": 5}],  # Full roll
		[{"offset": 0.0, "track": 5}, {"offset": 0.1, "track": 4}, {"offset": 0.2, "track": 3}, {"offset": 0.3, "track": 2}, {"offset": 0.4, "track": 1}, {"offset": 0.5, "track": 0}],  # Reverse roll
		[{"offset": 0.0, "track": 0}, {"offset": 0.0, "track": 2}, {"offset": 0.0, "track": 4}],  # Triple left
		[{"offset": 0.0, "track": 1}, {"offset": 0.0, "track": 3}, {"offset": 0.0, "track": 5}],  # Triple right
	]

	var expert_patterns = [
		[{"offset": 0.0, "track": 0}, {"offset": 0.0, "track": 3}, {"offset": 0.1, "track": 1}, {"offset": 0.1, "track": 4}],  # Double jump
		[{"offset": 0.0, "track": 0}, {"offset": 0.05, "track": 1}, {"offset": 0.1, "track": 2}, {"offset": 0.15, "track": 3}, {"offset": 0.2, "track": 4}, {"offset": 0.25, "track": 5}],  # Fast full roll
		[{"offset": 0.0, "track": 1}, {"offset": 0.0, "track": 4}, {"offset": 0.1, "track": 0}, {"offset": 0.1, "track": 3}, {"offset": 0.2, "track": 2}, {"offset": 0.2, "track": 5}],  # Complex jumps
		[{"offset": 0.0, "track": 0}, {"offset": 0.0, "track": 2}, {"offset": 0.0, "track": 4}, {"offset": 0.1, "track": 1}, {"offset": 0.1, "track": 3}, {"offset": 0.1, "track": 5}],  # Full hand
		[{"offset": 0.0, "track": 2}, {"offset": 0.05, "track": 3}, {"offset": 0.1, "track": 1}, {"offset": 0.15, "track": 4}, {"offset": 0.2, "track": 0}, {"offset": 0.25, "track": 5}],  # Spiral
	]

	# Select pattern based on complexity
	var patterns = []
	if complexity >= 1:
		patterns.append_array(simple_patterns)
	if complexity >= 2:
		patterns.append_array(normal_patterns)
	if complexity >= 3:
		patterns.append_array(hard_patterns)
	if complexity >= 4:
		patterns.append_array(expert_patterns)

	if patterns.is_empty():
		patterns = simple_patterns

	return patterns[index % patterns.size()]

func filter_close_notes(notes: Array, min_interval: float) -> Array:
	"""Remove notes that are too close together"""
	if notes.is_empty():
		return notes

	var filtered = [notes[0]]
	var last_time = notes[0].time

	for i in range(1, notes.size()):
		if notes[i].time - last_time >= min_interval:
			filtered.append(notes[i])
			last_time = notes[i].time

	return filtered

func filter_close_notes_per_track(notes: Array, min_interval: float) -> Array:
	"""Remove notes that are too close together on the same track"""
	if notes.is_empty():
		return notes

	var filtered = []
	var last_time_per_track = [-999.0, -999.0, -999.0, -999.0, -999.0, -999.0]  # Initialize for 6 tracks

	for note in notes:
		var track = note.track
		if track >= 0 and track < 6:
			if note.time - last_time_per_track[track] >= min_interval:
				filtered.append(note)
				last_time_per_track[track] = note.time

	return filtered

func save_chart(chart: Dictionary, output_path: String) -> bool:
	"""Save chart to JSON file"""
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(chart, "\t"))
		file.close()
		print("Chart saved to: ", output_path)
		return true
	else:
		print("Failed to save chart to: ", output_path)
		return false