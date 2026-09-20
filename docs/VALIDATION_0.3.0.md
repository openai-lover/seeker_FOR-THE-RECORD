# Verification for version 0.3.0

Verified September 20, 2026. Tests use synthetic data unless explicitly noted below.

- Full Flutter suite: **84 passed**. Includes 10 direct RPC/parser tests, eight direct MWA lifecycle tests, 16 UX regression tests and 13 localization tests, alongside existing domain, transaction guard and widget/golden coverage.
- Flutter analyzer: **no issues**.
- Optional server: **40 tests passed**, TypeScript build clean. No payment was made.
- All eight languages fit the Home, Settings and both journals at 360 x 800 logical pixels with 200% text. Spanish/French home overflow was fixed.
- Golden images were visually reviewed after deliberate palette, layout and free-mode changes.
- Mainnet public RPC `getVersion` returned a real response. This establishes endpoint reachability, not a successful wallet-to-journal flow.

## What these checks do not prove

Physical Seeker wallet success, supported real swap history, TalkBack behavior, battery endurance, native-speaker translation quality and production payment recovery remain unverified. Optional shared rooms and purchases are hidden in the free default edition. The delivered review APK uses a development signing key.

See [UX review](UX_REVIEW.md), [device rehearsal](submission/DEVICE_REHEARSAL.md), and [the free approach](submission/FREE_PREVIEW_APPROACH.md). Historical validation logs and reference prompts are retained locally but excluded from the public source package; they are not evidence for this release.

Android verification also passed on the isolated x64 emulator with the final free path: project creation, focus, saved outcome, SQLite reopen, all language choices, and native MWA no-wallet error handling without losing the saved record. Latest captured screens include the read-only connection page.
