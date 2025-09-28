extends Label

@onready var judgementKey = $"../JudgementTimer"
@onready var judgement = $"../JudgementTimer/Judgement"

const parser = preload("res://game/chart/chart_parser.gd")

func _ready():
	judgementKey.swap(4, 6)
	
	var chart = parser.parse_chart("res://data/charts/tutorial/easy.chart")
	
	judgement.set_tracks(chart)
	judgementKey.reset()

func _on_judgement_timer_key_status_updated(frame, track_status):
	var key_text = str(frame) + ", "
	for value in track_status:
		key_text += "1" if value == true else "0"
		key_text += ", "
	self.text = key_text


func _on_judgement_timer_note_update(judgement_type, note_index, track, hit_delta):
	print("%d, %d, %d, %d" % [judgement_type, track, note_index, hit_delta])
