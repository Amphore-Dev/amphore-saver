![Kinogrida preview](preview.gif)

# Shades — macOS Screensaver

A macOS screensaver that generates animated geometric compositions with shifting shades of color. Ported from the [Shades web project](https://github.com/Amphore-Dev/Shades) (TypeScript/Canvas) to native Swift.

## ⚠️ Epilepsy Warning

The shades can produce rapidly flashing and shifting patterns that may trigger seizures in photosensitive individuals. Viewer discretion is advised.

## Shapes

The screensaver randomly cycles through five shape types:

- **Square** — filled or stroked rectangles
- **Circle** — filled or stroked ellipses
- **Spiral** — rotating arcs
- **Triangle** — filled or stroked triangles with optional rotation
- **Text** — displays the current time (HH:mm) using the custom _Remained_ font

Each scene is composed of a grid of shapes drawn multiple times with decreasing opacity, creating the signature "shades" effect. The offset drifts smoothly to animate the composition, and scenes auto-regenerate with a fade transition.

## Project Structure

```
Shades/
├── ShadesView.swift            # ScreenSaverView engine
├── types/                      # Data types (ShadeColor, ShadePoint, ShadeConfig…)
├── constants/                  # Colors, filters, constants
├── utils/                      # Math, color and config utilities
├── shapes/                     # BaseShape + 5 shape implementations
└── Resources/fonts/
    └── Remained.ttf            # Custom font
```

## Installation

1. Download `Kinogrida.saver` from [Releases](https://github.com/Amphore-Dev/Kinogrida-screensaver/releases)
2. Double-click the file — macOS will install it automatically
3. Open **System Settings → Screen Saver** and select Kinogrida

## Build from source

```
git clone https://github.com/Amphore-Dev/Kinogrida-screensaver.git
open Kinogrida.xcodeproj
```

Build the `Kinogrida` scheme. The `.saver` bundle is installed to `~/Library/Screen Savers`.

Requires Xcode with the macOS SDK.

```bash
# Build release
make

# Build + install to ~/Library/Screen Savers/
make install

# Remove
make remove

# Clean build artifacts
make clean
```

After `make install`, open **System Settings → Screen Saver** and select **Shades**.

## Requirements

macOS 11.5 or later
