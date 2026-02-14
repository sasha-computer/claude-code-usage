<p align="center">
  <img src="assets/hero.png" alt="Claude Code Usage" width="200" />
</p>

<h1 align="center">Claude Code Usage</h1>

<p align="center">
  See your Claude Code rate limits in the macOS menu bar. Always.
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

- Shows **5-hour** and **weekly** usage percentages in the menu bar
- Color-coded: green (normal), orange (70%+), red (90%+)
- Click the menu bar item for detailed usage breakdown and reset times
- Refreshes every 30 seconds, reads credentials from the macOS Keychain
- Zero config. If you're logged into Claude Code, it just works.

## Installation

### One-liner (recommended)

```bash
curl -sL https://raw.githubusercontent.com/sasha-computer/claude-code-usage/main/install.sh | bash
```

Downloads the latest release and installs to `/Applications`.

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

Originally based on [NewTurn2017/ccusage](https://github.com/NewTurn2017/ccusage). Includes English language support, a token refresh bug fix that prevented Claude Code from getting logged out, and a productionized build/release pipeline.

## License

MIT
