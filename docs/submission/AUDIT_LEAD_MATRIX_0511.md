# Two historical audit leads: current 0.5.11 evidence

**Observed October 5, 2026.** This agent source/artifact review maps two repeated Coach leads to exact source and existing evidence. No production code was changed. No APK was rebuilt, existing tests/gates were not rerun, and no portal audit was consumed. It is not independent security clearance.

Historical partial audit source: `414acebb41d0b23169ff15e16456ec175b1ac67c`. Current app/tag source: `0c5dfd70243940d6598804e9ff3d111ae920051d`. Previous 0.5.10 app source: `9de8139614cfd0c6374036e0b0ceb68abeee7602`.

## Two-lead evidence matrix

| Historical lead | Exact current evidence | Disposition and limits |
|---|---|---|
| Possible SQL construction, `functions/src/index.ts:87` | [Exact historical line](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/414acebb41d0b23169ff15e16456ec175b1ac67c/functions/src/index.ts#L87) calls `ActivityService.query`; [current dispatcher:88](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/src/index.ts#L88). [activity.ts:133](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/src/activity.ts#L133) accepts only an optional Base58 cursor decoding to 64 bytes in a strict object. [140–147](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/src/activity.ts#L140) authenticate, validate, rate-limit, use a memory cache and call the provider with the authenticated wallet. [106–110](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/src/activity.ts#L106) serializes structured JSON-RPC; [124–131](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/src/activity.ts#L124) uses fixed read-only methods. [index.ts:38–46](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/src/index.ts#L38) verifies identity and uses Firestore document APIs. | No SQL statement or SQL sink found in this reviewed call path. Scoped false-positive triage, not assurance for every route or deployed stack. |
| Exported component, `AndroidManifest.xml:9` | [Exact historical component](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/414acebb41d0b23169ff15e16456ec175b1ac67c/android/app/src/main/AndroidManifest.xml#L9) and [current lines 9–29](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/android/app/src/main/AndroidManifest.xml#L9) identify intended MAIN/LAUNCHER `WorkroomActivity`; exported=true at line 11. [Receiver:31](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/android/app/src/main/AndroidManifest.xml#L31) is private. Native export [31–42](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/android/app/src/main/kotlin/app/workroom/seeker_workroom/WorkroomActivity.kt#L31) and [80–96](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/android/app/src/main/kotlin/app/workroom/seeker_workroom/WorkroomActivity.kt#L80) requires an in-process pending channel request and document-picker completion. App-written incoming-intent extra handling was not found in this native source. | Keep the intended launcher externally launchable. SDK callback components and inherited Flutter intent behavior have not been comprehensively audited. Current complete merged inventory is exposed below. |

## Existing input proof, unchanged source

[Current regression:33](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/test/activity-input.test.ts#L33) includes SQL quote/union/encoding, RPC escape text, traversal, wrong cursor types/lengths, wallet/method/endpoint overrides and prototype input. [Fixed-method assertions:94](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/functions/test/activity-input.test.ts#L94) intercept the actual provider's fetch.

The October 4 execution observed **21 malformed bodies rejected before rate-limit/provider work, 25 targeted checks and 69 complete backend checks**. Authentication/network are local fakes; deployed Firebase/HTTP/live RPC was not tested. No rerun occurred today.

[Targeted TAP](../evidence/security-0510/activity-input-tap.txt) · [full TAP](../evidence/security-0510/backend-tests-tap.txt) · [dated hashes/scope](../evidence/security-0510/receipt.json).

The [new receipt](../evidence/security-0511/receipt.json) verifies five byte-identical Git blobs between the two app sources: `index.ts`, `activity.ts`, source `AndroidManifest.xml`, `WorkroomActivity.kt` and `verify-release.ps1`. The test exists at current app source; original execution retains its date.

## Actual current APK manifests

Both hashes were verified **before** AAPT extraction.

| ABI | Bytes | Version code | APK SHA256 |
|---|---:|---:|---|
| ARM64 | 37,717,677 | 2018 | `29ba3bc74bad0221246aef3a5306681f81a5282f4da8518045c87cfa3339786c` |
| x64 | 39,675,145 | 4018 | `978a0c353939124c1bb8a261ff15adc90b910ea4ad85fe56417efaec9f486374` |

[ARM64 raw dump](../evidence/security-0511/packaged-arm64-v8a-manifest.txt) · [x64 raw dump](../evidence/security-0511/packaged-x86_64-manifest.txt) · [existing current package/asset passes](../evidence/ui-0511/package-checks.json) · [gate source](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/0c5dfd70243940d6598804e9ff3d111ae920051d/tools/verify-release.ps1#L7).

Both inventories have the same **14 named merged components**. Neither contains the three removed AndroidX test activities, Flutter integration-test components, or instrumentation. Remaining exported components and the app's private receiver:

| Exact component name | Explicitly exported | Component permission |
|---|---|---|
| app.workroom.seeker_workroom.WorkroomActivity | true | None declared |
| app.workroom.seeker_workroom.FocusAlarmReceiver | false | None declared |
| com.google.firebase.auth.internal.GenericIdpActivity | true | None declared |
| com.google.firebase.auth.internal.RecaptchaActivity | true | None declared |
| com.google.android.gms.auth.api.signin.RevocationBoundService | true | com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION |
| androidx.profileinstaller.ProfileInstallReceiver | true | android.permission.DUMP |

All remaining non-exported SDK activities/services/providers are listed in the full dumps and JSON inventory. Firebase auth activities remain exported without a component permission; their callback behavior is not comprehensively reviewed. Permission-gated SDK entries also remain visible. The package inspection is not full security clearance.

The three AndroidX test-activity exclusions happened in **0.5.10**, not today. [Original dependency trace and triage](AUDIT_TRIAGE_0510.md) · [original gate/negative-control output](../evidence/security-0510/packaged-gate-output.txt).

## Still open

Historical portal audit remains partial/scoreless with four unconfirmed leads. Two web3.js v1 migration leads and three optional undeployed-backend advisories (one high, two moderate) remain. [Backend status](../BACKEND_SECURITY_STATUS_2026-10-01.md). No independent penetration test, deployed-backend verification, extra audit or comprehensive SDK component clearance is claimed. No private phone data was used.
