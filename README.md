<p align="center">
  <img src="assets/icon.png" width="160" alt="Prompter icon">
</p>

<h1 align="center">Prompter</h1>

<p align="center">
  A minimal, lightweight teleprompter for macOS that sits right under your webcam.
</p>

<p align="center">
  <b>English</b> · <a href="README.tr.md">Türkçe</a>
</p>

---

Prompter is built for reading a script while recording yourself on camera. The window opens at the top center of the screen, right below the webcam, and stays above every other window, so your eyes barely leave the lens while you read. It is a single Swift/AppKit app with no Xcode project and no dependencies.

> The in-app interface is in Turkish. Everything is driven by the controls and the shortcuts listed below.

## Features

- **Always on top**: sits under the camera on every Space, including over full-screen apps.
- **Smooth scrolling**: adjustable speed. If you scroll by hand with the trackpad or mouse wheel, playback continues from where you left off.
- **Control bar**: appears at the bottom when you hover over the window. It controls:
  - background color and opacity,
  - text color and size,
  - scroll speed,
  - play/pause and open file.
- **Inline editing**: click the text to start editing, with the caret placed where you clicked. Press `Esc` to finish.
- **Loading text**: paste from the clipboard with `⌘V` or open a `.txt`/`.md` file with `⌘O`.
- **Remembers everything**: the script, colors, text size, speed and window position are kept between launches.

## Installation

### Download (recommended)

1. Download **`Prompter-<version>.dmg`** from the [latest release](https://github.com/serbestonline/Prompter/releases/latest).
2. Open it and drag **Prompter** onto **Applications**.
3. Launch Prompter from your Applications folder.

Requires **macOS 13 or later**. Runs natively on both Apple Silicon and Intel Macs.

> **First launch:** Prompter is not notarized by Apple, so the first time you open it macOS says it couldn't verify the app. Go to **System Settings › Privacy & Security**, scroll down and click **Open Anyway**. You only need to do this once.
> Or remove the quarantine flag in Terminal instead: `xattr -dr com.apple.quarantine /Applications/Prompter.app`

### Build from source

Requirements: macOS 13 or later and the Xcode Command Line Tools.

```bash
xcode-select --install          # if the Command Line Tools are not installed yet

git clone https://github.com/serbestonline/Prompter.git
cd Prompter
./build.sh --install            # builds and installs to ~/Applications
open ~/Applications/Prompter.app
```

| Command | Result |
|---|---|
| `./build.sh` | Builds a universal `build/Prompter.app` (Apple Silicon + Intel) |
| `./build.sh --install` | Also installs it to `~/Applications` |
| `./build.sh --dmg` | Also creates the drag-to-install `build/Prompter-<version>.dmg` (requires [uv](https://docs.astral.sh/uv/)) |

The version number is set at the top of `build.sh`.

## Usage

| Key | Action |
|---|---|
| `Space` | Play / pause |
| `↑` `↓` | Increase / decrease speed |
| `+` `−` | Larger / smaller text (`*` also enlarges on Turkish keyboards) |
| `←` `→` | Jump a few lines back / forward |
| `R` | Back to the top |
| `Esc` | Pause / finish editing |
| `⌘V` | Load text from the clipboard (replaces the current script) |
| `⌘O` | Open a text file |
| `⌘Q` | Quit |

Drag the window by its top edge to move it, and drag its edges to resize it.

To reset all settings:

```bash
defaults delete com.serbest.prompter
```

## Project structure

```text
Sources/
├── main.swift          # app, window, scrolling, keyboard and editing
├── ControlBar.swift    # hover control bar and HoverView
├── MainMenu.swift      # Edit menu so copy/paste/undo work while editing
└── ColorStore.swift    # saves and loads colors in UserDefaults
scripts/
├── make_icon.swift             # draws the app icon (1024×1024 PNG)
├── make_dmg_background.swift   # draws the DMG window background (1x + 2x)
└── dmg_settings.py             # DMG window layout for dmgbuild
assets/
└── icon.png
build.sh                        # build, icon, signing, install, DMG
```

## Known issues

- If the app quits while the color panel is open, macOS restores the panel on the next launch, and the control bar stays visible until you close the panel.

## License

[MIT](LICENSE)
