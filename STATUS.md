---
state: active        # active | paused | blocked | done
priority: med        # high | med | low
updated: 2026-10-06T18:37:11-06:00
source: manual       # manual (/wrapup or pre-push) | auto (sweeper)
---
# rolling-text status

## Goal
Keep the app releasable and choose the next piece of work: post the launch drafts, or start the Raspberry Pi edition (issue #49). The goal is inferred from repo state; the owner has not stated it in a STATUS.md.

## Done recently
- Added the shift-change handoff: STATUS.md template and the /wrapup skill (9e06c08).
- Corrected the icon release version to 0.6.1 instead of 0.7.0 (52f504c, PR #58).
- Redesigned the app icon bars and regenerated platform icons (b71b4a1, ce78579).
- Release audit, read-only: `pubspec.yaml` 0.6.1+10, newest released CHANGELOG heading `## [0.6.1]` and tag `v0.6.1` agree.
- Added `docs/launch-posts.md` (PR #59) and deleted three old tags and their releases.

## In progress / broken
- Nothing is known to be broken. `main` matches `origin/main`.
- `docs/launch-posts.md` is merged to `main` (PR #59, squash `d0c5b5e`): Show HN post, Reddit template, 14-subreddit list. Whether and where to post is the owner's call; the "no analytics" claim in the posts and the 78-character HN title were not independently verified.
- Old tags `v3.0.0`, `v2.1-2` and `v2.0` and their three GitHub Releases (two had one attached file each) were deleted at the owner's request. `v0.6.1` is the newest tag and release.
- `CHANGELOG.md` has an `[Unreleased]` section whose contents were not read.

## Next step
Read the `[Unreleased]` section of `CHANGELOG.md`, then ask the owner whether to open design discussion on issue #49 (Raspberry Pi edition).

## Blockers / waiting on
- Owner decision: issue #49 (Raspberry Pi edition, open, needs design discussion before any implementation).
