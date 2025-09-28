# UI Asset Guide

## Folder Structure

### `/assets/ui/song_covers/`
Place song cover images here. These are displayed in:
- Song selection screen (right panel)
- Loading transition screen

**File naming convention:**
- `demo.png` - for Demo Track
- `tutorial.png` - for Tutorial
- `electronic.png` - for Electronic Dream
- `sakura.png` - for Sakura Waltz

**Recommended size:** 400x225 pixels (16:9 aspect ratio)

### `/assets/ui/backgrounds/`
Place general background images here for:
- Game backgrounds
- Menu backgrounds (if different from selection screen)

### `/assets/ui/menu_backgrounds/`
Already contains:
- `Select_Menu.png` - Background shown when a song is selected
- `UnSelect_Menu.png` - Default background

## Adding New Songs

To add a new song with visuals:

1. Add the song cover image to `/assets/ui/song_covers/[songname].png`
2. Update `scripts/ui/song_database.gd` with the new song entry
3. Create a chart file in `/charts/[songname].json`
4. Optionally add a background image for the song in `/assets/ui/backgrounds/`

## Image Specifications

### Song Covers
- Format: PNG (preferred) or JPG
- Size: 400x225px recommended
- Will be scaled to fit while maintaining aspect ratio

### Backgrounds
- Format: PNG or JPG
- Size: 1280x720px or higher
- Will be stretched/cropped to fill screen

## Current Assets Status

✅ Menu selection backgrounds (Select_Menu.png, UnSelect_Menu.png)
⏳ Song covers - Ready for your images:
  - demo.png
  - tutorial.png
  - electronic.png
  - sakura.png
⏳ Song backgrounds - Ready for your images
