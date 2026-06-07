# Agent instructions — Intrai-2

## Project

On-device iPhone chat app using llama.cpp. See [CONTEXT.md](CONTEXT.md).

## Before coding

Discovery complete (2026-06-06). MVP plan approved — see `~/.cursor/plans/intrai-2_mvp_plan_ce25251c.plan.md`. **Slices 0–3 committed; Slice 4 complete (uncommitted); next: Slice 5.** See `docs/discovery/handoff-latest.md`.

## Docs authority

`docs/product-brief.md` > `docs/technical-brief.md` > `docs/design-handoff.md` > HTML mocks > agent memory

HTML mocks in `docs/archive/design-mocks/` are **canonical design** (layout, typography, spacing, copy treatment). Implement in SwiftUI per mocks + `docs/design-handoff.md`; do not literal-port HTML/CSS syntax.

## Resuming work

1. Read [CONTEXT.md](CONTEXT.md) and [docs/discovery/handoff-latest.md](docs/discovery/handoff-latest.md)
2. Use `resume-work` skill
3. Continue grill-me for open decisions

## Checkpoint cadence

After ~5–7 locked grill-me decisions or at session end:

- Update the three briefs
- Rewrite `docs/discovery/handoff-latest.md`
- Save process notes to agentmemory only (not UI particulars)

## Technical reference

Phathom agentmemory lessons cover llama.cpp iOS pitfalls, xcframework build, streaming patterns. Search before inventing new inference patterns.

## Design probes

Use `design-mock-probe` + `grill-me` before canonical HTML mocks. Review in Safari. Archive canonical mocks under `docs/archive/design-mocks/` when created.
