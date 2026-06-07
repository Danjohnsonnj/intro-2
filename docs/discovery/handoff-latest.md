# Session handoff — Intrai-2

**Updated:** 2026-06-06 (nav chrome design pass; Slice 2 next)

Cold-start agents: read [CONTEXT.md](../../CONTEXT.md), this file, [docs/design-handoff.md](../design-handoff.md), then the approved plan.

**Canonical design:** HTML mocks in `docs/archive/design-mocks/` are canonical for layout, typography, spacing, and control chrome. Implement via Swift components in `Intrai2/Design/` — do not literal-port HTML/CSS.

```
<handoff>
GOAL: Slice 2 conversation CRUD — match canonical mocks while building features
ENV: intrai-2 | Intrai2.xcodeproj | Slices 0-1 + design alignment done
STATE: InstrumentPanel + InstrumentNavChrome | flat nav (no Liquid Glass)
PHASE: implementation — Slice 2 next
DONE:
  - Slice 0-1 (inference, model import, banner)
  - Design bucket A (list/settings surfaces, tokens, instrument groups)
  - Nav chrome: InstrumentNavGlyph/BackButton, sharedBackgroundVisibility(.hidden),
    left-aligned Conversations title, custom flat back on Settings, nav bar hairline
TODO:
  - Slice 2 per plan + slice design checklist in design-handoff.md
NEXT: Slice 2
BLOCKED: none
</handoff>
```

## Design — implemented (list + settings)

- Flat bronze **+**, **⚙**, **‹** — no iOS 26 Liquid Glass (`InstrumentNavChrome.swift`)
- List title left-aligned; Settings title centered + custom back
- Opaque nav bar + hairline / inset highlight (`instrumentNavigationBar()`)
- Instrument settings groups, banner, list rows, timestamps (prior pass)

## Design — deferred by slice

See full table in [docs/design-handoff.md](../design-handoff.md) § Slice design checklist.

| Slice | Deferred design items |
|-------|----------------------|
| **2** | Trailing swipe **Delete** (`Theme.swipeDelete` / `#C94A4A`); `+` action creates conversation + pushes empty chat |
| **3** | Chat thread: message bubbles, compose bar, flat **‹** + centered title + flat **⋯** (`InstrumentNavChrome` reuse) |
| **4** | Send → **Stop** morph: solid bronze button, square stop icon (filled — not flat glyph) |
| **6** | **System prompt** editor (`codeBackground`) + mono token hint; **n_ctx** / **temperature** steppers (`surfaceRaised` buttons) |
| **7** | MarkdownUI in bubbles; code blocks SF Mono + `#2A2826` |
| **8** | Leading swipes **Rename** (raised surface) + **Export** (bronze); active row `accentSubtle` + 3px bronze bar |
| **9** | Light mode validation against handoff light palette |

## Design — Swift-only (keep)

| Item | Notes |
|------|-------|
| Loading / load-failed status + inline errors | Slice 1 functional; not in mocks |
| Inference section placeholder | Replaced in Slice 6 |

## Resume prompt

```
Resume Intrai-2. Read CONTEXT.md, docs/discovery/handoff-latest.md, docs/design-handoff.md, and ~/.cursor/plans/intrai-2_mvp_plan_ce25251c.plan.md.
Continue Slice 2 (conversation list CRUD). Apply slice design checklist when building each surface.
```
