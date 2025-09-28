extends Label

@onready var judgement = $"../JudgementTimer"

const parser = preload("res://game/chart/chart_parser.gd")

func _ready():
	judgement.swap(4, 6)
	judgement.reset()
	
	var chart = parser.parse_chart("res://data/charts/tutorial/easy.chart")
	var tracks = chart.to_tracklist()
	print(tracks)

func _on_judgement_timer_key_status_updated(frame, track_status):
	var key_text = str(frame) + ", "
	for value in track_status:
		key_text += "1" if value == true else "0"
		key_text += ", "
	self.text = key_text
