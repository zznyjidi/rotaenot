extends Node

const Note = preload("res://game/chart/datatype/note.gd").Note
const Chart = preload("res://game/chart/datatype/chart.gd").Chart

static func parse_chart(path: String) -> Chart:
	var notes = parse_notes(path)
	var chart = Chart.new()
	for note in notes:
		chart.add_note(note)
	return chart

static func parse_notes(path: String) -> Array[Note]:
	var chart = FileAccess.open(path, FileAccess.READ)
	if chart == null:
		push_error('Error opening file:', path)
		push_error('Error code:', FileAccess.get_open_error())
		return []
	
	var note_list: Array[Note] = []
	var note_index = 0
	while not chart.eof_reached():
		var line = chart.get_csv_line()
		var object
		
		var object_type = int(line[3])
		var object_time = int(line[2])
		var object_track = floor(float(line[0]) * 6 / 512) + 1
		
		if object_type & 0b00000001:
			object = create_tap(note_index, object_time, object_track)
		elif object_type & 0b10000000:
			var object_end_time = int(line[5].split(':')[0])
			object = create_hold(note_index, object_time, object_track, object_end_time - object_time)
		elif object_time & 0b00000010:
			var object_target_track = int(line[5].split(':')[0])
			object = create_swap(note_index, object_time, object_track, object_target_track)
		else:
			continue
		note_list.append(object)
		note_index += 1
	chart.close()
	return note_list

static func create_tap(index: int, time: int, track: int) -> Note:
	var note = Note.new()
	note.type = 1
	note.index = index
	
	note.time = time
	note.track = track
	
	return note

static func create_hold(index: int, time: int, track: int, length: int) -> Note:
	var note = Note.new()
	note.type = 2
	note.index = index
	
	note.time = time
	note.track = track
	note.hold_length = length
	
	return note

static func create_swap(index: int, time: int, track: int, target_track: int) -> Note:
	var note = Note.new()
	note.type = 3
	note.index = index
	
	note.time = time
	note.track = track
	note.target_track = target_track
	
	return note
