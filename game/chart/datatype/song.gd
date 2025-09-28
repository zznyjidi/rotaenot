extends Node

const Chart = preload("res://game/chart/datatype/chart.gd").Chart

class Song:
	var title: String
	var artist: String
	var bpm: int
	var offset: int
	var charts: Array[Chart]
