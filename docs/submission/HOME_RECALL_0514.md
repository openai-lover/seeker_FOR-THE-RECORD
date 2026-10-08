# Home recall — 0.5.14+21

## The product loop

Keep the reason behind an existing wallet action. Revisit it in your own words. Before a similar choice, open **Recall saved notes** from Home and retrieve the original reason, reflection and lesson.

Home recall works without an active wallet connection or another transaction. The user explicitly selects a wallet already represented in local saved records. No note content is displayed until that selection. Manual browsing is available without the optional AI model. AI search uses the same multilingual-e5-small Q8 model and unchanged conservative single-source policy, over up to 32 recent records from the selected wallet.

Wallet changes clear query/results. Query changes, record edits/deletion, cancellation and page closure invalidate pending responses. A local read failure offers Retry rather than claiming that the journal is empty. No database migration, new permission, signing, RPC call or AI service account is introduced by this feature.

## Validation on October 8, 2026

The supplied October 7 patch did not include an executed Flutter test/build. In the complete checkout, the applied patch passed clean analysis and all **287 Flutter tests**, including six new home-recall widget tests. The focused recall/journal/localization suite passed 47 tests. Two changed Home golden images were visually inspected and updated; other golden images remained unchanged.

Cases cover empty/read-error/retry, exact original text, explicit wallet scope, missing model, no match, wallet switching during a delayed response, edited query, cancellation, deletion and closing the page. These are automated checks, not independent human use or AI accuracy.

`tool/home_recall_0514.dart` is an explicitly enabled debug-only, exact `.integration` package harness. It uses four authored DEMO notes in a MemoryRepository across two public fixture addresses; it never opens a journal database or connects a wallet/RPC service. Its UI is the current product UI. Capture results and packaged-release checks are recorded separately when completed.

## Evidence that retains its date

The 0.5.12 normal production 9:17 capture, selected historical public-RPC swap capture and real-day due-card check remain separate, dated evidence. The 0.5.10 multilingual authored evaluation remains unchanged. New navigation is not a new model-quality measurement. One developer/owner personally reviewed 0.5.12; no external pilot or independently labelled AI study has been completed. Historical audit triage and remaining optional-backend advisories remain scoped and unresolved as documented.
