# Release packaging and limited audit triage — 0.5.10

## A real release-packaging issue

Inspection of the actual 0.5.9 ARM64 APK, rather than just the application source manifest, found three exported AndroidX test activities: `InstrumentationActivityInvoker$BootstrapActivity`, `$EmptyActivity` and `$EmptyFloatingActivity`. These are unnecessary production entry points. No exploit or personal-data disclosure was observed.

Gradle's `releaseRuntimeClasspath` traced the source to `mobile-wallet-adapter-clientlib-ktx:2.0.3 -> androidx.test.ext:junit-ktx:1.1.5 -> junit:1.1.5 -> androidx.test:core:1.5.0`. The adapter's published metadata also includes Mockito runtime dependencies. Its 49 production classes had no constant-pool references to AndroidX test, Mockito, JUnit or Byte Buddy in the inspected AAR; this static check is not a complete behavioral proof.

The application now excludes those three test dependencies specifically from the adapter edge. It retains the adapter itself, the production launcher, Firebase's existing optional authentication components, and the private alarm receiver. No manifest flag was disabled merely to conceal the historical launcher finding.

### Verified release result

Both ARM64 and x64 0.5.10+17 release builds passed the packaged-manifest gate. The old APK failed the same gate. All 145 Flutter regressions passed and analysis was clean after this change. On the physical Seeker, a normal in-place update installed versionCode 2017. The app started, opened the Seed Vault/MWA connection sheet, and returned to the app with **Wallet connected** after the account-connection action. No message or transaction was signed. No personal export, journal text or wallet address was collected for this check. This does not establish a new complete wallet-to-export video.

ARM64 APK: 37,713,149 bytes; SHA256 `3b2e8a11ad1a322dfcc510d46d90097c246fd995adaa1c7ff9d2984d94f19564`. The before/after package observations are in [release-manifest-0510.json](../evidence/release-manifest-0510.json). The model, parser and export behavior measured in 0.5.9 are unchanged; those earlier observations keep their original version labels.

`tools/verify-release.ps1` inspects each packaged APK before the build script copies release artifacts. It rejects test components, instrumentation, a debuggable build, the wrong application ID, a missing launcher, or a missing Internet permission. The old 0.5.9 artifact was the negative control and failed on its test activities. The patch changes packaging; the journal schema, room, UI, model and parser are unchanged.

## The four historical portal leads

After the 79-point review, [focused input and package evidence](SECURITY_PROOF_0510.md) added 21 malformed-body cases, exact RPC serialization assertions, and actual packaged-manifest/gate output. The targeted run passed 25 checks and the full local backend suite passed 69. This is a test/evidence update against unchanged production code, not a new portal audit or a new app release.

The portal audit examined commit `414acebb41d0b23169ff15e16456ec175b1ac67c`, was partial and scoreless, and called every listed finding unconfirmed. Its report says 230 files were read, but some checks did not run, including known dependency vulnerabilities. That is not proof of comprehensive coverage. No additional portal audit was consumed.

| Historical lead | Source-level finding and current disposition |
|---|---|
| High: SQL text construction, `functions/src/index.ts:87` | The exact old line invokes `activityService.query(...)`. That method authenticates the caller, parses a strict cursor-only schema, rate limits, reads an in-memory cache, and calls standard read-only Solana JSON-RPC. It does not build a SQL statement. The adjacent user storage uses Firestore document APIs. No SQL sink was found in this reviewed call path; this is a manual triage conclusion, not a new independent audit. |
| Medium: exported component, `AndroidManifest.xml:9` | The cited component is the intended MAIN/LAUNCHER `WorkroomActivity`. Reviewed code does not route incoming extras into exports or wallet signing. The native export channel needs an in-process pending request and a completed document-picker result. Inspection beyond the source manifest exposed the separate test activities described above, which this release removes. Other library components have not received a comprehensive behavioral audit. |
| Low: web3.js v1 import, `functions/src/chain.ts:1` | The optional backend really uses v1 and SPL APIs. Migration to Kit remains open; deleting the import would break existing optional code rather than resolve the maintenance concern. |
| Low: web3.js v1 import, `functions/src/index.ts:7` | Same actual dependency and migration limitation. The backend remains undeployed and payment activation defaults to false. |

### Source references pinned to the app tag

- [Exact historical flagged line](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/414acebb41d0b23169ff15e16456ec175b1ac67c/functions/src/index.ts#L87).
- [Activity request schema and call path](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/functions/src/activity.ts#L133), [standard RPC provider](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/functions/src/activity.ts#L102).
- [Verified token and collection-scoped user lookup](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/functions/src/index.ts#L38), [canonical wallet/UID binding](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/functions/src/identity.ts#L27).
- [Production launcher declaration](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/android/app/src/main/AndroidManifest.xml#L9), [native export completion](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/android/app/src/main/kotlin/app/workroom/seeker_workroom/WorkroomActivity.kt#L31), [release dependency exclusions](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/android/app/build.gradle.kts).
- [Existing identity regressions](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/functions/test/identity.test.ts). The 44-test backend run belongs to October 1; it is not relabelled as a new backend audit.

Official references: [Android exported activity semantics](https://developer.android.com/guide/topics/manifest/activity-element#exported), [Firestore data structures](https://firebase.google.com/docs/firestore/manage-data/structure-data), [Solana web3.js maintenance status](https://solana-foundation.github.io/solana-web3.js/).

## Dependency advisories remain open

The separate October 1 production dependency audit still records one high and two moderate advisories: bigint-buffer, uuid and stream-json. October 4 official registry inspection found that web3.js 1.99.0 still depends on jayson 4.3.0, whose metadata retains uuid 8 and stream-json 1; SPL Token 0.4.15 still reaches bigint-buffer through buffer-layout-utils 0.3.0. These available compatible updates do not remove those dependency paths. No package major version was forced and no warning was ignored.

The default mobile app uses local storage and direct read-only RPC, without a configured Firebase backend. This limits that optional backend's present deployment exposure; it does not clear its advisories. There is no comprehensive security clearance, new audit score or production penetration-test claim.
