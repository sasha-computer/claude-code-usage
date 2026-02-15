---
name: new-release
description: Cut a new release of ClaudeCodeUsage. Handles version bump, atomic commits, tag, DMG, GitHub release with hand-written notes, Homebrew tap update, and local install.
---

# New Release

Run through this checklist every time you cut a release. No shortcuts.

## Pre-release

1. **All feature/fix commits are already pushed.** Never bundle code changes into the release commit.
2. **README is up to date.** If the release changes user-facing behavior, update the README in its own atomic commit first.

## Release steps

Run these in order:

### 1. Version bump + release commit

```bash
# Replace OLD with NEW in Info.plist
sed -i '' 's|<string>OLD</string>|<string>NEW</string>|g' ClaudeCodeUsage/Sources/App/Info.plist
git add ClaudeCodeUsage/Sources/App/Info.plist
git commit -m "release: vX.Y.Z"
```

### 2. Tag and push

```bash
git tag vX.Y.Z
git push && git push origin vX.Y.Z
```

### 3. Build DMG

```bash
make dmg
```

### 4. GitHub release with hand-written notes

Write proper release notes following the release-notes skill format. Never use `--generate-notes` alone.

```bash
gh release create vX.Y.Z ClaudeCodeUsage.dmg --title "vX.Y.Z" --notes '<notes>'
```

Use `git log vPREVIOUS..HEAD --oneline` to make sure nothing is missed.

### 5. Bump Homebrew tap

```bash
make bump-tap v=X.Y.Z
```

This clones the tap repo, updates the version and SHA, commits, and pushes.

### 6. Clean up + local install

```bash
rm -f ClaudeCodeUsage.dmg
make install
```

## Commit conventions

- Feature/fix commits go first, each atomic and independently meaningful
- README/docs updates get their own commit
- The version bump in Info.plist is always its own commit with message `release: vX.Y.Z`
- The release commit is always the last commit before the tag

## Version numbering

- Patch (X.Y.**Z**): bug fixes, small UI tweaks
- Minor (X.**Y**.0): new features, behavior changes
- Major (**X**.0.0): breaking changes (hasn't happened yet)

## What can go wrong

- **DMG SHA mismatch in tap**: `make bump-tap` downloads the DMG from the release to compute the SHA. If the release asset isn't uploaded yet, it'll get a bad hash. Always run `bump-tap` after the GitHub release is created.
- **Forgot to push before tagging**: the tag push will succeed but the release will point to a commit that isn't on main. Always `git push` before `git push origin vX.Y.Z`.
