---
state: active        # active | paused | blocked | done
priority: med        # high | med | low
updated: 2026-10-06T18:29:45-06:00
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
- `docs/launch-posts.md` is untracked: 149 lines, copy-paste drafts (a Show HN post is first). Read in full: Show HN post, Reddit template, and a 14-subreddit list; ready to post apart from the two issues below.
- Old tags `v3.0.0`, `v2.1-2` and `v2.0` (Feb 2026, commits 3789d99, 98ad443, b43e1f5) were deleted locally and on origin at the owner's request. Their three GitHub Releases remain as untagged drafts; delete them in the Releases UI or with `gh release delete` if unwanted. `v0.6.1` is now the newest tag.
- `docs/launch-posts.md` line 3 mentions bracketed notes that do not exist, and line 144 implies a Play Store listing that nothing in the repo confirms.
- `CHANGELOG.md` has an `[Unreleased]` section whose contents were not read.

## Next step
Fix the stale header line and the Play Store mention in `docs/launch-posts.md`, then commit it on a `docs/` branch (not `main`) and open a PR.

## Blockers / waiting on
- Owner decision: launch posts first, or issue #49 (Raspberry Pi edition, open, needs design discussion before any implementation).
- Owner to say whether the three draft releases left by the tag deletion should be removed.
