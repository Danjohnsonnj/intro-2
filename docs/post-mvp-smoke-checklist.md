# Intrai-2 Post-MVP Smoke Checklist

**Status:** Passed — signed off 2026-06-08 (device + simulator).

**Slice 10 (A1)** — UI settle before inference.

MVP checklist ([mvp-smoke-checklist.md](mvp-smoke-checklist.md)) stays frozen.

## Setup

- [x] **Simulator (primary):** arm64 iPhone simulator — settle sequence observable without device inference
- [x] **Device (optional spot-check):** iPhone 16 Pro+, iOS 26.4+, imported GGUF — one send confirms stream still works after settle gate
- [x] Model loaded (device spot-check only)

## A1 — Settle sequence on Send

- [x] Tap Send with keyboard up → keyboard dismisses before bubbles appear
- [x] Compose clears; Send morphs to Stop; empty assistant bubble + "Generating…" appear
- [x] Thread scrolls to bottom (animated) before first token (device) or before settle window ends (simulator)
- [x] After settle (~300ms max), inference begins (device) or generation state persists through settle (simulator)

## A1 — Settle-window Stop

- [x] Send, then Stop within ~300ms → both placeholder bubbles removed
- [x] Sent text restored in compose field
- [x] Keyboard re-focuses on compose
- [x] No messages persisted (relaunch shows thread unchanged)

## A1 — Navigate away during settle

- [x] Send, then back within ~300ms → same rollback as Stop (no re-focus required after leave)
- [x] Return to thread → no new user/assistant messages persisted

## A1 — Cancel-then-send

- [x] While streaming, type new message and Send → prior stream cancels
- [x] Full settle sequence runs for new message (keyboard dismiss, scroll, then infer on device)
- [x] Partial prior assistant content retained

## A1 — Double Send during settle

- [x] Rapid double-tap Send during settle window → second Send ignored (no duplicate bubbles)

## A1 — Persist timing

- [x] Stop during settle → relaunch shows no new messages
- [x] Complete send on device → messages persist after relaunch

## Regression (MVP paths)

- [x] Stop during active generation still keeps partial assistant content
- [x] Auto title still generates after first completed exchange (device)
- [x] Export / copy / rename unchanged

## Notes

- Long-thread scroll fix (2026-06-08): `scrollToBottomAfterLayout` targets `streamingMessageID` so LazyVStack materializes the assistant placeholder on full-screen threads.
