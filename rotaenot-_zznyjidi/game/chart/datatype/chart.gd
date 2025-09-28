extends Node

const Note = preload("res://game/chart/datatype/note.gd").Note

class Chart:
	var difficulty: String
	var notes: Array[Array] = [[],[],[],[],[],[]]
	
	func add_note(note: Note) -> void:
		notes[note.track - 1].append(note)
	
	func to_tracklist() -> Array[Array]:
		var parsed_chart = notes.duplicate(true)
		for track in parsed_chart:
			track.reverse()
		return parsed_chart
