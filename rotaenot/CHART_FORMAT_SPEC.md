# Rotaenot Chart Format Specification v1.0

## File Format
Charts are stored as JSON files with the `.json` extension in the `/charts/` directory.

## Root Structure
```json
{
  "version": 1,
  "bpm": 120,
  "offset": 0.0,
  "metadata": {},
  "notes": []
}
```

### Required Fields

#### `version` (integer)
- Current version: `1`
- Used for backwards compatibility

#### `bpm` (integer)
- Beats per minute of the song
- Range: 60-300
- Used for beat snapping and visual guides

#### `offset` (float)
- Audio synchronization offset in seconds
- Positive values delay notes
- Negative values advance notes
- Default: `0.0`

#### `notes` (array)
- Array of note objects
- Sorted by time (ascending)

### Optional Fields

#### `metadata` (object)
- Additional information about the chart
- All fields optional:
  ```json
  {
    "title": "Song Name",
    "artist": "Artist Name",
    "charter": "Chart Creator",
    "difficulty": "Normal",
    "level": 5,
    "preview_start": 30.0,
    "preview_duration": 10.0
  }
  ```

## Note Object Structure

### Basic Note
```json
{
  "time": 1.5,
  "pad": 0,
  "type": "normal"
}
```

### Switch Note
```json
{
  "time": 2.0,
  "pad": 1,
  "switch_to": 3,
  "type": "switch"
}
```

### Note Fields

#### `time` (float, required)
- Time in seconds when note reaches the pad
- Must be positive
- Precision: 0.001 seconds (milliseconds)

#### `pad` (integer, required)
- Target pad index (0-5)
- Mapping:
  ```
  0: Left Top    (W key)
  1: Left Mid    (E key)
  2: Left Bot    (F key)
  3: Right Top   (J key)
  4: Right Mid   (I key)
  5: Right Bot   (O key)
  ```

#### `type` (string, required)
- Note type identifier
- Current types:
  - `"normal"`: Standard hit note
  - `"switch"`: Track switching note

#### `switch_to` (integer, conditional)
- Required for `"switch"` type notes
- Target pad for track switch (0-5)
- Must be different from `pad`

#### `comment` (string, optional)
- Developer comment, ignored by game
- Useful for chart organization

## Extended Note Types (Future)

### Hold Note (Planned)
```json
{
  "time": 3.0,
  "pad": 0,
  "type": "hold",
  "duration": 2.0
}
```

### Slide Note (Planned)
```json
{
  "time": 4.0,
  "pad": 0,
  "type": "slide",
  "end_pad": 2,
  "duration": 1.0
}
```

### Rotation Note (Planned)
```json
{
  "time": 5.0,
  "type": "rotate",
  "direction": "cw",
  "degrees": 180
}
```

## Timing Calculations

### Beat Alignment
```
beat_duration = 60.0 / bpm
measure_duration = beat_duration * 4

// For note on beat 2 of measure 3:
time = (3 * measure_duration) + (2 * beat_duration)
```

### Common Timings (120 BPM)
- Beat: 0.5 seconds
- Measure: 2.0 seconds
- 8th note: 0.25 seconds
- 16th note: 0.125 seconds

## Best Practices

### Note Density
- **Easy**: 0.5-1.0 notes/second
- **Normal**: 1.0-2.0 notes/second
- **Hard**: 2.0-3.0 notes/second
- **Expert**: 3.0+ notes/second

### Track Switches
- Minimum 0.5 seconds between switches
- Avoid switching during dense patterns
- Use for emphasis or transitions

### Patterns
1. **Readable**: Players should understand the pattern
2. **Fair**: Physically possible to hit
3. **Musical**: Follow the rhythm and melody
4. **Progressive**: Difficulty should build gradually

## Validation Rules

### Required Validations
1. All note times must be positive
2. Pad indices must be 0-5
3. Switch targets must differ from source pad
4. Notes should be sorted by time

### Recommended Validations
1. No two notes on same pad within 0.1 seconds
2. Track switches at least 0.3 seconds apart
3. First note after 1.0 seconds (give player time)
4. Last note before audio ends

## Example: Simple Chart
```json
{
  "version": 1,
  "bpm": 128,
  "offset": 0.0,
  "notes": [
    {"time": 2.000, "pad": 0, "type": "normal"},
    {"time": 2.469, "pad": 1, "type": "normal"},
    {"time": 2.938, "pad": 2, "type": "normal"},
    {"time": 3.406, "pad": 3, "type": "normal"},
    {"time": 3.875, "pad": 4, "type": "normal"},
    {"time": 4.344, "pad": 5, "type": "normal"}
  ]
}
```

## Example: Complex Pattern
```json
{
  "version": 1,
  "bpm": 140,
  "offset": -0.05,
  "metadata": {
    "title": "Complex Example",
    "difficulty": "Hard",
    "level": 8
  },
  "notes": [
    {"time": 2.0, "pad": 0, "type": "normal"},
    {"time": 2.0, "pad": 3, "type": "normal"},
    {"time": 2.214, "pad": 1, "type": "normal"},
    {"time": 2.214, "pad": 4, "type": "normal"},
    {"time": 2.429, "pad": 2, "switch_to": 5, "type": "switch"},
    {"time": 2.643, "pad": 5, "type": "normal"},
    {"time": 2.857, "pad": 4, "type": "normal"},
    {"time": 3.071, "pad": 3, "switch_to": 0, "type": "switch"}
  ]
}
```

## Error Handling

### Parser Errors
- Invalid JSON: Show line number
- Missing required fields: List fields
- Invalid values: Show constraints

### Runtime Errors
- Note out of bounds: Skip note
- Invalid switch: Treat as normal note
- Negative time: Skip note

## Version History

### v1.0 (Current)
- Basic note types (normal, switch)
- 6-pad system
- BPM and offset support
- Metadata structure

### v2.0 (Planned)
- Hold notes
- Slide notes
- Rotation triggers
- Multi-difficulty in single file
- Bookmark system

## Tools and Utilities

### Validation Script
```python
# validate_chart.py
import json

def validate_chart(filepath):
    with open(filepath) as f:
        chart = json.load(f)

    assert chart['version'] == 1
    assert 60 <= chart['bpm'] <= 300
    assert isinstance(chart['notes'], list)

    for note in chart['notes']:
        assert 0 <= note['pad'] <= 5
        assert note['time'] > 0
        assert note['type'] in ['normal', 'switch']

        if note['type'] == 'switch':
            assert 'switch_to' in note
            assert note['switch_to'] != note['pad']
```

### Conversion from Other Formats
- StepMania (.sm) → Rotaenot (.json)
- osu! (.osu) → Rotaenot (.json)
- MIDI (.mid) → Rotaenot (.json)

## Community Standards
- Use semantic filenames: `artist_song_difficulty.json`
- Include metadata for credits
- Test all difficulties before sharing
- Provide audio separately (respect copyright)