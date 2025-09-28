extends Node

const Chart = preload("res://game/chart/datatype/chart.gd").Chart
const Note = preload("res://game/chart/datatype/note.gd").Note

const perfectWindow = 30
const greatWindow = 30
const preMissWindow = 40

const MISS    = 0b000
const HIT     = 0b100
const PERFECT = 0b010
const EARLY 	  = 0b001

signal note_updated(judgement_type: int, note_index: int, track: int, hit_delta: int)

var chart_tracks
var next_notes: Array[Note] = [null, null, null, null, null, null]

func set_tracks(chart: Chart) -> void:
	chart_tracks = chart.to_tracklist()

func _on_judgement_timer_key_status_updated(frame, track_status):
	for i in range(next_notes.size()):
		if next_notes[i] == null:
			next_notes[i] = chart_tracks[i].pop_back()

		var next = next_notes[i]
		if next == null: # no more notes
			continue
		else:
			var hit_delta = (frame - next.time)
			if hit_delta > (perfectWindow + greatWindow): # late miss
				note_updated.emit(MISS, next.index, i+1, hit_delta)
				next_notes[i] = null
				continue
			elif track_status[i]: # hit
				if hit_delta < - (perfectWindow + greatWindow + preMissWindow): # not in judging window
					continue
				elif hit_delta < - (perfectWindow + greatWindow): # early miss
					note_updated.emit(MISS | EARLY, next.index, i+1, hit_delta)
					next_notes[i] = null
					continue
				elif hit_delta < - perfectWindow: # early great
					note_updated.emit(HIT | EARLY, next.index, i+1, hit_delta)
					next_notes[i] = null
					continue
				elif hit_delta < 0: # early perfect
					note_updated.emit(HIT | PERFECT | EARLY, next.index, i+1, hit_delta)
					next_notes[i] = null
					continue
				elif hit_delta < perfectWindow: # late perfect
					note_updated.emit(HIT | PERFECT, next.index, i+1, hit_delta)
					next_notes[i] = null
					continue
				else: # late great
					note_updated.emit(HIT, next.index, i+1, hit_delta)
					next_notes[i] = null
					continue
