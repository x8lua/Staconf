# Staconf

## Settings profiles

The Settings tab supports named local profiles, Save, Load, Refresh, Delete, startup loading, and restoring session defaults. Overwrite, Delete, and Reset require a second click within four seconds. Profile names accept 1–32 ASCII letters, numbers, spaces, hyphens, or underscores.

Profiles store 16 controls, including appearance, hotkey, camera, lighting, movement, and Glass Strength. Settings → Liquid Glass exposes a 1×–20× strength slider with a live multiplier label. The default is 4.5×; strength changes the main window curved lens depth and surface normals without changing window opacity. The lens uses an EditableMesh (434 vertices / 864 triangles), updated only when size, corner radius, or strength changes. Unsupported environments fall back to the supplied glass meshes. Existing profiles without this field leave the current strength unchanged. Loading applies the existing control callbacks. Pointer modal demo controls and account information are not included. Reset restores values captured when this script started; saved profiles are retained.

Curved-glass validation: isolated in-client previews at 1× and 20×, plus a non-refracting material control, used temporary straight background bars at unchanged 0.08 panel transparency. The 20× lens visibly curved the bars at graphics quality 10. Hide/show and teardown passed; temporary geometry was removed. This is not a guarantee of identical results on other graphics settings or executors. The complete application was not re-executed during this test.

Storage uses the executor workspace file `Staconf/settings-v1.json`, with the previous file copied to `Staconf/settings-v1.json.bak` before writes. Requires `readfile`, `writefile`, and `isfile`; folder creation is used when available. Corrupt or unsupported data blocks writes until repaired and refreshed. There is no cloud sync or background autosave.

Validation: 15 isolated Luau tests passed using mock controls and in-memory files, including startup loading and corrupt-file protection. Actual filesystem persistence and Settings layout have not been visually verified. The existing `collectgarbage("collect")` analyzer diagnostic is unrelated to this addition.

Next-Generation Roblox Luau In-Game Console & UI Suite.

Built with an innovative design paradigm: high-contrast **Electric Blue (`#3B82F6`)** accent, decoupled 125% content scaling, embedded auto-revealing Dock with native vector icons, and macOS Sequoia styling.

---

## ⚡ Quick Load (UNC Compatible)

### 1. Innovative In-Game Console Deck
Independent prototype featuring dynamic hover dock, 125% decoupled inner scale, and pure vector icons:
```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/Staconf/main/console_ui_demo.luau"))()
```

### 2. StacOnf Sequoia Deck
Sequoia-inspired desktop console powered by Cascade UI with Electric Blue contrast accents:
```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/Staconf/main/staconf_demo.luau"))()
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

### StacOnf Sequoia Deck (`staconf_demo.luau`)
- **macOS Sequoia Window Architecture**: Traffic light window controls, sidebar search above a local Sign in panel, draggable and resizable frames.
- **Compact Sidebar**: Semibold SF Pro tab titles, 2px tab gaps, solid sidebar/content surfaces without a seam divider, and one rounded outer clip. Sign in toggles a local demo account only; it does not authenticate or send credentials.
- **Responsive Pointer Panel**: SF Pro typography, synchronized theme colors, animated toggles and buttons, and a draggable slider with concise motion feedback.
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
