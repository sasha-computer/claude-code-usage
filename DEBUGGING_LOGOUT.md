# Debugging: "Not logged in" every morning

## Symptom

The app shows "Not logged in -- run claude login" every morning despite being logged in the previous day. The macOS Keychain has zero Claude entries.

## Root cause

The `saveCredentials` method used a **delete-then-add** pattern to update the Keychain. This is a non-atomic operation that loses credentials when the add step fails.

**Overnight timeline:**

1. Access token expires (they last a few hours to a few days)
2. App polls every 30s, sees expired token, calls Anthropic's refresh endpoint
3. Refresh tokens are **single-use** -- the old one is consumed server-side on success
4. `saveCredentials` **deletes** the Keychain entry first
5. Then tries to **add** the new entry -- fails (Keychain locked after sleep, macOS sandbox, etc.)
6. Old entry deleted, new entry never written -- credentials permanently lost
7. Morning: "Not logged in"

## Key facts from research

- **Refresh tokens are single-use.** If you call the refresh endpoint and don't save the new tokens, the old refresh token is consumed and gone. You must re-authenticate. ([source](https://gist.github.com/patyearone/7c753ef536a49839c400efaf640e17de))
- **Claude Code refreshes tokens in-memory but does not write them back to the Keychain.** The Keychain entry goes stale while Claude Code works fine in its session. ([source](https://gist.github.com/patyearone/7c753ef536a49839c400efaf640e17de))
- **Keychain ACL permissions can break after app updates**, preventing writes even when reads succeed. ([anthropics/claude-code#19456](https://github.com/anthropics/claude-code/issues/19456))

## Fix (applied 2026-02-15)

Three changes to `ClaudeDataReader.swift`:

1. **Removed delete-then-add** -- now uses `security add-generic-password -U` alone, which atomically updates an existing entry or creates a new one. The Keychain entry is never deleted.

2. **Added in-memory credential cache** -- after a successful token refresh, credentials are cached in `cachedCreds`. Even if the Keychain write fails, the app keeps working until restart.

3. **Handles missing Keychain entries** -- if no existing entry is found (previously lost), builds a fresh `claudeAiOauth` envelope instead of silently failing.

## Recovery

If you hit the "Not logged in" state, run:

```bash
claude login
```

This restores the Keychain entry. The fixed app will keep it alive from there.
