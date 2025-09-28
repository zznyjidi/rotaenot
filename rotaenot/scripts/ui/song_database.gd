extends Node

class_name SongDatabase

# Song data structure
static var songs = [
	{
		"id": "demo_chart",
		"title": "Tutorial Track",
		"artist": "N/A",
		"bpm": 120,
		"duration": "2:34",
		"chart_path": "res://charts/demo_chart.json",
		"music_path": "res://assets/music/Tobu - Faster [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/demo.png",  # Place song cover images here
		"difficulties": {
			"Easy": {"level": 2, "notes": 156},
			"Normal": {"level": 5, "notes": 284},
			"Hard": {"level": 8, "notes": 512}
		},
		"unlock_status": true,
		"high_scores": {
			"Easy": 0,
			"Normal": 0,
			"Hard": 0
		}
	},
	{
		"id": "tutorial",
		"title": "Tutorial",
		"artist": "System",
		"bpm": 100,
		"duration": "1:20",
		"chart_path": "res://charts/tutorial_chart.json",
		"music_path": "res://assets/music/sakuracloud - miffy cafe  [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/tutorial.png",
		"difficulties": {
			"Easy": {"level": 1, "notes": 40}
		},
		"unlock_status": true,
		"high_scores": {
			"Easy": 0
		}
	},
	{
		"id": "electronic_dream",
		"title": "Electronic Dream",
		"artist": "N/A",
		"bpm": 140,
		"duration": "3:12",
		"chart_path": "res://charts/electronic_dream.json",
		"music_path": "res://assets/music/Different Heaven - Nekozilla [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/electronic.png",
		"difficulties": {
			"Easy": {"level": 3, "notes": 200},
			"Normal": {"level": 6, "notes": 380},
			"Hard": {"level": 9, "notes": 620},
			"Expert": {"level": 11, "notes": 980},
			"Hell": {"level": 15, "notes": 320, "chart_path": "res://charts/electronic_dream_hell.json"}
		},
		"unlock_status": true,
		"high_scores": {
			"Easy": 0,
			"Normal": 0,
			"Hard": 0,
			"Expert": 0,
			"Hell": 0
		}
	},
	{
		"id": "sakura_waltz",
		"title": "Sakura Waltz",
		"artist": "Hana Melody",
		"bpm": 96,
		"duration": "2:48",
		"chart_path": "res://charts/sakura_waltz.json",
		"music_path": "res://assets/music/RINZO, MAHIRU - デイドリーム (Daydream) [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/sakura.png",
		"difficulties": {
			"Easy": {"level": 2, "notes": 120},
			"Normal": {"level": 4, "notes": 210},
			"Hard": {"level": 7, "notes": 390}
		},
		"unlock_status": false,  # Locked song
		"high_scores": {
			"Easy": 0,
			"Normal": 0,
			"Hard": 0
		}
	},
	{
		"id": "template_chart",
		"title": "Template Example",
		"artist": "Example",
		"bpm": 120,
		"duration": "0:30",
		"chart_path": "res://charts/template_chart.json",
		"music_path": "res://assets/music/Tobu - Funk It [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/template.png",
		"difficulties": {
			"Normal": {"level": 5, "notes": 48}
		},
		"unlock_status": true,  # Available for testing
		"high_scores": {
			"Normal": 0
		}
	},
	{
		"id": "tobu_faster",
		"title": "Faster",
		"artist": "Tobu",
		"bpm": 128,
		"duration": "3:13",
		"chart_path": "res://charts/tobu_faster_normal.json",  # Default to normal
		"music_path": "res://assets/music/Tobu - Faster [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/demo.png",  # Placeholder
		"difficulties": {
			"Easy": {"level": 3, "notes": 32, "chart_path": "res://charts/tobu_faster_easy.json"},
			"Normal": {"level": 5, "notes": 199, "chart_path": "res://charts/tobu_faster_normal.json"},
			"Hard": {"level": 8, "notes": 1070, "chart_path": "res://charts/tobu_faster_hard.json"},
			"Expert": {"level": 11, "notes": 2319, "chart_path": "res://charts/tobu_faster_expert.json"}
		},
		"unlock_status": true,
		"high_scores": {
			"Easy": 0,
			"Normal": 0,
			"Hard": 0,
			"Expert": 0
		}
	},
	{
		"id": "skyline_pt2",
		"title": "Skyline Pt. II",
		"artist": "Electro-Light & Kovan",
		"bpm": 140,
		"duration": "3:45",
		"chart_path": "res://charts/skyline_hell_generated.json",
		"music_path": "res://assets/music/Electro-Light, Kovan - Skyline Pt. II [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/electronic.png",  # Placeholder
		"difficulties": {
			"Hell": {"level": 15, "notes": 2734, "chart_path": "res://charts/skyline_hell_generated.json"}
		},
		"unlock_status": true,
		"high_scores": {
			"Hell": 0
		}
	},
	{
		"id": "friend_tutorial",
		"title": "Tutorial No.2",
		"artist": "Marrelia",
		"bpm": 120,
		"duration": "2:00",
		"chart_path": "res://charts/tutorial_friend.chart",  # CSV format chart
		"music_path": "res://assets/music/sakuracloud - miffy cafe  [NCS Release].mp3",
		"preview_image": "res://assets/ui/song_covers/tutorial.png",
		"difficulties": {
			"Easy": {"level": 1, "notes": 100, "chart_path": "res://charts/tutorial_friend.chart"}
		},
		"unlock_status": true,
		"high_scores": {
			"Easy": 0
		}
	}
]

static func get_all_songs() -> Array:
	return songs

static func get_unlocked_songs() -> Array:
	var unlocked = []
	for song in songs:
		if song.unlock_status:
			unlocked.append(song)
	return unlocked

static func get_song_by_id(id: String) -> Dictionary:
	for song in songs:
		if song.id == id:
			return song
	return {}

static func update_high_score(song_id: String, difficulty: String, score: int):
	var song = get_song_by_id(song_id)
	if song and song.high_scores.has(difficulty):
		if score > song.high_scores[difficulty]:
			song.high_scores[difficulty] = score
			return true
	return false
