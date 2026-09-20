# Keeping the preview free to run

The journal's useful core should not require a paid cloud deployment. Work records and reflections live in SQLite on the phone. Native Mobile Wallet Adapter supplies the selected wallet account. The direct read-only path can request public Solana activity without Firebase Authentication, Functions or a billing upgrade.

The direct implementation is in `lib/data/direct_activity.dart`. Check the current release evidence before treating the full wallet path as validated. A real-wallet run on a physical device remains separate from parser tests and emulator demonstrations.

## Scope

| Capability | Preview approach |
|---|---|
| Projects, focus sessions and reflection text | Local SQLite, no cloud service needed |
| JSON export | Android file picker, no cloud account needed |
| Wallet selection | Native Mobile Wallet Adapter |
| Supported finalized activity | Direct read-only public RPC requests |
| Shared rooms and server-verified access | Optional cloud feature, unavailable without its backend |
| SKR purchases | Disabled in this preview |

The direct journal path does not request a trade or payment. Reading chain data does not submit an on-chain transaction. There is no need to upgrade Firebase just to try the local journal or the direct wallet-reading design.

## What free public RPC does and does not provide

Public RPC is shared infrastructure. Solana documents rate limits, possible blocking and no production service guarantee. Requests can fail even when the app is correct. Keep refreshes deliberate, bound activity pages, retain local writing during failures, and show a retry state. Do not promise unlimited requests, permanent availability or zero future operating cost.

The current client limits a page to eight signatures, caches a successful page for 60 seconds, combines duplicate pending requests and allows at most two RPC calls at once. It caps each call at two attempts and uses an eight-second request timeout. For a rate-limit response, it respects a short `Retry-After` delay; a longer cooldown is surfaced to the user without an immediate retry. These are application limits that reduce avoidable traffic. They are not a guarantee that a shared endpoint will accept every request.

For a broader launch, choose a suitable RPC service according to measured usage. A provider's free allowance may be enough initially, but its current limits and terms need a fresh review. A private provider credential should not be committed to a public repository or treated as secret after it has been embedded in a mobile app.

Sources checked 20 September 2026: [Solana public endpoints](https://solana.com/docs/references/clusters), [production readiness](https://solana.com/docs/tools/production-readiness), [Mobile Wallet Adapter overview](https://docs.solanamobile.com/developers/mobile-wallet-adapter).
