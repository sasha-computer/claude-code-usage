# Claude Code Usage

macOS menu bar app showing Claude Code rate limits. Swift + SwiftUI, distributed as a signed DMG via GitHub Releases and Homebrew.

## Project structure

- `ClaudeCodeUsage/Sources/App/` -- app entry point, AppDelegate, Info.plist
- `ClaudeCodeUsage/Sources/Services/` -- UsageMonitor, ClaudeDataReader, UpdateChecker
- `ClaudeCodeUsage/Sources/Views/` -- MenuBarView, SettingsView, UpdateAlertWindow
- `ClaudeCodeUsage/Sources/Models/` -- UsageData models
- `ClaudeCodeUsage/Sources/Utils/` -- L10n, Formatters
- `Tests/` -- unit tests
- `frontend/` -- web frontend (deployed to Railway)

## Build and run

```bash
make build      # build the .app
make install    # build + copy to /Applications + launch
make clean      # remove build artifacts
make dmg        # build + create DMG
```

## Key conventions

- **Atomic commits.** One logical change per commit, independently meaningful.
- **Rebase workflow.** Linear history, no merge commits.
- **No em dashes** in any prose or copy.
- **Release process** is documented in `.claude/skills/new-release.md` (symlinked from `.pi/skills/new-release/SKILL.md`). Follow it exactly.

## Architecture notes

- The app reads OAuth credentials from the macOS Keychain (where Claude Code stores them)
- Calls the Anthropic usage API directly
- UpdateChecker does in-app self-updates: downloads DMG, mounts, replaces app, relaunches
- Menu bar label is reactive via Combine publishers
