"""
Score System for Rotaenot
Handles score calculation, combo tracking, and rating system
"""

from dataclasses import dataclass
from enum import Enum
from typing import List, Tuple, Optional
import math


class JudgmentType(Enum):
    """Note judgment types based on timing accuracy"""
    PERFECT = "perfect"
    GREAT = "great"
    GOOD = "good"
    MISS = "miss"


@dataclass
class JudgmentWindow:
    """Timing windows for note judgments (in milliseconds)"""
    perfect: float = 40.0
    great: float = 80.0
    good: float = 120.0


@dataclass
class ScoreData:
    """Complete score information for a play session"""
    total_score: int
    accuracy: float
    max_combo: int
    perfect_count: int
    great_count: int
    good_count: int
    miss_count: int
    full_combo: bool


class ScoreCalculator:
    """Calculate scores and ratings for gameplay"""

    def __init__(self):
        self.judgment_windows = JudgmentWindow()
        self.reset()

    def reset(self):
        """Reset the score calculator for a new play session"""
        self.current_score = 0
        self.current_combo = 0
        self.max_combo = 0
        self.perfect_count = 0
        self.great_count = 0
        self.good_count = 0
        self.miss_count = 0
        self.total_notes = 0

    def judge_note(self, time_difference: float) -> JudgmentType:
        """
        Judge a note based on timing difference

        Args:
            time_difference: Time difference in milliseconds between
                           actual hit and perfect timing

        Returns:
            Judgment type
        """
        abs_diff = abs(time_difference)

        if abs_diff <= self.judgment_windows.perfect:
            return JudgmentType.PERFECT
        elif abs_diff <= self.judgment_windows.great:
            return JudgmentType.GREAT
        elif abs_diff <= self.judgment_windows.good:
            return JudgmentType.GOOD
        else:
            return JudgmentType.MISS

    def process_note_hit(self, judgment: JudgmentType,
                        base_note_score: int = 1000) -> int:
        """
        Process a note hit and update score

        Args:
            judgment: The judgment type for the hit
            base_note_score: Base score value for a perfect note

        Returns:
            Score gained from this note
        """
        self.total_notes += 1

        # Score multipliers based on judgment
        multipliers = {
            JudgmentType.PERFECT: 1.0,
            JudgmentType.GREAT: 0.8,
            JudgmentType.GOOD: 0.5,
            JudgmentType.MISS: 0.0
        }

        # Update counts
        if judgment == JudgmentType.PERFECT:
            self.perfect_count += 1
            self.current_combo += 1
        elif judgment == JudgmentType.GREAT:
            self.great_count += 1
            self.current_combo += 1
        elif judgment == JudgmentType.GOOD:
            self.good_count += 1
            self.current_combo += 1
        else:  # MISS
            self.miss_count += 1
            self.current_combo = 0

        # Update max combo
        self.max_combo = max(self.max_combo, self.current_combo)

        # Calculate score (Rotaeno doesn't use combo for score)
        score_gained = int(base_note_score * multipliers[judgment])
        self.current_score += score_gained

        return score_gained

    def get_accuracy(self) -> float:
        """
        Calculate current accuracy percentage

        Returns:
            Accuracy as a percentage (0-100)
        """
        if self.total_notes == 0:
            return 100.0

        weighted_hits = (
            self.perfect_count * 1.0 +
            self.great_count * 0.8 +
            self.good_count * 0.5
        )
        return (weighted_hits / self.total_notes) * 100

    def get_letter_grade(self) -> str:
        """
        Get letter grade based on accuracy

        Returns:
            Letter grade (SSS, SS, S, A, B, C, D)
        """
        accuracy = self.get_accuracy()

        if accuracy >= 100:
            return "SSS"
        elif accuracy >= 98:
            return "SS"
        elif accuracy >= 95:
            return "S"
        elif accuracy >= 90:
            return "A"
        elif accuracy >= 80:
            return "B"
        elif accuracy >= 70:
            return "C"
        else:
            return "D"

    def calculate_rating(self, chart_difficulty: int) -> float:
        """
        Calculate rating for B40 system

        Args:
            chart_difficulty: The difficulty level of the chart (1-14)

        Returns:
            Rating value for this play
        """
        accuracy = self.get_accuracy()

        # Base rating from chart difficulty
        base_rating = chart_difficulty

        # Accuracy modifier
        if accuracy >= 100:
            modifier = 2.0
        elif accuracy >= 98:
            modifier = 1.5
        elif accuracy >= 95:
            modifier = 1.0
        elif accuracy >= 90:
            modifier = 0.5
        elif accuracy >= 80:
            modifier = 0.0
        else:
            modifier = -0.5

        rating = base_rating + modifier
        return max(0, rating)  # Ensure non-negative

    def get_final_score_data(self) -> ScoreData:
        """
        Get final score data for the play session

        Returns:
            Complete ScoreData object
        """
        return ScoreData(
            total_score=self.current_score,
            accuracy=self.get_accuracy(),
            max_combo=self.max_combo,
            perfect_count=self.perfect_count,
            great_count=self.great_count,
            good_count=self.good_count,
            miss_count=self.miss_count,
            full_combo=(self.miss_count == 0 and self.total_notes > 0)
        )

    def calculate_theoretical_max(self, total_notes: int,
                                base_note_score: int = 1000) -> int:
        """
        Calculate theoretical maximum score for a chart

        Args:
            total_notes: Total number of notes in the chart
            base_note_score: Base score per note

        Returns:
            Maximum possible score
        """
        return total_notes * base_note_score


class B40Calculator:
    """Calculate B40 (Best 40) rating for player profile"""

    def __init__(self):
        self.scores = []

    def add_score(self, song_id: str, difficulty: int,
                 rating: float, timestamp: int):
        """Add a score to the B40 calculation"""
        self.scores.append({
            'song_id': song_id,
            'difficulty': difficulty,
            'rating': rating,
            'timestamp': timestamp
        })

    def calculate_b40(self) -> Tuple[float, List[dict]]:
        """
        Calculate B40 rating

        Returns:
            Tuple of (total B40 rating, list of best 40 scores)
        """
        # Group by song and keep only best score per song
        best_by_song = {}
        for score in self.scores:
            key = score['song_id']
            if key not in best_by_song or score['rating'] > best_by_song[key]['rating']:
                best_by_song[key] = score

        # Sort by rating and take top 40
        sorted_scores = sorted(best_by_song.values(),
                              key=lambda x: x['rating'],
                              reverse=True)[:40]

        # Calculate total B40
        total_rating = sum(score['rating'] for score in sorted_scores)

        return total_rating, sorted_scores