# Intrai-2

Private, on-device LLM chat for iPhone. Runs local models via llama.cpp + Metal. Built primarily for personal use; unlikely App Store distribution.

## Status

**Discovery complete** — signed off 2026-06-06. Grill-me Q1–Q20 locked; canonical design mocks approved.

**MVP plan approved** — reviewed 2026-06-06. Plan: `~/.cursor/plans/intrai-2_mvp_plan_ce25251c.plan.md`

**MVP signed off** — all 9 vertical slices shipped and smoke-validated (2026-06-08). Checklist: [docs/mvp-smoke-checklist.md](docs/mvp-smoke-checklist.md) (passed).

| Slice | Summary |
|-------|---------|
| 0 | Git, Xcode scaffold, SwiftData, Theme, NavigationStack |
| 1 | Text-only inference, ModelManager, Settings model import/forget |
| 2 | Conversation list CRUD, trailing Delete swipe |
| 3 | ChatViewModel, streaming generation, compose bar |
| 4 | Stop morph, cancel-then-send, partial persist |
| 5 | SlidingWindowTrimmer, trim notice, decode recovery |
| 6 | Settings: system prompt, `n_ctx`, creativity slider |
| 7 | MarkdownUI bubbles, copy message, export `.md` |
| 8 | Auto title, rename paths, list swipes, active row |
| 9 | Light mode, smoke checklist, MVP docs checkpoint |
| 10 | **Planned** — A1 UI settle before inference (see plan below) |

**Design alignment** — list + settings + chat per canonical HTML mocks; flat nav chrome; system light + dark supported.

**Post-MVP:** Slice 10 (A1) planned and reviewed — plan: `~/.cursor/plans/slice_10_a1_settle_b79a4cd1.plan.md`. Spec: [docs/technical-brief.md](docs/technical-brief.md) § Slice 10 A1. Handoff: [docs/discovery/handoff-latest.md](docs/discovery/handoff-latest.md).

## Docs (source of truth)

| Doc | Purpose |
|-----|---------|
| [docs/product-brief.md](docs/product-brief.md) | Requirements, user stories, MVP scope |
| [docs/technical-brief.md](docs/technical-brief.md) | Architecture, llama.cpp, persistence, extensibility |
| [docs/design-handoff.md](docs/design-handoff.md) | Visual language, components, mock workflow |
| [docs/mvp-smoke-checklist.md](docs/mvp-smoke-checklist.md) | Device acceptance checklist |
| [docs/discovery/handoff-latest.md](docs/discovery/handoff-latest.md) | Latest session handoff for cold-start agents |

## Session bootstrap

1. Read this file and `docs/discovery/handoff-latest.md`
2. Read the three briefs for locked decisions
3. **Implementation:** MVP shipped; next slice is 10 (A1 settle) per plan + technical brief
4. Mocks: `docs/archive/design-mocks/` — **canonical design**; implement in SwiftUI per `docs/design-handoff.md`

## Relationship to Phathom

Borrow proven llama.cpp iOS patterns from Phathom (inference lifecycle, xcframework, pitfalls). Intrai-2 is a greenfield app — not a Phathom fork — focused on chat only.
