# Rotaenot Development Guide

## Project Setup Complete!

The Rotaeno-like rhythm game project has been set up with the following features:

### Core Components Implemented

#### 1. Game Architecture (GDScript)
- **GameManager** (`scripts/core/game_manager.gd`): Central game state controller
- **RotationController** (`scripts/input/rotation_controller.gd`): Handles rotation input (mouse, keyboard, gyro)
- **NoteBase** (`scripts/notes/note_base.gd`): Base class for all note types
- **PythonBridge** (`scripts/core/python_bridge.gd`): Interface between Godot and Python backend

#### 2. Python Backend
- **ChartParser** (`python_backend/chart_parser.py`): Parse and generate beatmaps
- **ScoreSystem** (`python_backend/score_system.py`): Advanced scoring and rating calculations
- **GyroProcessor** (`python_backend/gyro_processor.py`): Process gyroscope/accelerometer data

#### 3. Input Controls
- **Mouse**: Point to rotate the playfield
- **Keyboard**:
  - `A` / `←`: Rotate left
  - `D` / `→`: Rotate right
  - `Space` / `Click`: Tap notes
  - `ESC` / `P`: Pause game

### How to Run

1. **Install Python dependencies**:
   ```bash
   cd rotaenot/python_backend
   pip install -r requirements.txt
   ```

2. **Open in Godot**:
   - Launch Godot 4.5+
   - Import the project from `rotaenot/project.godot`
   - The project will compile shaders on first run

3. **Test the game**:
   - A test chart is available at `data/charts/test_chart.json`
   - Run the project in Godot editor (F5)

### Next Steps for Development

#### Phase 1: Visual Implementation (Priority)
- [ ] Create circular playfield scene
- [ ] Implement note spawning from center
- [ ] Add judgment circle visualization
- [ ] Create basket indicators (left/right)

#### Phase 2: Gameplay Polish
- [ ] Add visual effects for note hits
- [ ] Implement combo display
- [ ] Create score UI
- [ ] Add audio synchronization

#### Phase 3: Chart System
- [ ] Build chart editor
- [ ] Support multiple difficulty levels
- [ ] Implement chart validation

#### Phase 4: Mobile Deployment
- [ ] Configure Android export
- [ ] Test gyroscope controls
- [ ] Optimize performance

### Game Mechanics Summary

Based on Rotaeno research:
- **Circular playfield** with notes moving from center to edge
- **Rotation control** via device gyroscope (or mouse/keyboard for testing)
- **Note types**: Tap, Hold, Catch, Flick, Rotation
- **Judgment system**: Perfect, Great, Good, Miss
- **Scoring**: Based on accuracy only (no combo multiplier)
- **B40 rating system**: Best 40 plays determine player rating

### Python Integration

The Python backend can be called from GDScript using the PythonBridge:

```gdscript
var python_bridge = preload("res://scripts/core/python_bridge.gd").new()

# Parse a chart file
var chart = python_bridge.parse_chart("res://data/charts/song.json")

# Calculate score
var score_data = python_bridge.calculate_score(note_results)

# Process gyro data
var rotation = python_bridge.process_gyro_data(sensor_data)
```

### Testing Without Hardware

For development without a gyroscope:
1. Use mouse to rotate playfield (point around screen center)
2. Use A/D or arrow keys for rotation
3. Press Space or click to hit notes

### Important Files

- **Project structure**: `PROJECT_STRUCTURE.md`
- **Development notes**: This file
- **Test chart**: `data/charts/test_chart.json`
- **Python requirements**: `python_backend/requirements.txt`

### Git Branch Policy

- **DO NOT** merge or push to `main` branch
- All development happens on `Rick` branch
- Create feature branches from `Rick` if needed

Happy coding! The foundation is ready for building the full game.