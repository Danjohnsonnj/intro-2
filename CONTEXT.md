# Intrai-2

Private, on-device LLM chat for iPhone. Runs local models via llama.cpp + Metal. Built primarily for personal use; unlikely App Store distribution.

## Status

**Discovery complete** — signed off 2026-06-06. Grill-me Q1–Q20 locked; canonical design mocks approved.

**MVP plan approved** — reviewed 2026-06-06. Plan: `~/.cursor/plans/intrai-2_mvp_plan_ce25251c.plan.md`

**Slice 0 complete** — git, Xcode scaffold, SwiftData, Theme, NavigationStack, README (2026-06-06).

**Slice 1 complete** — text-only inference port, ModelManager, Settings model import/forget, no-model banner (2026-06-06).

**Slice 2 complete** — conversation list CRUD: `+` create/push, row open, trailing Delete swipe, `ChatThreadView` shell (2026-06-07).

**Design alignment** — list + settings surfaces + flat nav chrome (no Liquid Glass on +, gear, back) per canonical HTML mocks (2026-06-06).

**Next session:** Slice 3 — chat send, stream, persist, compose bar. See `docs/discovery/handoff-latest.md`.

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
