# Focused input and packaged-manifest evidence

**October 4, 2026. App 0.5.10+17 remains unchanged.** This evidence addresses two specific requests in the 79-point Coach report. It adds regression tests and publishes existing package-check output. It does not represent a new portal audit or independent security clearance.

## 1. Historical SQL-construction lead

The historical flagged [index.ts:87](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/414acebb41d0b23169ff15e16456ec175b1ac67c/functions/src/index.ts#L87) calls `ActivityService.query`. In the [unchanged submitted activity source](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/functions/src/activity.ts), the body accepts only an optional Base58 cursor decoding to 64 bytes. The wallet comes from the authenticated identity, not the body. The provider serializes structured JSON-RPC parameters for fixed read-only methods. There is no SQL statement or SQL driver in this reviewed path; the adjacent persistence layer uses Firestore.

The new [executable regression](../../functions/test/activity-input.test.ts) runs the actual activity service and provider. Authentication and network transport are replaced with local fakes; this deliberately excludes real credentials, live RPC, Firebase and private wallets.

| Check | Observed result |
|---|---|
| 21 malformed bodies: SQL quotes/union/encoding, JSON escape text, traversal, URL, operator object, arrays, nulls, wrong decoded lengths, body wallet/method/endpoint/signed-transaction overrides, and a JSON prototype key | Every case returned `invalid-input` / 400. Only authentication was observed; no rate-limit or provider invocation occurred. Each following valid request still used the exact authenticated wallet and cursor. |
| Authentication failure with a crafted body | `sign-in-required` / 401 before validation or provider creation. |
| Five valid 64-byte cursor encodings, including leading-zero encodings | Exact cursor preserved; repeated request used the same cached page while still authenticating and rate limiting. |
| Actual `SolanaActivityProvider` with intercepted fetch | Exactly `getGenesisHash`, `getSignaturesForAddress`, and `getTransaction`; fixed endpoint, POST, structured parameters, finalized commitment, page limit 20. No caller-controlled method or endpoint. |
| Missing transaction response | Safely returned unavailable / Other. |

On Node.js **22.23.2**, the targeted run passed **25 checks**: four top-level tests, one containing 21 named subtests. The complete local backend suite passed **69 checks**: 48 top-level tests plus those 21 subtests, zero failed or skipped. Strict TypeScript checking of the new test and imported modules also exited successfully. These counts are separate from the previously completed 145 Flutter tests.

Evidence: [targeted TAP output](../evidence/security-0510/activity-input-tap.txt), [complete backend TAP output](../evidence/security-0510/backend-tests-tap.txt), [hashes and scope receipt](../evidence/security-0510/receipt.json).

Reproduction from `functions/`, using the pinned dependencies and Node 22:

```text
pnpm exec tsx --test test/activity-input.test.ts
pnpm test
pnpm exec tsc --noEmit --target ES2022 --module NodeNext --moduleResolution NodeNext --strict --esModuleInterop --skipLibCheck --noUncheckedIndexedAccess test/activity-input.test.ts
```

This is evidence for the listed cases and the reviewed service boundary. It does not prove the deployed HTTP/Firebase stack, all possible inputs, all backend routes, or absence of every vulnerability. The optional backend remains undeployed. Existing identity regressions separately cover canonical wallet/UID binding.

## 2. Actual packaged Android component output

The ARM64 artifact is the already published `FOR-THE-RECORD-0.5.10-arm64.apk`, versionCode **2017**, SHA256 **3b2e8a11ad1a322dfcc510d46d90097c246fd995adaa1c7ff9d2984d94f19564**. App/tag source is **9de8139614cfd0c6374036e0b0ceb68abeee7602**. No new APK was built for this evidence update.

The complete, unmodified [packaged ARM64 manifest dump](../evidence/security-0510/packaged-arm64-manifest.txt) is now attached, together with [verbatim build-gate output](../evidence/security-0510/packaged-gate-output.txt). The output was recorded during the original October 4 release checks; it is not presented as another run.

```text
Release manifest verified: app-arm64-v8a-release.apk
Release manifest verified: app-x86_64-release.apk
```

The original 0.5.9 APK failed the same check:

```text
Release APK contains a test component. Inspect releaseRuntimeClasspath before publishing.
```

The 0.5.10 package no longer contains the three unnecessary AndroidX test activities. The intended MAIN/LAUNCHER activity remains available and its physical read-only MWA connection was previously verified. The full manifest exposes the remaining SDK components for inspection rather than claiming that every exported component is absent or comprehensively audited.

Methods and open findings: [0.5.10 packaging/audit triage](AUDIT_TRIAGE_0510.md), [packaging receipt](../evidence/release-manifest-0510.json), [build gate at the app tag](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/v0.5.10/tools/verify-release.ps1).

## Remaining limits

The three optional-backend dependency advisories and web3.js v1 migration remain open. There is no new paid/free portal audit, independent penetration test, production backend deployment, current continuous production-device recording, or independent user study. The latest actual AI Coach remains **79/100**; these newly attached proofs have not yet been reassessed. The entry remains **DRAFT**.
