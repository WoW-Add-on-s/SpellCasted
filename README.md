# SpellCasted

A World of Warcraft (Retail) addon that displays the icon of the spell you are currently casting, designed to be captured by OBS as a stream overlay.

---

## Features

- Displays the spell icon as soon as the cast starts
- Stays visible after the cast ends (always-on mode)
- Visual feedback on cast failure:
  - ❌ **Cancelled** — icon tinted red with a red cross overlay
  - ⚔️ **Interrupted** — icon tinted orange with a combat icon overlay
- **Spell history**: a row of the last few spells you actually cast, with its
  own position, size and direction, and the older ones fading out
- Settings panel in the same dark and gold look as the rest of the set
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
| **Unlock / Lock** | Allows dragging the icon, and the history row, anywhere on screen |
| **Reset** | Restores all settings to default and reloads the UI |
| **Show the history** | A row of the spells you last cast |
| **How many icons** | 2 to 12 (default: 5) |
| **Icon size** | 16 to 96 px (default: 48) |
| **Space between** | 0 to 24 px (default: 4) |
| **Older ones fade** | The further back a spell is, the fainter its icon |
| **Newest on the left** | Which end new spells appear at (default: the right) |
| **Fill with examples** | Puts placeholder icons in the row, so it can be placed without casting anything |
| **Empty** | Clears the row |

### Spell History

Only a cast that actually went through is written down: starting one, failing
one and being cut off are not casting. A spell that announces itself twice in a
row counts once. The row has its own position - unlock, drag it where you want
it, lock again - because on a stream layout it does not always want to sit under
the main icon.

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
