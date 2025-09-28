"""
Chart Parser for Rotaenot
Handles beatmap/chart file parsing and generation
"""

import json
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from enum import Enum
import numpy as np


class NoteType(Enum):
    TAP = "tap"
    HOLD = "hold"
    CATCH = "catch"
    FLICK = "flick"
    ROTATION = "rotation"


@dataclass
class Note:
    """Represents a single note in the chart"""
    time: float  # Time in seconds
    position: float  # Angular position (0-360 degrees)
    note_type: NoteType
    duration: Optional[float] = None  # For hold notes
    direction: Optional[str] = None  # For flick notes
    rotation_speed: Optional[float] = None  # For rotation sections


@dataclass
class Chart:
    """Represents a complete chart/beatmap"""
    title: str
    artist: str
    bpm: float
    difficulty: int
    notes: List[Note]
    audio_file: str
    preview_time: float = 0.0
    offset: float = 0.0  # Audio offset in ms


class ChartParser:
    """Parse and generate chart files for the rhythm game"""

    def __init__(self):
        self.supported_formats = ['.json', '.txt', '.osu']

    def parse_chart(self, file_path: str) -> Chart:
        """
        Parse a chart file and return a Chart object

        Args:
            file_path: Path to the chart file

        Returns:
            Chart object containing all beatmap data
        """
        if file_path.endswith('.json'):
            return self._parse_json_chart(file_path)
        else:
            raise ValueError(f"Unsupported chart format: {file_path}")

    def _parse_json_chart(self, file_path: str) -> Chart:
        """Parse JSON format chart"""
        with open(file_path, 'r') as f:
            data = json.load(f)

        notes = []
        for note_data in data.get('notes', []):
            note = Note(
                time=note_data['time'],
                position=note_data['position'],
                note_type=NoteType(note_data['type']),
                duration=note_data.get('duration'),
                direction=note_data.get('direction'),
                rotation_speed=note_data.get('rotation_speed')
            )
            notes.append(note)

        return Chart(
            title=data['title'],
            artist=data['artist'],
            bpm=data['bpm'],
            difficulty=data['difficulty'],
            notes=notes,
            audio_file=data['audio_file'],
            preview_time=data.get('preview_time', 0.0),
            offset=data.get('offset', 0.0)
        )

    def generate_chart_from_audio(self, audio_file: str, difficulty: int = 1) -> Chart:
        """
        Generate a basic chart from audio analysis

        Args:
            audio_file: Path to audio file
            difficulty: Difficulty level (1-14)

        Returns:
            Generated Chart object
        """
        # This is a placeholder for audio analysis
        # In a real implementation, you'd analyze the audio for beats
        notes = self._generate_test_pattern(duration=180, difficulty=difficulty)

        return Chart(
            title="Generated Chart",
            artist="Unknown",
            bpm=120,
            difficulty=difficulty,
            notes=notes,
            audio_file=audio_file
        )

    def _generate_test_pattern(self, duration: float, difficulty: int) -> List[Note]:
        """Generate a test pattern of notes"""
        notes = []
        note_density = 2 + (difficulty * 0.5)  # Notes per second
        total_notes = int(duration * note_density)

        for i in range(total_notes):
            time = i / note_density
            position = (i * 45) % 360  # Spiral pattern

            # Mix different note types based on difficulty
            if difficulty > 5 and i % 7 == 0:
                note_type = NoteType.FLICK
            elif difficulty > 3 and i % 5 == 0:
                note_type = NoteType.CATCH
            elif difficulty > 7 and i % 11 == 0:
                note_type = NoteType.HOLD
            else:
                note_type = NoteType.TAP

            notes.append(Note(
                time=time,
                position=position,
                note_type=note_type,
                duration=0.5 if note_type == NoteType.HOLD else None
            ))

        return notes

    def save_chart(self, chart: Chart, file_path: str):
        """Save a chart to a file"""
        chart_data = {
            'title': chart.title,
            'artist': chart.artist,
            'bpm': chart.bpm,
            'difficulty': chart.difficulty,
            'audio_file': chart.audio_file,
            'preview_time': chart.preview_time,
            'offset': chart.offset,
            'notes': [
                {
                    'time': note.time,
                    'position': note.position,
                    'type': note.note_type.value,
                    'duration': note.duration,
                    'direction': note.direction,
                    'rotation_speed': note.rotation_speed
                }
                for note in chart.notes
            ]
        }

        with open(file_path, 'w') as f:
            json.dump(chart_data, f, indent=2)

    def validate_chart(self, chart: Chart) -> List[str]:
        """
        Validate a chart for common issues

        Returns:
            List of validation errors (empty if valid)
        """
        errors = []

        # Check for notes too close together
        for i in range(1, len(chart.notes)):
            time_diff = chart.notes[i].time - chart.notes[i-1].time
            if time_diff < 0.05:  # Less than 50ms apart
                errors.append(f"Notes too close at {chart.notes[i].time}s")

        # Check for invalid positions
        for note in chart.notes:
            if not 0 <= note.position < 360:
                errors.append(f"Invalid position {note.position} at {note.time}s")

        return errors