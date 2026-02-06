# CCUsage

Minimal macOS menu bar app for real-time Claude Code usage monitoring.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## What it does

- Shows your **5-hour** and **weekly** Claude Code usage percentage in the menu bar
- Color-coded status: green (normal) → orange (70%+) → red (90%+)
- Displays time until usage resets
- Auto-refreshes every 30 seconds
- Zero configuration — reads your existing Claude Code credentials

## Requirements

- macOS 14 (Sonoma) or later
- Active Claude Code subscription (Pro / Max5 / Max20)
- Claude Code CLI installed and logged in

## Install

### One-liner

```bash
curl -sL https://raw.githubusercontent.com/jaehyunjang/ccusage/main/install.sh | bash
```

### Download

1. Download `CCUsage.zip` from [Releases](https://github.com/jaehyunjang/ccusage/releases/latest)
2. Unzip and move `CCUsage.app` to `/Applications`
3. **Right-click → Open** (required once for unsigned apps)

### Build from source

```bash
git clone https://github.com/jaehyunjang/ccusage.git
cd ccusage
make install
```

## How it works

CCUsage reads your OAuth credentials from macOS Keychain (`Claude Code-credentials`) and calls the Anthropic usage API (`api.anthropic.com/api/oauth/usage`) to get your real-time utilization percentages.

No data is stored or transmitted anywhere except to the official Anthropic API.

## Uninstall

```bash
make uninstall
```

Or delete `CCUsage.app` from `/Applications`.

## License

MIT
