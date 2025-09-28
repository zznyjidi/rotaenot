extends Node

class_name ImagePreloader

static var song_covers = {
	"demo": preload("res://assets_ui_song_covers_demo.png"),
	"tutorial": preload("res://assets_ui_song_covers_tutorial.png"),
	"electronic": preload("res://assets_ui_song_covers_electronic.png"),
	"sakura": preload("res://assets_ui_song_covers_sakura.png")
}

static var fallback_image = preload("res://assets_ui_menu_backgrounds_NoImage.png")

static func get_song_cover(song_id: String) -> Texture2D:
	if song_covers.has(song_id):
		return song_covers[song_id]
	return fallback_image

static func get_cover_from_path(path: String) -> Texture2D:
	# Extract song type from path
	if "demo" in path:
		return get_song_cover("demo")
	elif "tutorial" in path:
		return get_song_cover("tutorial")
	elif "electronic" in path:
		return get_song_cover("electronic")
	elif "sakura" in path:
		return get_song_cover("sakura")
	else:
		return fallback_image

static func get_cover_for_song(song: Dictionary) -> Texture2D:
	if song.has("id"):
		return get_song_cover(song["id"])
	elif song.has("preview_image"):
		return get_cover_from_path(song["preview_image"])
	else:
		return fallback_image