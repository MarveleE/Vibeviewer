## Vibeviewer

English | [简体中文](README.zh-CN.md)

![Swift](https://img.shields.io/badge/Swift-5.10-orange?logo=swift)
![Xcode](https://img.shields.io/badge/Xcode-15.4%2B-blue?logo=xcode)
![macOS](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![License](https://img.shields.io/badge/License-MIT-green)
![Release](https://img.shields.io/badge/Release-DMG-purple)

![Preview](Images/image.png)

**Tags**: `swift`, `swiftui`, `xcode`, `tuist`, `macos`, `menu-bar`, `release`

An open-source macOS menu bar app that surfaces workspace/team usage and spend at a glance, with sign-in, settings, auto-refresh, and sharing capabilities. The project follows a modular Swift Package architecture and a pure SwiftUI MV (not MVVM) approach, emphasizing clear boundaries and replaceability.

### Features
- **Menu bar summary**: Show key metrics (e.g., total spend) and reveal details in a popover.
- **Sign-in & Settings**: Dedicated windows with persisted credentials and preferences.
- **Power-aware refresh**: Smart refresh strategy reacting to screen power/activity state.
- **Modular architecture**: One-way dependencies Core ← Model ← API ← Feature; DTO→Domain mapping lives in API only.
- **Sharing components**: Built-in fonts and assets to generate shareable views.

### Notes
- Currently developed and tested against **team accounts** only. Individual/free accounts are not yet verified — contributions for compatibility are welcome.
- Thanks to the modular layered design, although Cursor is the present data source, other similar apps can be integrated by implementing the corresponding data-layer interfaces — PRs are welcome.
- The app currently has no logo — designers are welcome to contribute one.

> Brand and data sources are for demonstration. The UI never sees concrete networking implementations — only service protocols and default implementations are exposed.

---

## Architecture & Structure

Workspace with multiple Swift Packages (one-way dependency: Core ← Model ← API ← Feature):

```
Vibeviewer/
├─ Vibeviewer.xcworkspace           # Open this workspace
├─ Vibeviewer/                      # Thin app shell (entry only)
├─ Packages/
│  ├─ VibeviewerCore/               # Core: utilities/extensions/shared services
│  ├─ VibeviewerModel/              # Model: pure domain entities (value types/Sendable)
│  ├─ VibeviewerAPI/                # API: networking/IO + DTO→Domain mapping (protocols exposed)
│  ├─ VibeviewerAppEnvironment/     # Environment injection & cross-feature services
│  ├─ VibeviewerStorage/            # Storage (settings, credentials, etc.)
│  ├─ VibeviewerLoginUI/            # Feature: login UI
│  ├─ VibeviewerMenuUI/             # Feature: menu popover UI (main)
│  ├─ VibeviewerSettingsUI/         # Feature: settings UI
│  └─ VibeviewerShareUI/            # Feature: sharing components & assets
└─ Scripts/ & Makefile              # Tuist generation, clean, DMG packaging
```

Key rules (see also `./.cursor/rules/architecture.mdc`):
- **Placement & responsibility**
  - Core/Shared → utilities & extensions
  - Model → pure domain data
  - API/Service → networking/IO/3rd-party orchestration and DTO→Domain mapping
  - Feature/UI → SwiftUI views & interactions consuming service protocols and domain models only
- **Dependency direction**: Core ← Model ← API ← Feature (no reverse dependencies)
- **Replaceability**: API exposes service protocols + default impl; UI injects via `@Environment`, never references networking libs directly
- **SwiftUI MV**:
  - Use `@State`/`@Observable`/`@Environment`/`@Binding` for state
  - Side effects in `.task`/`.onChange` (lifecycle-aware cancellation)
  - Avoid default ViewModel layer (no MVVM by default)

---

## Requirements

- macOS 14.0+
- Xcode 15.4+ (`SWIFT_VERSION = 5.10`)
- Tuist

Install Tuist if needed:

```bash
brew tap tuist/tuist && brew install tuist
```

---

## Getting Started

1) Generate the Xcode workspace:

```bash
make generate
# or
Scripts/generate.sh
```

2) Open and run:

```bash
open Vibeviewer.xcworkspace
# In Xcode: scheme = Vibeviewer, destination = My Mac (macOS), then Run
```

3) Build/package via CLI (optional):

```bash
make build     # Release build (macOS)
make dmg       # Create DMG package
make release   # Clean → Generate → Build → Package
```

---

## Run & Debug

- The menu bar shows the icon and key metrics; click to open the popover.
- Sign-in and Settings windows are provided via environment-injected window managers (see `.environment(...)` in `VibeviewerApp.swift`).
- Auto-refresh starts on app launch and reacts to screen power/activity changes.

---

## Testing

Each package ships its own tests. Run from Xcode or via CLI per package:

```bash
swift test --package-path Packages/VibeviewerCore
swift test --package-path Packages/VibeviewerModel
swift test --package-path Packages/VibeviewerAPI
swift test --package-path Packages/VibeviewerAppEnvironment
swift test --package-path Packages/VibeviewerStorage
swift test --package-path Packages/VibeviewerLoginUI
swift test --package-path Packages/VibeviewerMenuUI
swift test --package-path Packages/VibeviewerSettingsUI
swift test --package-path Packages/VibeviewerShareUI
```

> Tip: after adding/removing packages, run `make generate` first.

---

## Contributing

Issues and PRs are welcome. To keep the codebase consistent and maintainable:

1) Branch & commits
- Use branches like `feat/...` or `fix/...`.
- Prefer Conventional Commits (e.g., `feat: add dashboard refresh service`).

2) Architecture agreements
- Read `./.cursor/rules/architecture.mdc` and this README before changes.
- Place new code in the proper layer (UI/Service/Model/Core). One primary type per file.
- API layer exposes service protocols + default impl only; DTOs stay internal; UI uses domain models only.

3) Self-check
- `make generate` works and the workspace opens
- `make build` succeeds (or Release build in Xcode)
- `swift test` passes for related packages
- No reverse dependencies; UI never imports networking implementations

4) PR
- Describe motivation, touched modules, and impacts
- Include screenshots/clips for UI changes
- Prefer small, focused PRs

---

## FAQ

- Q: Missing targets or workspace won’t open?
  - A: Run `make generate` (or `Scripts/generate.sh`).

- Q: Tuist command not found?
  - A: Install via Homebrew as above.

- Q: Swift version mismatch during build?
  - A: Use Xcode 15.4+ (Swift 5.10). If issues persist, run `Scripts/clear.sh` then `make generate`.

---

## License

This project is open-sourced under the MIT License. See `LICENSE` for details.

---

## Acknowledgements

Thanks to the community for contributions to modular Swift packages, SwiftUI, and developer tooling — and thanks for helping improve Vibeviewer!

UI inspiration from X user @hi_caicai — see [Minto: Vibe Coding Tracker](https://apps.apple.com/ca/app/minto-vibe-coding-tracker/id6749605275?mt=12).


