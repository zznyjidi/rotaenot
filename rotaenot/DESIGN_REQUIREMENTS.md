# Rotaenot Design Requirements - 3D Perspective Rhythm Game

## Core Visual Design

### Playfield Shape
- **Olive/Ellipse shape**: Tall oval that extends beyond screen top and bottom
- **Middle compression**: The center area is thinner (pinched) creating a larger curve
- **3D Perspective**: Creates illusion of depth with center being "far" and edges being "close"
- **Visible portion**: Only the side curves are visible on screen (top and bottom cut off)

### Fixed Pad System (6 Pads)
- **Layout**: 3 pads on each side (left and right)
- **Positions per side**:
  - Top pad
  - Middle pad
  - Bottom pad
- **Keyboard controls**: Each pad mapped to a specific key
  - Left side: Q (top), A (middle), Z (bottom)
  - Right side: P (top), L (middle), M (bottom)
- **No rotation needed**: Pads are fixed in position

### Track Lines
- **6 tracks total**: One line from center area to each pad
- **Perspective effect**: Lines converge toward center (vanishing point)
- **Visual style**: Track lines show the path notes will travel

### Note Design
- **Shape**: Rectangular/trapezoid with perspective
- **Appearance**: Notes appear to come from far (small) to near (large)
- **Four corners**: Each corner follows the track line boundaries
- **3D effect**: Notes stretch and grow as they approach pads

### Center UI
- **Score display**: Positioned in center
- **Combo counter**: Below score
- **Note spawn area**: Notes emerge from around the center UI (not directly from center point)

## Visual Perspective Details

### 3D Illusion Elements
1. **Size scaling**: Objects smaller in center, larger at edges
2. **Track convergence**: Lines meet at vanishing point
3. **Note transformation**: Rectangular notes morph with perspective
4. **Depth layers**: Background → Tracks → Notes → UI

### Screen Layout
```
     [TOP CUT OFF]
   /               \
  |   Q         P   |  <- Top pads
  |               |
  |   A    [SCORE]  L   |  <- Middle pads + Center UI
  |      [COMBO]    |
  |               |
  |   Z         M   |  <- Bottom pads
   \               /
     [BOTTOM CUT OFF]
```

## Implementation Notes
- Focus on visual clarity and 3D depth perception
- Notes should clearly telegraph which pad they're heading to
- Smooth perspective scaling as notes travel
- Clear hit zones for each pad