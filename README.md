# SpellCasted

A World of Warcraft (Retail) addon that displays the icon of the spell you are currently casting, designed to be captured by OBS as a stream overlay.

---

## Features

- Displays the spell icon as soon as the cast starts
- Stays visible after the cast ends (always-on mode)
- Visual feedback on cast failure:
  - ❌ **Cancelled** — icon tinted red with a red cross overlay
  - ⚔️ **Interrupted** — icon tinted orange with a combat icon overlay
- Built-in configuration panel (no commands to memorize)
- Position, size, and opacity saved between sessions

---

## Installation

1. Download the `SpellCasted` folder
2. Place it in:
   ```
   World of Warcraft/_retail_/Interface/AddOns/SpellCasted/
   ```
3. Launch (or restart) the game
4. Enable the addon from the character selection screen
5. Type `/reload` in-game if needed

---

## Usage

Type `/sc` to open or close the configuration panel.

### Configuration Panel

| Option | Description |
|---|---|
| **Icon Size** | Slider from 32 to 512 px (default: 128) |
| **Opacity** | Slider from 0.10 to 1.00 (default: 1.0) |
| **Always show icon** | Checked = icon stays visible at all times with the last cast texture. Unchecked = icon disappears when not casting. |
| **Unlock / Lock** | Allows dragging the icon anywhere on screen |
| **Reset** | Restores all settings to default and reloads the UI |

### Moving the Icon

1. Open the panel with `/sc`
2. Click **Unlock**
3. Drag the icon to the desired position
4. Click **Lock**

---

## OBS Integration

1. Position the icon in WoW wherever you want it on screen
2. In OBS, add a **Game Capture** source
3. Use a **Crop/Pad filter** to isolate only the icon area
4. (Optional) For a transparent background, run WoW in windowed mode, use a **Window Capture** source, and apply a **Chroma Key** filter on the black background

---

## Compatibility

- **WoW Version**: Retail 11.0+ (Interface 120001)
- Tested on The War Within

---

## License

MIT — free to use and modify.
