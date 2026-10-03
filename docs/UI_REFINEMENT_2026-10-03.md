# Journal UI refinement — 0.5.4

The room, original artwork, three-page onboarding, app identity and local record schema stay intact. The journal uses a clearer hierarchy inspired by official Toss Design System guidance, without copying Toss branding or assets.

## Applied rules

- One prominent action at the bottom of the writing screen. Save remains reachable above the software keyboard; optional navigation has lower emphasis.
- Compact activity cards show type, date, known amounts and the next action. Unknown activities retain their truthful label; amounts are never inferred.
- Source details live in an expandable section. Wallet and signature are available on demand instead of competing with the note.
- The saved original reason appears first on record detail. Empty optional fields are omitted.
- The reflection AI offers a question in the writing flow. Model deletion and implementation details belong in AI settings.
- Text scales with system accessibility settings. The fixed action area adds no custom motion.

## Primary references

- [Toss Button](https://tossmini-docs.toss.im/tds-mobile/components/button/): primary/secondary emphasis and loading state.
- [Toss Typography](https://tossmini-docs.toss.im/tds-mobile/foundation/typography/): consistent hierarchy and scalable text.
- [Toss FixedBottomCTA](https://tossmini-docs.toss.im/tds-mobile/components/BottomCTA/fixed-bottom-cta/): predictable primary action placement.
- [Toss ListRow](https://tossmini-docs.toss.im/tds-mobile/components/ListRow/list-row-overview/): compact, readable information groups.

## Verification

- 103 Flutter tests passed, including 360px layouts, eight UI languages at 200% text, saved reason/source integrity, reflection, export and persistence.
- New regression verifies that Save stays above a 300px keyboard at 360x800 and that full wallet information is hidden until the source section is opened.
- Updated English journal/editor golden images were visually inspected before acceptance.
- Static analysis: no issues.

These are implementation and automated accessibility checks, not user research or a complete accessibility audit. Physical-device and release evidence is recorded separately after it is completed.
