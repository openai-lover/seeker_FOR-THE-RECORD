# FOR THE RECORD · Current product walkthrough

**0.5.14+21**, development-signed ARM64 app. [Download and exact checksum](DOWNLOAD_LINKS.md). This page describes the current interface; versioned old walkthroughs remain historical.

## The room and personal work

Three welcome pages support swipe and Skip. The desk opens the decision journal, the lamp opens focus, and the shelf opens saved work. A personal work project needs no wallet or paid AI service. Eight UI languages and reduced motion are available in Settings.

## A reason connected to existing activity

1. **Leave a reason** opens the journal. Native MWA/Seed Vault selects an account for read-only activity; no message or transaction signing is needed.
2. **Activity** shows finalized history. A confidently recognized swap has **Write reflection**. A successful Other activity has **Add a personal note**, with its original source and no invented swap amounts. Failed, unavailable and unparseable activity cannot become a saved wallet note.
3. One reason enables **Save reason**. **Add details** is optional. A revisit can be in 1, 3 or 7 days, or have no date.
4. **My notes** and the room's latest reason reopen saved writing. The saved reason appears first; source facts expand separately. **Reflect** supports an immediate manual revisit, while due notes also appear on the home screen when their real due time arrives.
5. The user writes the reflection and lesson. Optional local AI recalls an exact original record or suggests a question. Suggestions may be wrong; original text and manual browsing remain available. Edited queries invalidate old results.
6. **Export this record** uses Android's file picker. The interface distinguishes pending, saved, cancelled and failed states. A saved result follows native write, flush and close. Records remain in SQLite after export. JSON contains private writing; it is not cloud backup or import/restore.

The optional multilingual-e5-small Q8 model is 132,439,008 bytes. It retrieves existing text; it does not generate a person's reason or lesson. After preparation, inference works without app Internet access. The normal activity reader still needs an available RPC connection; public infrastructure can rate-limit.

## Home recall before the next choice

1. From Home choose **Recall saved notes**; no new transaction or active wallet connection is required.
2. Select a locally saved wallet explicitly before note content appears.
3. Open **Browse saved records** to read the exact original reason/reflection/lesson/source without the optional model.
4. With a prepared model, ask a question to search up to 32recent notes in that wallet. Read the one original suggestion, or browse manually if no close record is found. Suggestions can be wrong.
5. Changing wallets clears the query/results. Query/record changes, cancel and leaving invalidate late replies. A local read failure offers Retry.

## Reproduction and evidence

[HOME_RECALL_0514.md](HOME_RECALL_0514.md) records the current feature checks:287 Flutter tests, clean analysis, both release package gates, actual Seeker isolated authored-DEMO browsing/search and wallet clearing. Current3-minute edited footage uses MemoryRepository, no Internet/MWA/RPC or productionSQLite. It does not prove current production persistence or independent accuracy. [Matched materials](MATERIALS_0514.md) records the11 slides/notes and video scope.

Historical [PRODUCTION_FLOW_0512.md](PRODUCTION_FLOW_0512.md) records9:17normal production read-onlyMWA/RPC successfulOther, authoredDEMO, reflection/lesson, completed export/restart and two 2,029Bjournals matching except export timestamps. One prepared/network-available request2355ms is not a distribution or accuracy claim. The selected [public historical swap](FRESH_PUBLIC_CASE8_0512.md) is isolated, not owned/newtrade/heldout; the [25.8-hour due card](REAL_DAY_DUE_0512.md) is technical foreground state, not human retention or a notification.

The dated [0.5.10AI/proof report](CURRENT_PROOF_0510.md) keeps authored labels and every failure. [Scoped input/package proof](SECURITY_PROOF_0510.md) and [current audit addendum](AUDIT_LEAD_ADDENDUM_0512.md) are not comprehensive clearance. One owner review; no independent raters/external pilot. [Actual76-point Coach feedback](REVIEW_076_0514.md). Raw personal data remains private; no financial transaction or new signature was performed.
