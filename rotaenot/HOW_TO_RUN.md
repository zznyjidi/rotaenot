# How to Run the Rotaenot Demo

## Quick Start

1. **Open Godot 4.5+**
2. **Import the project**: Click "Import" and select `rotaenot/project.godot`
3. **Press F5** or click the Play button to run the game

## What You'll See

### Main Menu
- Simple menu with "PLAY DEMO" button
- Click to start the game

### Gameplay Demo Features

#### Visual Elements:
- **Circular playfield** with judgment circles
- **Notes spawning** from the center moving outward
- **Rotation indicator** (yellow line) showing current rotation
- **Left/Right baskets** (orange and blue arcs) that light up when active
- **Score, Combo, and Accuracy display**
- **Judgment feedback** (PERFECT, GREAT, GOOD, MISS)

#### Controls:
- **Mouse**: Move mouse around the screen to rotate the playfield
- **Keyboard**:
  - `A` or `←`: Rotate left
  - `D` or `→`: Rotate right
  - `Space` or `Mouse Click`: Hit notes
  - `ESC` or `P`: Pause game

## How to Play

1. **Notes spawn from the center** and move toward the outer judgment circle
2. **Hit notes** when they reach the judgment circle (outer ring)
3. **Timing matters**:
   - PERFECT: Very close to the judgment line (gold effect)
   - GREAT: Good timing (green effect)
   - GOOD: Acceptable timing (blue effect)
   - MISS: Too early/late (red effect)

4. **Catch Notes** (yellow): Must be in the correct basket (left/right) when hit
5. **Regular Notes** (cyan): Can be hit from any rotation

## Features Implemented

✅ **Core Systems**:
- Game state management
- Score and combo tracking
- Note spawning system
- Rotation control (mouse and keyboard)
- Visual feedback for hits/misses

✅ **Visual Polish**:
- Animated judgment text
- Color-coded notes by type
- Dynamic basket highlighting
- Scaling effects on note approach
- Hit effects with color feedback

✅ **UI Elements**:
- Main menu
- In-game HUD
- Pause menu
- Score/combo/accuracy display

## Known Limitations (Demo Version)

- No audio/music yet
- Limited note patterns (demo loop)
- No gyroscope support (desktop only)
- No chart loading from files yet
- Python backend prepared but not integrated

## Next Development Steps

To continue development:
1. Add audio synchronization
2. Implement chart file loading
3. Add more note types (hold, flick)
4. Create level selection
5. Integrate Python backend for advanced features
6. Add mobile gyroscope support

## Troubleshooting

If the game doesn't run:
1. Make sure you're using Godot 4.5 or newer
2. Check that all scene files are present
3. Verify the main scene is set to `res://scenes/main_menu/main_menu.tscn`
4. Try reimporting the project

The demo is fully functional and ready to play!