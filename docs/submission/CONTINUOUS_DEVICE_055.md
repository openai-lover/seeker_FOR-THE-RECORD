# Current production Seeker demonstration — 0.5.5

Observed 4 October 2026 on a physical Seeker running the existing production 0.5.5+12 install (versionCode 2012). App source and release tag remain `07a0cb388e5395f24b3a75c9923aa2f4df5dc7cd`; this evidence update does not modify the app or AI model.

[Continuous video](https://drive.google.com/file/d/1JeE2C5iJb-CIFL8v9uv40Cn15s_BIfwl/view) · [Current deck](https://docs.google.com/presentation/d/1tO0GQsr-iQCSKIODwrkbODu2ENiVbRopWM78R8wwcNA/edit) · [Release files](https://github.com/openai-lover/seeker_FOR-THE-RECORD/releases/tag/v0.5.5) · [Sanitized receipt](../evidence/continuous-device-055.json)

## What actually happened

1. The app reconnected using an existing Mobile Wallet Adapter authorization, then read finalized public RPC activity. No fresh account-consent prompt, signing request, trade or token purchase occurred.
2. A previously unrecorded successful **Other** activity received a new synthetic public demo note: “I want to check one source before my next choice.” The original reason and source were retained. This is not a supported Jupiter swap.
3. An immediate manual reflection requested a local AI question. The production app selected question 4; its exported provenance recorded a **2,249 ms cold** invocation. The model was already installed and networking was available. This single observation is not an offline benchmark, population latency estimate or general accuracy result.
4. A synthetic reflection and lesson were saved. Earlier personal records were not edited. The operator briefly opened an earlier record by mistake and returned; that portion is covered in the public video without removing time.
5. Android's native export picker was cancelled once, then retried. The operator waited for a completed **1,876-byte valid JSON** before stopping the app.
6. After force-stop and reopen, the saved reason, reflection and lesson remained. A second completed export had an **exactly identical complete `tradeJournals` payload**. JSON parsing, exact text and provenance checks were performed locally outside the phone screen. Raw exports remain private.

## Video scope and limitations

The published 6:28 video is the first 388 seconds of one continuous screen recording, at original speed with no internal cuts. Solid covers hide account identifiers, private earlier notes and file listings. They also obscure parts of the wallet and restart navigation, so this is **redacted continuous evidence**, not an unobscured account-to-export proof. Pauses and the wrong-record detour remain. English synthetic narration explains the actions and limits. The second export is outside the published segment.

The raw recording produced a decode warning around 24 seconds on the room screen; the re-encoded video was visually reviewed. This warning is not described as a removed tail-only fault. The local file checks provide separate evidence for export completion and preservation.

No supported live swap, delayed due-date wait, independent user study, retention metric or current offline benchmark was verified. Earlier [40-case diagnostic results](../AI_EVALUATION_055.md) are isolated debug measurements and are kept separate from this production observation. The existing [export regression and limited security triage](EXPORT_RELIABILITY_055.md) remains applicable; no extra portal audit was consumed.

## Reproduction without exposing records

Use an existing read-only wallet authorization and successful activity, clearly label any authored demonstration writing, select no date for an immediate revisit, save a lesson, cancel/retry native export, wait for completion, parse the exported JSON locally, reopen the app and compare a second export. Never publish wallet identifiers or raw personal exports. Do not create a transaction merely to demonstrate this path.
