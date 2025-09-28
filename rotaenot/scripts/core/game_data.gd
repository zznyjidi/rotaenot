extends Node

# Singleton for passing data between scenes
var selected_song: Dictionary = {}
var selected_difficulty: String = "Normal"
var last_score: int = 0
var last_combo: int = 0

# Game results for results screen
var last_game_results: Dictionary = {
	"result_type": 0,
	"score": 0,
	"max_combo": 0,
	"perfect_count": 0,
	"great_count": 0,
	"good_count": 0,
	"bad_count": 0,
	"miss_count": 0
}