# FOR THE RECORD · Current product walkthrough

**0.5.11+18**, development-signed ARM64 app. [Download and exact checksum](DOWNLOAD_LINKS.md). This page describes the current interface; versioned old walkthroughs remain historical.

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

## Reproduction and evidence

[PRODUCTION_FLOW_0511.md](PRODUCTION_FLOW_0511.md) records current production verification of the installed production app: one 608.07-second / 10:08 session at 1× with no internal cuts, existing MWA authorization, actual direct read-only RPC, successful Other, agent-authored DEMO writing, immediate reflection/question choice, lesson, completed 2,009-byte export and force-stop/reopen. A second 2,009-byte export had identical `tradeJournals` data and a different export timestamp. The privacy-reviewed public video is published at 1× with no internal cuts; matching presentation and hashes are in [MATERIALS_PRODUCTION_0511.md](MATERIALS_PRODUCTION_0511.md). No supported live swap, delayed due completion or independent human study is claimed. No edits to prior personal records were observed; whole prior database equality was not verified.

The question selector took 2,373 ms once with the model prepared and network available. The operator chose 1 from candidates 1 and 5. This is a single production observation, not an offline benchmark or general accuracy.

[CURRENT_PROOF_0510.md](CURRENT_PROOF_0510.md) documents an 8:08 continuous physical Seeker run of the 0.5.10 UI, parser, real isolated SQLite and native AI with public finalized response fixtures and authored notes. Both 2,264-byte exports have identical journal payloads after restart. The separate `.integration` app has no INTERNET permission and never opens the production database. Its displayed account context comes from public response fixtures, not wallet ownership or authorization.

The 0.5.11 UI cleanup retains the same parser, AI and export behavior. [PRODUCT_UI_0511.md](PRODUCT_UI_0511.md) describes the new user-facing copy and current checks.

The same dated report includes 48 fresh frozen authored queries and all false positives/abstentions, not independent human accuracy. [SECURITY_PROOF_0510.md](SECURITY_PROOF_0510.md) gives focused malformed-input regressions and actual packaging outputs. The new production verification and older public recordings are separately dated; raw files remain private and only the reviewed privacy-covered derivative is public. No supported live user trade, consented repeat-use pilot or comprehensive security clearance is asserted.
