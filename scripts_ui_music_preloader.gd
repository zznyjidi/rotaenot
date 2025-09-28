extends Node

class_name MusicPreloader

# Preload all music files for HTML5 compatibility
static var music_tracks = {
	"assets_music_Tobu - Faster [NCS Release].mp3": preload("res://assets_music_Tobu - Faster [NCS Release].mp3"),
	"assets_music_sakuracloud - miffy cafe  [NCS Release].mp3": preload("res://assets_music_sakuracloud - miffy cafe  [NCS Release].mp3"),
	"assets_music_Different Heaven - Nekozilla [NCS Release].mp3": preload("res://assets_music_Different Heaven - Nekozilla [NCS Release].mp3"),
	"assets_music_RINZO, MAHIRU - デイドリーム (Daydream) [NCS Release].mp3": preload("res://assets_music_RINZO, MAHIRU - デイドリーム (Daydream) [NCS Release].mp3"),
	"assets_music_Tobu - Funk It [NCS Release].mp3": preload("res://assets_music_Tobu - Funk It [NCS Release].mp3"),
	"assets_music_Electro-Light, Kovan - Skyline Pt. II [NCS Release].mp3": preload("res://assets_music_Electro-Light, Kovan - Skyline Pt. II [NCS Release].mp3"),
	"assets_music_Aisake, Dosi - Cruising [NCS Release].mp3": preload("res://assets_music_Aisake, Dosi - Cruising [NCS Release].mp3"),
	"assets_music_Distrion, Alex Skrindo - Entropy [NCS Release].mp3": preload("res://assets_music_Distrion, Alex Skrindo - Entropy [NCS Release].mp3"),
	"assets_music_Joyful, Фрози, Zachz Winner - Boogie [NCS Release].mp3": preload("res://assets_music_Joyful, Фрози, Zachz Winner - Boogie [NCS Release].mp3"),
	"assets_music_Kovan, Electro-Light - Skyline [NCS Release].mp3": preload("res://assets_music_Kovan, Electro-Light - Skyline [NCS Release].mp3"),
	"assets_music_No Hero, Tatsunoshin - All Or Nothing [NCS Release].mp3": preload("res://assets_music_No Hero, Tatsunoshin - All Or Nothing [NCS Release].mp3"),
	"assets_music_Zachz Winner - blu [NCS Release].mp3": preload("res://assets_music_Zachz Winner - blu [NCS Release].mp3"),
	"assets_music_sakuracloud, 99god - miffy cafe pt. 2 [NCS Release].mp3": preload("res://assets_music_sakuracloud, 99god - miffy cafe pt. 2 [NCS Release].mp3")
}

static func get_music(path: String) -> AudioStream:
	# Remove res:// if present
	var clean_path = path.replace("res://", "")

	if music_tracks.has(clean_path):
		return music_tracks[clean_path]

	# Try to find a partial match
	for key in music_tracks:
		if clean_path in key or key in clean_path:
			return music_tracks[key]

	print("Music not found in preloader: ", path)
	return null