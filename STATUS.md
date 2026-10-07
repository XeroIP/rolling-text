---
state: active        # active | paused | blocked | done
priority: med        # high | med | low
updated: 2026-10-06T18:24:46-06:00
source: manual       # manual (/wrapup or pre-push) | auto (sweeper)
---
# rolling-text status

## Goal
Keep the app releasable and choose the next piece of work: publish the launch posts, or start the Raspberry Pi edition (issue #49). The goal is inferred from repo state; the owner has not stated it in a STATUS.md.

## Done recently
- Added the shift-change handoff: STATUS.md template and the /wrapup skill (9e06c08).
- Corrected the icon release version to 0.6.1 instead of 0.7.0 (52f504c, PR #58).
- Redesigned the app icon bars and regenerated platform icons (b71b4a1, ce78579).
- Release audit run this session, read-only: `pubspec.yaml` is 0.6.1+10, the newest released CHANGELOG heading is `## [0.6.1]`, and tag `v0.6.1` exists. All three agree.
- No code changed this session.

## In progress / broken
- Nothing is known to be broken. `main` matches `origin/main`.
- `docs/launch-posts.md` is untracked: 149 lines, copy-paste drafts (a Show HN post is first) with bracketed notes still to edit. Only the first 15 lines were read; completeness is unchecked.
- `git tag --sort=-v:refname` lists `v3.0.0`, `v2.1-2` and `v2.0` above `v0.6.1`. Their origin is unknown. They did not affect the 0.6.1 audit, but they would affect any "latest tag" check.
- `CHANGELOG.md` has an `[Unreleased]` section whose contents were not read.

## Next step
Read `docs/launch-posts.md` in full, resolve its bracketed notes, then commit it on a `docs/` branch (not `main`) and open a PR.

## Blockers / waiting on
- Owner decision: launch posts first, or issue #49 (Raspberry Pi edition, open, needs design discussion before any implementation).
- Owner to say whether the stray `v3.0.0`, `v2.1-2` and `v2.0` tags are intentional.
