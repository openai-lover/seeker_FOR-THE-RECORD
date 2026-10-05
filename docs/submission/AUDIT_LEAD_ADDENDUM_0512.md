# 0.5.12 packaged evidence and historical audit-lead addendum

**Observed October 5, 2026.** App 0.5.12+19 is pinned to source **ee650639670c7ab35081a92e3435a185b73a6642**. This is an agent source/container inspection with selected release gates. It is not an independent audit, deployed-backend test or comprehensive security clearance.

The [dated 0.5.11 matrix](AUDIT_LEAD_MATRIX_0511.md) and its raw manifests remain unchanged. The older partial portal audit used source 414acebb41d0b23169ff15e16456ec175b1ac67c.

## What the final packages contain

Both exact APK hashes below were verified **before** Android build-tools 36.0.0 AAPT extraction. Actual manifests have the same 14 named components, component export/permission settings and five uses-permissions as the dated 0.5.11 packages. Package versions changed; the old manifests were not relabelled.

| ABI | Bytes | Version code | APK SHA256 |
|---|---:|---:|---|
| arm64-v8a | 37,713,101 | 2019 | ac4b86ef0f32616f88b0dc4e66b212d013c33a1f01f8e3192b935e970c9a23e3 |
| x86_64 | 39,670,569 | 4019 | 2a695ff0c043407a14f9aaa9b6becdfb366d01cc0fac57f7a9560e68b659baf7 |

Each final APK has **17 nonempty Flutter asset entries**, including all **13 required** manifest/font/room/motion/license resources. Each contains exactly one supported ABI and all three nonempty native libraries: libapp.so, libflutter.so and libreflection_native.so. The gate verifies selected container requirements; it does not prove every resource is semantically correct.

[ARM64 raw manifest](../evidence/security-0512/packaged-arm64-v8a-manifest.txt) - [x64 raw manifest](../evidence/security-0512/packaged-x86_64-manifest.txt) - [full inventory, asset/library hashes and provenance](../evidence/security-0512/receipt.json) - [actual gate output](../evidence/security-0512/package-gate-output.txt).

The final build's captured gate output records manifest and asset/native passes for both ABIs. Root separately completed 274 Flutter tests, clean analysis, 97 backend tests and backend compilation. No test suite, build, device operation, deployment, commit or push was performed by this artifact-review task.

## A caught packaging failure, with retained negative controls

The first 0.5.12 build had a valid manifest and current AOT code, but **zero Flutter asset entries**. Root caught it before installation or public release. A manifest-only check was therefore insufficient.

[Current gate:28](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/tools/verify-release.ps1#L28) now requires packaged manifest/font/room/motion/license assets plus exactly one supported ABI and all three native libraries. Root rebuilt after backing up affected generated intermediates inside the repository. No personal device data was involved.

The retained incomplete binaries stay private. This inspection verified zero Flutter entries and reran only the read-only package gate against those two controls. Both fail with **Release APK is missing a required Flutter asset: AssetManifest.bin**. Their AOT hashes equal their respective final package AOT hashes; missing resources, rather than a different reader implementation, explain the failure.

| Private control ABI | Bytes | Flutter entries | Current gate exit | Control SHA256 |
|---|---:|---:|---:|---|
| arm64-v8a | 27,627,600 | 0 | 1 | 87b5c346db9887ad138beeb504e608ac60f44451bdd2a62b05c5389e73281023 |
| x86_64 | 29,585,068 | 0 | 1 | cec5cad41267cc44ea3662f0d3a7cd8362fd6037f42febddf6f39b485780c5ac |

This adds no claim about a current-gate positive result for the older 0.5.11 x64 APK. Older gate evidence retains its original date and rules.

## Two historical leads mapped to the current source

| Historical lead | Current exact path and proof | Disposition and limit |
|---|---|---|
| Possible SQL construction at old index.ts:87 | [Current dispatcher:88](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/src/index.ts#L88) calls ActivityService.query. [Strict cursor:149](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/src/activity.ts#L149) allows only an optional Base58 cursor decoding to 64 bytes. [Query:156](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/src/activity.ts#L156) authenticates before validating/rate-limiting and using its memory cache. [Structured RPC:122](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/src/activity.ts#L122) serializes fixed read-only methods; [methods:141](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/src/activity.ts#L141) use the authenticated wallet and validated cursor. [Identity/Firestore:38](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/src/index.ts#L38) uses verified identity and Firestore document APIs. | No SQL statement or SQL sink found in the reviewed activity path. This is scoped triage, not proof for every route, deployment or input. |
| Exported AndroidManifest.xml:9 | [Source launcher:9](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/android/app/src/main/AndroidManifest.xml#L9) remains exported with MAIN/LAUNCHER at lines 27-28; [alarm receiver:31](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/android/app/src/main/AndroidManifest.xml#L31) is private. The exact final AAPT inventories show these flags and all SDK components. No AndroidX test activities, Flutter integration-test components or instrumentation are present. | The intended launcher must remain externally launchable. Remaining SDK callbacks and inherited Flutter intent behavior are not comprehensively audited. |

Current index.ts, source AndroidManifest.xml and WorkroomActivity.kt are byte-identical to app source 0.5.11. Current activity.ts changed for guarded reading of known version-1 transaction envelopes and the numeric RPC ceiling of 1. The request cursor validation, authenticated wallet source, fixed read-only method structure and displayed total meta.fee remain. These changes do not add an SQL sink or relax authority/balance/action classification.

The original [21 malformed-body / 25 targeted checks](../evidence/security-0510/activity-input-tap.txt) and [69 backend checks](../evidence/security-0510/backend-tests-tap.txt) retain their October 4 scope. Current regression source [activity-input.test.ts:33](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/test/activity-input.test.ts#L33) retains crafted SQL/escape/traversal/override inputs; [fixed-method assertions:94](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/functions/test/activity-input.test.ts#L94) now expect the numeric version ceiling 1. Current root backend regression count is 97. Authentication, rate limiting and provider network are local fakes; deployed Firebase/HTTP behavior was not tested.

## Remaining exported SDK components are visible

Both final APKs have these same explicit flags:

| Exact component name | Exported | Component permission |
|---|---|---|
| app.workroom.seeker_workroom.WorkroomActivity | true | None declared |
| app.workroom.seeker_workroom.FocusAlarmReceiver | false | None declared |
| com.google.firebase.auth.internal.GenericIdpActivity | true | None declared |
| com.google.firebase.auth.internal.RecaptchaActivity | true | None declared |
| com.google.android.gms.auth.api.signin.RevocationBoundService | true | com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION |
| androidx.profileinstaller.ProfileInstallReceiver | true | android.permission.DUMP |

All other named non-exported SDK components are included in the raw dumps and receipt. The three unnecessary AndroidX test activities were removed in 0.5.10, not in this inspection. [Dated original trace and proof](AUDIT_TRIAGE_0510.md).

## Still open

The historical portal audit remains partial/scoreless with four unconfirmed leads. Two web3.js v1 migration leads remain; the existing SDK/chain.ts path was not upgraded. The optional backend is undeployed and has three production advisories, one high and two moderate. [Backend status](../BACKEND_SECURITY_STATUS_2026-10-01.md). No extra portal audit was run, no fee/signature/transaction was performed, and no full SDK-component clearance or independent penetration test is claimed.
