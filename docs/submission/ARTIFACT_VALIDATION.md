# Media validation — preview 0.3.1

Checked on 20 September 2026.

- Final demo decoded completely without reported decoder errors: **5,400 frames, 30 fps, 180.000 seconds of video**, 1920 × 1080 H.264. AAC container padding can display a total duration of approximately 180.02 seconds in some players.
- The edit contains 123 seconds of recorded Android app footage, 32 seconds of actual app still captures, and 25 seconds of original motion/graphics. First app interaction starts at 0:08. Language selection uses the actual eight-choice screenshot to keep the content and caption aligned.
- Sample activity carries a persistent visible label. The genuine native wallet approval recording is separately labeled **Official mock wallet / Android emulator**. It returns an empty mainnet history. It does not show a live swap, payment, physical Seeker or Seed Vault validation.
- The final English SRT and VTT timings match the 180-second edit. The video has on-screen explanations, an original quiet two-note opening sound, and no spoken narration.
- The editable eight-slide PPTX passed package integrity, geometry, font policy and import checks with no findings. All eight imported slides were rendered and visually inspected. Native Microsoft PowerPoint execution was not tested.
- The eight-page PDF was exported from those final rendered slides, rendered again with Poppler, and visually inspected. It preserves the final deck appearance; the PPTX is the editable version.
- Slide 3 shows the actual saved next action prefilled on return. Slide 4 enlarges the reopened sample reason and plan and retains a clear sample-data caption.
- The original GitHub intro GIF is 960 × 540, 12 fps and **445,665 bytes**. README includes a static image fallback for reduced-motion browsers. A separate eight-second MP4 intro is supplied for reuse.
- No Envato asset, template frame, external music or third-party speaker voice is included. The vector mark, typography animation and two-note sound were created for this project.

See [DOWNLOAD_LINKS.md](DOWNLOAD_LINKS.md) for the exact Android artifact and [SHA256SUMS.txt](SHA256SUMS.txt) in the delivery package for file hashes. App/network evidence is described separately in [README.md](README.md), [DEVICE_REHEARSAL.md](DEVICE_REHEARSAL.md) and the [release checklist](RELEASE_CHECKLIST.md).
