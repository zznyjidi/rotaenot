extends Node

# Script to generate example charts for existing music

func _ready():
	var generator = SimpleChartGenerator.new()

	# Let's generate a chart for "Tobu - Faster"
	var music_path = "res://assets/music/Tobu - Faster [NCS Release].mp3"
	var output_dir = "res://charts/"

	# Generate charts for different difficulties
	var difficulties = ["Easy", "Normal", "Hard", "Expert"]

	for difficulty in difficulties:
		print("Generating ", difficulty, " chart for Tobu - Faster...")

		var chart = generator.generate_chart_from_audio(
			music_path,
			difficulty,
			"Tobu - Faster"
		)

		if not chart.is_empty():
			# Update metadata
			chart.metadata.title = "Faster"
			chart.metadata.artist = "Tobu"
			chart.metadata.bpm = 128  # Electronic music typical BPM

			# Save the chart
			var filename = "tobu_faster_" + difficulty.to_lower() + ".json"
			var success = generator.save_chart(chart, output_dir + filename)

			if success:
				print("Successfully generated ", difficulty, " chart with ", chart.notes.size(), " notes")
			else:
				print("Failed to save ", difficulty, " chart")
		else:
			print("Failed to generate ", difficulty, " chart")

	print("\nChart generation complete!")
	print("Generated charts saved to: ", output_dir)

	# Also generate a chart for another song as example
	print("\nGenerating chart for Electronic Dream...")

	# For the electronic_dream_hell chart that already exists
	var electronic_music = "res://assets/music/Electro-Light, Kovan - Skyline Pt. II [NCS Release].mp3"

	var electronic_chart = generator.generate_chart_from_audio(
		electronic_music,
		"Hell",
		"Skyline Pt. II"
	)

	if not electronic_chart.is_empty():
		electronic_chart.metadata.title = "Skyline Pt. II"
		electronic_chart.metadata.artist = "Electro-Light & Kovan"
		electronic_chart.metadata.bpm = 140  # Slightly faster for "Hell" difficulty

		generator.save_chart(electronic_chart, output_dir + "skyline_hell_generated.json")
		print("Generated Hell difficulty chart with ", electronic_chart.notes.size(), " notes")

	# Exit after generation
	get_tree().quit()