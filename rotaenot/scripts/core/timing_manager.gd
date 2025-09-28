extends Node

# Timing Manager
# Handles timing windows and judgment using millisecond precision
# Based on friend's improved timing system

class_name TimingManager

# Timing windows in milliseconds (from friend's code)
const PERFECT_WINDOW_MS = 30  # ±30ms for PERFECT
const GREAT_WINDOW_MS = 30    # ±30ms after perfect for GREAT
const GOOD_WINDOW_MS = 40     # ±40ms after great for GOOD
const BAD_WINDOW_MS = 50      # ±50ms after good for BAD

# Total window for hit detection
const MAX_HIT_WINDOW_MS = PERFECT_WINDOW_MS + GREAT_WINDOW_MS + GOOD_WINDOW_MS + BAD_WINDOW_MS  # 150ms

# Judgment types
enum Judgment {
	PERFECT,
	GREAT,
	GOOD,
	BAD,
	MISS
}

# Convert judgment to string for display
static func judgment_to_string(judgment: Judgment) -> String:
	match judgment:
		Judgment.PERFECT: return "PERFECT"
		Judgment.GREAT: return "GREAT"
		Judgment.GOOD: return "GOOD"
		Judgment.BAD: return "BAD"
		Judgment.MISS: return "MISS"
		_: return ""

# Get color for judgment type
static func judgment_to_color(judgment: Judgment) -> Color:
	match judgment:
		Judgment.PERFECT: return Color(1.0, 1.0, 0.0)  # Yellow
		Judgment.GREAT: return Color(0.0, 1.0, 0.0)    # Green
		Judgment.GOOD: return Color(0.3, 0.7, 1.0)     # Light Blue
		Judgment.BAD: return Color(1.0, 0.5, 0.0)      # Orange
		Judgment.MISS: return Color(1.0, 0.0, 0.0)     # Red
		_: return Color.WHITE

# Calculate judgment based on timing difference in milliseconds
static func calculate_judgment(delta_ms: float) -> Dictionary:
	var abs_delta = abs(delta_ms)
	var result = {
		"judgment": Judgment.MISS,
		"delta_ms": delta_ms,
		"is_early": delta_ms < 0,
		"is_hit": false,
		"accuracy": 0.0
	}

	# Check each timing window
	if abs_delta <= PERFECT_WINDOW_MS:
		result.judgment = Judgment.PERFECT
		result.is_hit = true
		result.accuracy = 1.0 - (abs_delta / PERFECT_WINDOW_MS) * 0.1  # 90-100%
	elif abs_delta <= PERFECT_WINDOW_MS + GREAT_WINDOW_MS:
		result.judgment = Judgment.GREAT
		result.is_hit = true
		result.accuracy = 0.75 - ((abs_delta - PERFECT_WINDOW_MS) / GREAT_WINDOW_MS) * 0.15  # 60-75%
	elif abs_delta <= PERFECT_WINDOW_MS + GREAT_WINDOW_MS + GOOD_WINDOW_MS:
		result.judgment = Judgment.GOOD
		result.is_hit = true
		result.accuracy = 0.5 - ((abs_delta - PERFECT_WINDOW_MS - GREAT_WINDOW_MS) / GOOD_WINDOW_MS) * 0.2  # 30-50%
	elif abs_delta <= MAX_HIT_WINDOW_MS:
		result.judgment = Judgment.BAD
		result.is_hit = true
		result.accuracy = 0.1  # 10%
	else:
		result.judgment = Judgment.MISS
		result.is_hit = false
		result.accuracy = 0.0

	return result

# Check if a note should be auto-missed (too late)
static func should_auto_miss(note_time_ms: float, current_time_ms: float) -> bool:
	var delta_ms = current_time_ms - note_time_ms
	return delta_ms > MAX_HIT_WINDOW_MS

# Check if a note is in the hittable window
static func is_in_hit_window(note_time_ms: float, current_time_ms: float) -> bool:
	var delta_ms = abs(current_time_ms - note_time_ms)
	return delta_ms <= MAX_HIT_WINDOW_MS

# Convert seconds to milliseconds
static func seconds_to_ms(seconds: float) -> float:
	return seconds * 1000.0

# Convert milliseconds to seconds
static func ms_to_seconds(ms: float) -> float:
	return ms / 1000.0

# Calculate score multiplier based on judgment
static func get_score_multiplier(judgment: Judgment) -> float:
	match judgment:
		Judgment.PERFECT: return 1.0
		Judgment.GREAT: return 0.75
		Judgment.GOOD: return 0.5
		Judgment.BAD: return 0.25
		Judgment.MISS: return 0.0
		_: return 0.0

# Calculate combo multiplier (breaks on BAD or MISS)
static func should_break_combo(judgment: Judgment) -> bool:
	return judgment == Judgment.BAD or judgment == Judgment.MISS

# Get life change based on judgment and difficulty
static func get_life_change(judgment: Judgment, difficulty: String = "Normal") -> int:
	var base_change = {
		Judgment.PERFECT: 2,
		Judgment.GREAT: 1,
		Judgment.GOOD: 0,
		Judgment.BAD: -5,
		Judgment.MISS: -10
	}

	var change = base_change.get(judgment, 0)

	# Adjust based on difficulty
	match difficulty:
		"Easy":
			if change < 0:
				change = int(change * 0.5)  # Less punishment
			else:
				change = int(change * 1.5)  # More reward
		"Hard", "Expert":
			if change < 0:
				change = int(change * 1.5)  # More punishment
		"Hell":
			if change < 0:
				change = int(change * 2.0)  # Double punishment

	return change