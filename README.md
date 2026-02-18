<p align="center">
  <img src="assets/hero.png" alt="Claude Code Usage" width="200" />
</p>

<h1 align="center">Claude Code Usage</h1>

<p align="center">
  See your Claude Code rate limits in the macOS menu bar. Always.
</p>

<p align="center">
  <img src="assets/screenshot-light.png" alt="Light mode" width="360" />
  &nbsp;&nbsp;
  <img src="assets/screenshot-dark.png" alt="Dark mode" width="360" />
</p>

<p align="center">
  <a href="#installation">Installation</a> ·
  <a href="#how-it-works">How it works</a> ·
  <a href="#usage">Usage</a> ·
  <a href="#building-from-source">Building from source</a>
</p>

## Why?

You're deep in a coding session and Claude Code suddenly tells you you've hit your rate limit. You had no idea you were close. Now you're stuck waiting for the reset with no visibility into when it actually happens.

**Claude Code Usage fixes this.** It sits in your menu bar and shows your 5-hour and weekly usage as percentages, color-coded so you can see at a glance how close you are to the limit. No surprises.

## How it works

```mermaid
graph TD
    subgraph macOS Menu Bar
        AD[AppDelegate] --> UM[UsageMonitor]
        AD --> UC[UpdateChecker]
        AD --> AS[AccountStore]
        AD --> SI[NSStatusItem]
        AS -->|active account token| UM
    end

    subgraph Credential Resolution
        UM -->|every 30s| API[ClaudeUsageAPI]
        API --> KC[macOS Keychain]
        API --> CF["~/.claude/.credentials.json"]
        AS -->|reads| MCC["~/.pi/agent/multi-claude-code.json"]
        API -->|token expired| TR[OAuth Token Refresh]
        TR -->|write back| KC
    end

    subgraph Anthropic API
        API -->|Bearer token| UA["GET /api/oauth/usage"]
        UA -->|5h + 7d utilization| UM
    end

    subgraph SwiftUI
        UM -->|"@Published + Combine"| SI
        SI -->|click| PO["NSPopover with MenuBarView"]
    end

    subgraph Auto-Update
        UC -->|daily| GH[GitHub Releases API]
        GH -->|new version| DMG["Download DMG → Mount → Replace → Relaunch"]
    end
```

- Shows **5-hour** and **weekly** usage percentages in the menu bar
- Color-coded: green (normal), orange (70%+), red (90%+)
- Click the menu bar item for detailed usage breakdown and reset times
- **Multi-account support** -- switch between multiple Claude Code accounts via [pi's MCC extension](https://github.com/mariozechner/pi-coding-agent). A badge in the menu bar shows the active account, and a segmented picker in the popover lets you toggle between them.
- **Automatic updates** -- checks for new versions and installs them in-place. No manual downloads or DMG wrangling.
- Refreshes every 30 seconds, reads credentials from the macOS Keychain
- Zero config. If you're logged into Claude Code, it just works.

## Installation

### Homebrew (recommended)

```bash
brew install --cask sasha-computer/tap/claude-code-usage
```

### One-liner

```bash
curl -sL https://raw.githubusercontent.com/sasha-computer/claude-code-usage/main/install.sh | bash
```

### Manual download

1. Grab `ClaudeCodeUsage.dmg` from the [latest release](https://github.com/sasha-computer/claude-code-usage/releases/latest)
2. Open the DMG and drag `ClaudeCodeUsage.app` to `/Applications`
3. First launch: right-click the app and select Open (one-time gate for unsigned apps)

## Usage

Launch the app. That's it.

The menu bar shows `5h 12%  7d 34%` (or whatever your current usage is). Click it to see:

- Exact percentages for both windows
- Reset countdown timers
- A refresh button if you want to check right now

### Multi-account (MCC)

If you use [pi's multi-claude-code extension](https://github.com/mariozechner/pi-coding-agent), you can monitor usage across multiple Claude Code accounts:

1. Open Settings (right-click the menu bar item)
2. Enable the **Multi-Claude-Code** toggle
3. The app reads accounts from `~/.pi/agent/multi-claude-code.json`

When enabled, the menu bar shows a badge with the active account's initial, and the popover footer has a segmented picker to switch between accounts.

### Requirements

- macOS 14 (Sonoma) or later
- Claude Code CLI installed and logged in
- An active Claude Code subscription (Pro, Max5, or Max20)

The app reads your OAuth credentials from the macOS Keychain (where Claude Code stores them) and calls the Anthropic usage API directly. It never sends data anywhere else.

## Building from source

```bash
git clone https://github.com/sasha-computer/claude-code-usage.git
cd claude-code-usage
make install
```

This builds a universal binary (arm64 + x86_64), copies it to `/Applications`, and launches it.

Other make targets: `make build` (build only), `make clean`, `make uninstall`.

## Credits

Originally based on [NewTurn2017/ccusage](https://github.com/NewTurn2017/ccusage). Includes English language support, an atomic token refresh that keeps Claude Code from getting logged out (even after sleep), and a productionized build/release pipeline.

## License

MIT
