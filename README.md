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

Requirements: **macOS 13 or later** and the Xcode Command Line Tools.

```bash
xcode-select --install          # if the Command Line Tools are not installed yet

git clone https://github.com/serbestonline/Prompter.git
cd Prompter
./build.sh --install            # builds and installs to ~/Applications
open ~/Applications/Prompter.app
```

Running `./build.sh` without flags only builds the app to `build/Prompter.app` and installs nothing.

> The app is signed locally (ad-hoc), not with an Apple developer certificate. If you copy the built `.app` to another Mac, open it the first time with **right-click → Open**.

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
└── make_icon.swift     # draws the app icon (1024×1024 PNG)
assets/
└── icon.png
build.sh                # build, icon generation, signing, install
```

## Known issues

- If the app quits while the color panel is open, macOS restores the panel on the next launch, and the control bar stays visible until you close the panel.

## License

[MIT](LICENSE)
