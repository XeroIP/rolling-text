---
state: active        # active | paused | blocked | done
priority: med        # high | med | low
updated: 2026-10-07T00:06:39-06:00
source: manual       # manual (/wrapup or pre-push) | auto (sweeper)
---
# rolling-text status

## Goal
Work through the six issues filed from the October code review (#60-#65), starting with the one that affects the launch posts. Issue #49 (Raspberry Pi edition) still needs design discussion.

## Done recently
- Reviewed an external code review (ten findings, three nits) and two later triage passes against `main`; no code was changed. `flutter analyze` is clean and all 94 tests pass on Flutter 3.44.8.
- Filed #60 (template metadata), #61 (CI on pull requests and before web deploy), #62 (resume focus steal, thrown saves, write on cancel, version lookup), #63 (dark-theme contrast), #64 (hardcoded font-size limits, duplicate font row), #65 (blank page when browser storage is blocked).
- Reproduced #62 in Chrome on a debug build: after a resume with a sheet open, typed keys go to the editor behind it and Escape stops closing the sheet. The resume was simulated with `blur`/`focus` events on `window`.
- Reproduced #65 in headless Chrome with a throwaway profile that blocks site data: reading `localStorage` throws `SecurityError` and the page stays blank.
- Read the `[Unreleased]` section of `CHANGELOG.md`: it is empty.

## In progress / broken
- Nothing is in progress. `main` matches `origin/main`; no branches are open.
- Known defects on `main` are the six issues above. #62 is destructive (stray keys at the limit delete text) and #65 stops the web app from starting.
- `docs/launch-posts.md` is not posted yet. Its "no analytics" claim and 78-character HN title are still unverified, and link previews would show the template metadata until #60 lands.
- `review/` is untracked and holds the triage handoff. The repo is public, so committing it publishes the findings. A local-only branch `review/codex-2026-08-02` holds the original review.
- Not confirmed by hand: #62 with a real window switch, #62 on Android, and whether a key typed immediately after opening a sheet can land in the editor in a visible window (both noted in comments on #62).

## Next step
Fix #60 on a new branch: in `web/index.html` set the title (line 32) and `apple-mobile-web-app-title` (line 26) to `Rolling Text` and the meta description (line 21) to the one in `web/manifest.json`; in `android/app/src/main/AndroidManifest.xml` line 5 set `android:label="Rolling Text"`. Then #61, #62 with #65, #63, #64.

## Blockers / waiting on
- Owner decision: remove the `orientation` lock in `web/manifest.json` as part of #60, or keep portrait.
- Owner decision: final colors for #63 (Dark Sepia primary text probably needs brightening too).
- Owner decision: whether the "Nothing is stored" wording changes, given four settings persist.
- Owner decision: commit or delete `review/` and the local review branch now that the issues exist.
- Owner decision: issue #49 design discussion.
