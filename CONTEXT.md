# Intrai-2

Private, on-device LLM chat for iPhone. Runs local models via llama.cpp + Metal. Built primarily for personal use; unlikely App Store distribution.

## Status

**Discovery complete** — signed off 2026-06-06. Grill-me Q1–Q20 locked; canonical design mocks approved.

**MVP plan approved** — reviewed 2026-06-06. Plan: `~/.cursor/plans/intrai-2_mvp_plan_ce25251c.plan.md`

**Slice 0 complete** — git, Xcode scaffold, SwiftData, Theme, NavigationStack, README (2026-06-06).

**Slice 1 complete** — text-only inference port, ModelManager, Settings model import/forget, no-model banner (2026-06-06).

**Slice 2 complete** — conversation list CRUD: `+` create/push, row open, trailing Delete swipe, `ChatThreadView` shell (2026-06-07).

**Slice 3 complete** — `ChatViewModel`, `ChatGenerationService`, `ChatPromptBuilder`, streaming persist, compose bar, flat ⋯ nav (2026-06-07).

**Slice 4 complete** — stop morph (■), cancel-then-send, chunked prefill cancel, `ChatComposeBar` + `ChatThreadBody` (2026-06-07).

**Slice 5 complete** — `ChatService`, `SlidingWindowTrimmer`, `NoOpContextAugmentation`, trim notice, decode -3 recovery (2026-06-07).

**Slice 6 complete** — `SettingsStore`, system prompt / `n_ctx` / creativity slider (0.1–1.5), reload on `n_ctx` change, wired into chat (2026-06-08).

**Slice 7 complete** — MarkdownUI bubbles (coalesced stream re-parse), code block styling, per-message Copy markdown, chat ⋯ Export → `.md` share sheet (2026-06-08).

**Slice 8 complete** — auto title after first exchange, rename (nav tap / ⋯ / list swipe, sets `titleLocked`), list leading Export/Rename swipes, active-row bronze accent (2026-06-08).

**Design alignment** — list + settings surfaces + flat nav chrome (no Liquid Glass on +, gear, back) per canonical HTML mocks (2026-06-06).

**Next:** Slice 9 — device smoke pass, light mode check, MVP acceptance gate. Slice 8 pending user commit. See `docs/discovery/handoff-latest.md`.

## Docs (source of truth)

| Doc | Purpose |
|-----|---------|
| [docs/product-brief.md](docs/product-brief.md) | Requirements, user stories, MVP scope |
| [docs/technical-brief.md](docs/technical-brief.md) | Architecture, llama.cpp, persistence, extensibility |
| [docs/design-handoff.md](docs/design-handoff.md) | Visual language, components, mock workflow |
| [docs/discovery/handoff-latest.md](docs/discovery/handoff-latest.md) | Latest session handoff for cold-start agents |

## Session bootstrap

1. Read this file and `docs/discovery/handoff-latest.md`
2. Read the three briefs for locked decisions
3. **Implementation:** follow approved MVP plan (9 vertical slices); read plan file first
4. Mocks: `docs/archive/design-mocks/` — **canonical design**; implement in SwiftUI per `docs/design-handoff.md`

## Relationship to Phathom

Borrow proven llama.cpp iOS patterns from Phathom (inference lifecycle, xcframework, pitfalls). Intrai-2 is a greenfield app — not a Phathom fork — focused on chat only.
