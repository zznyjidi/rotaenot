# Level Creation Guide for Rotaenot

## Overview
This guide explains how to create new levels (songs) for Rotaenot, including charts, music, and visual assets.

## Quick Start Checklist
- [ ] 1. Add music file (.mp3) to `assets/music/`
- [ ] 2. Create chart file (.json) in `charts/`
- [ ] 3. Add song cover image to `assets/ui/song_covers/`
- [ ] 4. Register song in `scripts/ui/song_database.gd`
- [ ] 5. Test your level

## Detailed Instructions

### 1. Music File
Place your music file in `/assets/music/`:
- **Format**: MP3 (recommended), OGG also supported
- **Naming**: Use descriptive names like `Artist - Song Title.mp3`
- **Length**: 1-5 minutes recommended
- **Quality**: 192kbps or higher recommended

### 2. Chart File Structure
Create a JSON file in `/charts/` with this structure:

```json
{
  "version": 1,
  "bpm": 120,
  "offset": 0.0,
  "notes": [
    {
      "time": 1.0,
      "pad": 0,
      "type": "normal"
    },
    {
      "time": 2.0,
      "pad": 1,
      "switch_to": 2,
      "type": "switch"
    }
  ]
}
```

#### Chart Parameters:
- **version**: Chart format version (currently 1)
- **bpm**: Beats per minute of the song
- **offset**: Audio delay offset in seconds (usually 0)
- **notes**: Array of note objects

#### Note Types:

##### Normal Note
```json
{
  "time": 1.5,      // When the note reaches the pad (in seconds)
  "pad": 0,         // Which pad (0-5: W,E,F,J,I,O by default)
  "type": "normal"  // Regular hit note
}
```

##### Switch Note
```json
{
  "time": 2.0,
  "pad": 1,          // Starting pad
  "switch_to": 3,    // Target pad to switch to
  "type": "switch"   // Creates a track switch with jelly effect
}
```

#### Pad Numbering:
```
Left Side:          Right Side:
  0 (W)               3 (J)
  1 (E)               4 (I)
  2 (F)               5 (O)
```

### 3. Song Cover Image
Add cover art to `/assets/ui/song_covers/`:
- **Format**: PNG recommended
- **Size**: 400x225px (16:9 aspect ratio)
- **Naming**: Match the song ID (e.g., `my_song.png`)
- **Fallback**: NoImage.png displays if not found

### 4. Register in Song Database
Edit `/scripts/ui/song_database.gd` and add your song:

```gdscript
{
    "id": "my_song",                    # Unique identifier
    "title": "My Awesome Song",         # Display title
    "artist": "Artist Name",            # Artist name
    "bpm": 128,                         # BPM for display
    "duration": "3:24",                 # Song length
    "chart_path": "res://charts/my_song.json",
    "music_path": "res://assets/music/my_song.mp3",
    "preview_image": "res://assets/ui/song_covers/my_song.png",
    "difficulties": {
        "Easy": {"level": 3, "notes": 250},
        "Normal": {"level": 6, "notes": 420},
        "Hard": {"level": 9, "notes": 680}
    },
    "unlock_status": true,              # false to lock the song
    "high_scores": {
        "Easy": 0,
        "Normal": 0,
        "Hard": 0
    }
}
```

### 5. Multiple Difficulties
Create separate chart files for each difficulty:
- `my_song_easy.json`
- `my_song_normal.json`
- `my_song_hard.json`

Update the chart_path based on selected difficulty in your code.

## Chart Creation Tips

### Timing
- Notes spawn 3 seconds before hit time
- Account for visual travel time when timing notes
- Use offset parameter if audio is delayed

### Difficulty Guidelines

#### Easy (Level 1-3)
- 0.5-1 note per second
- Simple patterns
- Few or no track switches
- Focus on single pads

#### Normal (Level 4-7)
- 1-2 notes per second
- Basic patterns and combinations
- Occasional track switches
- Some alternating patterns

#### Hard (Level 8-10)
- 2-4 notes per second
- Complex patterns
- Frequent track switches
- Multi-pad combinations

#### Expert (Level 11-12)
- 4+ notes per second
- Very complex patterns
- Rapid track switches
- Full pad utilization

### Pattern Ideas
1. **Stairs**: Sequential pads (0→1→2 or 3→4→5)
2. **Alternating**: Back and forth (0→3→0→3)
3. **Trills**: Rapid alternation between two pads
4. **Jumps**: Simultaneous hits (add notes at same time)
5. **Streams**: Continuous note flow across multiple pads

## Testing Your Level

1. **Launch the game**
2. **Go to Song Select**
3. **Find your song** (check console for errors)
4. **Play through** each difficulty
5. **Check sync** between music and notes
6. **Adjust timing** as needed

## Common Issues

### Notes not appearing
- Check JSON syntax (use a JSON validator)
- Verify chart_path in database
- Check console for loading errors

### Music not playing
- Verify music file exists
- Check music_path in database
- Ensure file format is supported

### Wrong timing
- Adjust individual note times
- Use offset parameter for global adjustment
- Account for 3-second spawn lead time

## Advanced Features

### Custom Note Types
You can extend the note system by modifying `note_3d_v2.gd`:
```gdscript
"hold": duration,     # Hold notes (not yet implemented)
"slide": end_pad,     # Slide notes (not yet implemented)
```

### Beat Snapping
For precise timing, calculate beat positions:
```
beat_time = 60.0 / bpm
measure_time = beat_time * 4
note_time = measure_number * measure_time + beat_in_measure * beat_time
```

### Automation Tools
Consider creating:
- MIDI to chart converter
- Audio analysis for auto-generation
- Visual chart editor

## Example Charts

### Simple Pattern
```json
{
  "version": 1,
  "bpm": 120,
  "offset": 0,
  "notes": [
    {"time": 1.0, "pad": 0, "type": "normal"},
    {"time": 1.5, "pad": 1, "type": "normal"},
    {"time": 2.0, "pad": 2, "type": "normal"},
    {"time": 2.5, "pad": 3, "type": "normal"},
    {"time": 3.0, "pad": 4, "type": "normal"},
    {"time": 3.5, "pad": 5, "type": "normal"}
  ]
}
```

### With Track Switches
```json
{
  "version": 1,
  "bpm": 140,
  "offset": 0,
  "notes": [
    {"time": 1.0, "pad": 0, "type": "normal"},
    {"time": 2.0, "pad": 0, "switch_to": 3, "type": "switch"},
    {"time": 3.0, "pad": 3, "type": "normal"},
    {"time": 4.0, "pad": 3, "switch_to": 1, "type": "switch"},
    {"time": 5.0, "pad": 1, "type": "normal"}
  ]
}
```

## Contributing
If you create charts for popular songs, consider:
1. Sharing them with the community
2. Following copyright guidelines
3. Crediting original artists
4. Testing with multiple players

Happy charting!