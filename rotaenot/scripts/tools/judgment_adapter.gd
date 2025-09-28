extends Node

# Judgment Adapter
# Integrates friend's advanced judgment system with your existing game

class_name JudgmentAdapter

# Import friend's judgment constants
const PERFECT_WINDOW = 30  # milliseconds
const GREAT_WINDOW = 30    # milliseconds
const PRE_MISS_WINDOW = 40 # milliseconds

# Judgment result bitflags (from friend's code)
const MISS    = 0b000
const HIT     = 0b100
const PERFECT = 0b010
const EARLY   = 0b001

# Your existing judgment types
enum JudgmentType {
	PERFECT,
	GREAT,
	GOOD,
	BAD,
	MISS
}

signal judgment_result(type: JudgmentType, delta: float, is_early: bool)

var frame_time_ms: float = 0.0
var music_position_ms: float = 0.0

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	# Update frame time in milliseconds
	frame_time_ms += delta * 1000.0

# Convert friend's frame-based timing to your music-based timing
func judge_note_hit(note_time_sec: float, hit_time_sec: float) -> Dictionary:
	var note_time_ms = note_time_sec * 1000.0
	var hit_time_ms = hit_time_sec * 1000.0
	var delta_ms = hit_time_ms - note_time_ms

	# Use friend's judgment logic
	var judgment_flags = calculate_judgment_flags(delta_ms)

	# Convert to your system
	var result = {
		"type": convert_flags_to_type(judgment_flags),
		"delta": delta_ms / 1000.0,  # Convert back to seconds
		"is_early": (judgment_flags & EARLY) != 0,
		"is_hit": (judgment_flags & HIT) != 0
	}

	return result

# Friend's judgment logic
func calculate_judgment_flags(delta_ms: float) -> int:
	if delta_ms > (PERFECT_WINDOW + GREAT_WINDOW):
		# Late miss
		return MISS
	elif delta_ms < -(PERFECT_WINDOW + GREAT_WINDOW + PRE_MISS_WINDOW):
		# Too early, not in window
		return -1  # Invalid
	elif delta_ms < -(PERFECT_WINDOW + GREAT_WINDOW):
		# Early miss
		return MISS | EARLY
	elif delta_ms < -PERFECT_WINDOW:
		# Early great
		return HIT | EARLY
	elif delta_ms < 0:
		# Early perfect
		return HIT | PERFECT | EARLY
	elif delta_ms < PERFECT_WINDOW:
		# Late perfect
		return HIT | PERFECT
	elif delta_ms < (PERFECT_WINDOW + GREAT_WINDOW):
		# Late great
		return HIT
	else:
		# Should not reach here
		return MISS

# Convert friend's bitflags to your judgment types
func convert_flags_to_type(flags: int) -> JudgmentType:
	if flags == -1:
		return -1  # Not in window
	elif (flags & HIT) == 0:
		return JudgmentType.MISS
	elif (flags & PERFECT) != 0:
		return JudgmentType.PERFECT
	else:
		return JudgmentType.GREAT

# Improved judgment with friend's timing windows
func judge_with_improved_timing(note: Dictionary, current_time: float) -> Dictionary:
	var note_time = note.time
	var delta_sec = current_time - note_time
	var delta_ms = delta_sec * 1000.0

	# Use friend's more precise timing windows
	var result = {
		"hit": false,
		"judgment": JudgmentType.MISS,
		"delta": delta_sec,
		"early": false,
		"in_window": false
	}

	# Check if in judgment window
	var total_window_ms = PERFECT_WINDOW + GREAT_WINDOW + PRE_MISS_WINDOW
	if abs(delta_ms) > total_window_ms:
		result.in_window = false
		if delta_ms > 0:
			result.judgment = JudgmentType.MISS  # Late miss
		return result

	result.in_window = true
	result.early = delta_ms < 0

	# Apply friend's judgment logic
	if abs(delta_ms) <= PERFECT_WINDOW:
		result.hit = true
		result.judgment = JudgmentType.PERFECT
	elif abs(delta_ms) <= (PERFECT_WINDOW + GREAT_WINDOW):
		result.hit = true
		result.judgment = JudgmentType.GREAT
	else:
		result.hit = false
		result.judgment = JudgmentType.MISS

	return result

# Track swapping feature from friend's code
var key_track_map: Array = [0, 1, 2, 3, 4, 5]  # Maps keys to tracks

func swap_tracks(track1: int, track2: int):
	if track1 < 0 or track1 >= 6 or track2 < 0 or track2 >= 6:
		print("Invalid track indices for swap")
		return

	var temp = key_track_map[track1]
	key_track_map[track1] = key_track_map[track2]
	key_track_map[track2] = temp

	print("Swapped tracks %d and %d" % [track1, track2])

func get_track_for_key(key_index: int) -> int:
	if key_index < 0 or key_index >= 6:
		return key_index
	return key_track_map[key_index]

# Helper to check if a note should be auto-missed
func should_auto_miss(note: Dictionary, current_time: float) -> bool:
	var delta_ms = (current_time - note.time) * 1000.0
	return delta_ms > (PERFECT_WINDOW + GREAT_WINDOW)