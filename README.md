# Staconf

Next-Generation Roblox Luau In-Game Console & UI Suite.

Built with an innovative design paradigm: high-contrast **Electric Blue (`#3B82F6`)** accent, decoupled 125% content scaling, embedded auto-revealing Dock with native vector icons, and macOS Sequoia styling.

---

## ⚡ Quick Load (UNC Compatible)

### 1. Innovative In-Game Console Deck
Independent prototype featuring dynamic hover dock, 125% decoupled inner scale, and pure vector icons:
```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/Staconf/main/console_ui_demo.luau"))()
```

### 2. Cascade Sequoia Deck
Sequoia-inspired desktop console powered by Cascade UI with Electric Blue contrast accents:
```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/Staconf/main/cascade_demo.luau"))()
```

### 3. Universal Entry Loader
```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/Staconf/main/init.luau"))()
```

---

## 🚀 Key Features

### In-Game Console Deck (`console_ui_demo.luau`)
- **Decoupled 125% Content Scaling**: Physical window frame remains compact at 740×490px while all internal components (cards, sliders, switches, buttons, text) are scaled up by 125% via an inverted canvas architecture.
- **Embedded Auto-Dock**: Floating bottom navigation bar embedded inside the main window. Sits hidden as a minimal white peekbar handle and smoothly rises with a `Quart` easing when the mouse enters the bottom sensor zone.
- **Pure Native Vector Icons**: Handcrafted procedural vector geometry for Controls (crosshair), Display (monitor), Audio (equalizer bars), Overview (2×2 grid), and System (microchip).
- **High-Contrast Dark Theme**: Deep charcoal `#101015` base paired with crisp white labels and vibrant Electric Blue accent highlights.
- **Zero Library Dependencies**: 100% native Luau implementation.

### Cascade Sequoia Deck (`cascade_demo.luau`)
- **macOS Sequoia Window Architecture**: Traffic light window controls, integrated toolbar search, draggable and resizable frames.
- **Multi-Matrix Routing**:
  - **Runtime Matrix**: Real-time Field of View slider, low-latency render toggles, engine ping, and instant GC memory collector.
  - **Environment**: Real-time ClockTime scrubber, global shadow switches, and ambient lighting presets.
  - **Player Dynamics**: WalkSpeed and JumpPower real-time sliders with instant default reset.
  - **Preferences**: Dynamic Accent color picker (defaults to Electric Blue), theme switching (Dark/Light), and customizable keybinds.
- **UNC Stealth Protection**: Seamless detection of `gethui()` -> `CoreGui` -> `PlayerGui` with `cloneref` anti-detection layer.

---

## ⌨️ Controls & Shortcuts

| Action | Shortcut |
| :--- | :--- |
| Toggle Console / Minimize | `RightControl` |
| Reveal Embedded Dock | Hover mouse at the bottom edge of the window |
| Reset Character Attributes | Locomotion -> "Reset to Default" |

---

## 🛠️ Requirements & Compatibility

- Compatible with all Level 7/8 UNC executors supporting standard Luau HTTP/loadstring capabilities.
- Safe fallback support for standard Roblox Studio test environments.
