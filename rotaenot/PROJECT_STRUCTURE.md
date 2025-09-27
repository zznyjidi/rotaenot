# Rotaenot - Rotaeno-like Rhythm Game Project Structure

## Project Overview
A Rotaeno-inspired rhythm game built with Godot 4.5 and Python backend support.

## Core Gameplay Mechanics (Based on Rotaeno)
- **Circular Playfield**: Notes travel from center to edge
- **Rotation Control**: Use device gyroscope/accelerometer for rotation
- **Note Types**:
  - Tap Notes: Standard rhythm game taps
  - Catch Notes: Must be within rotation "basket" areas
  - Flick Notes: Directional swipe notes (higher difficulties)
  - Hold Notes: Long press notes
- **Judgment Circle**: Outer ring where notes are judged
- **Dual Basket System**: Left and right collection areas

## Directory Structure

```
rotaenot/
├── project.godot          # Godot project configuration
├── scenes/                # Godot scene files (.tscn)
│   ├── main_menu/         # Main menu scenes
│   ├── gameplay/          # Core gameplay scenes
│   ├── ui/                # UI components
│   └── effects/           # Visual effects scenes
├── scripts/               # GDScript files
│   ├── core/              # Core game logic
│   ├── input/             # Input handling (rotation, touch)
│   ├── notes/             # Note types and behaviors
│   └── scoring/           # Score calculation system
├── resources/             # Game assets
│   ├── audio/             # Music and sound effects
│   │   ├── songs/         # Game songs
│   │   └── sfx/           # Sound effects
│   ├── textures/          # Images and sprites
│   │   ├── notes/         # Note sprites
│   │   ├── ui/            # UI elements
│   │   └── backgrounds/   # Background images
│   └── fonts/             # Font files
├── data/                  # Game data files
│   ├── charts/            # Song charts (beatmaps)
│   ├── settings/          # Configuration files
│   └── scores/            # High score data
├── python_backend/        # Python integration
│   ├── chart_parser.py    # Parse and generate charts
│   ├── score_system.py    # Advanced scoring calculations
│   ├── gyro_processor.py  # Process gyroscope data
│   └── server.py          # Backend server (if needed)
└── docs/                  # Documentation
	└── DEVELOPMENT.md     # Development notes
```

## Technical Stack
- **Engine**: Godot 4.5
- **Primary Language**: GDScript
- **Backend Support**: Python (via Godot-Python bridge)
- **Platform Target**: Mobile (Android/iOS) + PC for development

## Development Phases

### Phase 1: Core Setup ✅
- Project structure creation
- Basic Godot configuration
- Python integration setup

### Phase 2: Basic Mechanics (Current)
- Circular playfield implementation
- Basic note spawning system
- Touch input handling
- Rotation input simulation (for PC testing)

### Phase 3: Gameplay Systems
- Note types implementation
- Scoring system
- Combo mechanics
- Judgment system (Perfect, Great, Good, Miss)

### Phase 4: Advanced Features
- Gyroscope integration
- Chart editor
- Song selection menu
- Difficulty system

### Phase 5: Polish
- Visual effects
- Audio synchronization
- Performance optimization
- Mobile deployment

## Key Components to Implement

1. **GameManager**: Central game state controller
2. **NoteSpawner**: Handles note generation from charts
3. **InputManager**: Processes rotation and touch inputs
4. **ScoreManager**: Tracks score, combo, and accuracy
5. **ChartLoader**: Loads and parses beatmap data
6. **RotationController**: Manages playfield rotation
