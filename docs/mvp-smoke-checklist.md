# Intrai-2 MVP Smoke Checklist

**Status:** Passed — signed off 2026-06-08 (device + simulator).

Manual validation for MVP acceptance (Slice 9). Derived from `intrai-llama/docs/mvp-smoke-checklist.md` — **web search, recap compaction, and instrumentation items removed.**

## Setup

- [x] **Device (preferred):** iPhone 16 Pro or newer, iOS 26.4+
- [x] **Simulator (UI only):** arm64 iPhone simulator — navigation, SwiftData, export/copy, markdown layout
- [x] Local `vendor/llama/llama.xcframework` built (`./scripts/setup-llama-xcframework.sh`)
- [x] Test `.gguf` model available for import (device runs)

## Simulator limitations

| Area | Simulator | Device |
|------|-----------|--------|
| Metal GPU | CPU only (`n_gpu_layers = 0`) | Metal (`n_gpu_layers = -1`) |
| Model load / generation | Requires xcframework; CPU inference very slow or impractical for large models | Full MVP inference path |
| Title generation | Serialized on inference actor — needs loaded model | Same |
| Performance | Not representative | Use for perf sanity |

## User story 1 — Import model

- [x] Launch with no model → list shows **No model loaded** banner → Settings
- [x] Import GGUF via Files picker succeeds
- [x] Model name appears in Settings; banner clears on list
- [x] Forget model clears selection; banner returns; messages persist
- [x] Relaunch restores bookmarked model (no re-import)

## User story 2 — Start chat

- [x] `+` creates conversation and pushes empty chat
- [x] Send streams assistant reply token-by-token (device)
- [x] Messages persist after relaunch
- [x] List sorts by `updatedAt` (most recent first)

## User story 3 — Stop generation

- [x] Send morphs to Stop while generating
- [x] Stop keeps partial assistant content
- [x] Cancel-then-send: new message cancels in-flight stream first

## User story 4 — Resume history

- [x] Quit app mid-conversation → relaunch → thread intact
- [x] Multi-turn history continues generating (device)

## User story 5 — Manage conversations

- [x] List rows: title + relative timestamp only (no preview)
- [x] Trailing swipe Delete removes conversation
- [x] Leading swipe Rename opens sheet; sets `titleLocked`; persists
- [x] Auto-title after first exchange (device; 3–6 words from first user message)
- [x] Manual rename (nav tap, ⋯, list swipe) skips auto-title
- [x] Active row shows bronze accent after returning from chat

## User story 6 — Read formatted replies

- [x] Markdown renders: headings, lists, bold, code blocks
- [x] Stream re-parse during generation (no flicker storm)
- [x] Light mode: readable contrast on list, chat, settings

## User story 7 — Configure inference

- [x] System prompt edit persists; empty restores default
- [x] `n_ctx` stepper persists; reload on save
- [x] Creativity slider (0.1–1.5) persists; applies on next send
- [x] Model change reloads on save (no confirmation dialog)

## User story 8 — Export & copy

- [x] Per-message context menu → Copy markdown → pasteboard
- [x] Chat `⋯` → Export → share sheet (`.md`)
- [x] List leading Export → share sheet (non-empty threads only)
- [x] Export format: `# title`, `## User` / `## Assistant`, raw body

## Cross-screen polish

- [x] Empty list: *No conversations* / *Tap + to start*
- [x] No model: send disabled in chat (dimmed compose action)
- [x] Settings gear and `+` use flat bronze glyphs (no Liquid Glass)
- [x] Edge swipe back from chat and Settings

## Multi-turn / trim (device)

- [x] 20+ turn thread still generates
- [x] Trim notice appears when sliding-window budget exceeded
- [x] Decode failure recovery (context recreate) — no permanent poison

## Light mode pass

- [x] System Settings → Light appearance
- [x] List: row text, borders, active row, swipes
- [x] Chat: bubbles, markdown, compose bar, nav chrome
- [x] Settings: grouped panels, prompt editor, sliders

## Exit criteria

- [x] All 8 user stories pass on **physical device**
- [x] Simulator pass for UI, persistence, export/copy, light mode
- [x] No critical crashes in CRUD, model load, generation, stop, export
- [x] Known issues recorded with severity and workaround — none blocking
