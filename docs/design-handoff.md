# Design handoff — Intrai-2

**Status:** Discovery complete (signed off 2026-06-06)  
**Last updated:** 2026-06-06

Locked visual and UX decisions for mocks and SwiftUI implementation. Authority: this doc > HTML mocks.

## Direction

**"Private instrument"** (Option A) borrowing **native iOS discipline** (Option B).

Not generic "AI app" aesthetic. Signals local, private, tool — not cloud chatbot.

**Premium polish (mock v3):** warmer ivory ink, generous row rhythm, bronze accent bar on active list row, inset surface highlights, aligned compose controls — same private-instrument direction.

## Mode & color

| Token | Value | Notes |
|-------|-------|-------|
| Default mode | **Dark-first** | System light mode supported |
| Background | Warm off-black | Not pure `#000` |
| Accent | Shiny bronze | Not purple gradients |
| Surfaces | Flat | Subtle 1px borders over heavy shadows |
| User bubble | Right-aligned tint | Minimal |
| Assistant bubble | Left-aligned neutral surface | Markdown is the star |

### Palette (mock probe — 2026-06-06)

| Token | Hex / value | Usage |
|-------|-------------|-------|
| `--bg` | `#121110` | Warm off-black root |
| `--surface` | `#1C1B19` | Cards, compose bar, assistant bubble |
| `--surface-raised` | `#252422` | Stepper controls, elevated fills |
| `--border` | `rgba(237, 234, 230, 0.08)` | Hairline dividers |
| `--text-primary` | `#F0EDE8` | Body, titles — warm ivory |
| `--text-secondary` | `#9A9690` | Secondary labels |
| `--text-tertiary` | `#6B6762` | Timestamps, hints, metadata |
| `--accent` | `#CDA963` | Shiny bronze — actions, send, nav tint |
| `--accent-subtle` | `rgba(205, 169, 99, 0.12)` | Active row highlight |
| `--user-bubble` | `rgba(205, 169, 99, 0.11)` | User message fill |
| `--code-bg` | `#2A2826` | Code blocks, prompt editor |
| `--status-ready` | `#7A9A7E` | Sage status dot ("Model loaded") |
| `--banner-text` | `#C4A862` | No-model banner |
| `--destructive` | `#B85C5C` | Forget model |

### Spacing rhythm

| Token | Value | Usage |
|-------|-------|-------|
| Screen horizontal inset | 16–20px | List rows, thread padding |
| Row vertical padding | 14px | Conversation list |
| Message gap | 16px | Thread between messages |
| Bubble padding | 10px 14px | Message content |
| Section gap | 28px | Settings groups |
| Corner radius sm/md/lg | 8 / 12 / 18px | Banner, groups, bubbles |

## Typography

| Role | Font |
|------|------|
| UI | SF Pro |
| Code / metadata | SF Mono |
| Status copy | Small caps metadata style — honest, not anthropomorphic |

Examples: "Generating…", "Model loaded", "Ready" — not "Thinking…" with sparkles.

## Hard nos

- Purple-on-gradient AI cliché
- Mascots / anthropomorphic "assistant" personality in chrome
- Heavy glassmorphism
- Bubble tails (default no)
- Sparkle / "thinking" animations

## Markdown in messages

- MarkdownUI rendering (stream-safe, coalesced updates)
- Readable code blocks (mono, subtle background, tight padding)
- List rhythm (consistent indent, spacing between items)
- Per-message **Copy markdown** in context menu

## Screens (MVP)

### Conversation list

- `NavigationStack` root
- Rows: **title + relative timestamp only** — no message preview
- **No-model banner:** `12px` vertical margin, `22px` horizontal inset (matches list row padding)
- **Swipe actions** (Mail / Phathom pattern — no hint copy):

| Edge | Label | Style | Action |
|------|-------|-------|--------|
| Trailing | `Delete` | Destructive red | Remove conversation |
| Leading | `Rename` | Neutral raised | Inline rename; sets `titleLocked` |
| Leading | `Export` | Accent bronze | Export `.md` → share sheet |

- Toolbar: `+` (creates row + pushes chat immediately), gear
- **No model:** persistent top banner → Settings
- **Empty:** centered *"No conversations"* / *"Tap + to start"* — no illustration, no wizard

### Chat

- Message thread with MarkdownUI
- Multiline compose (~5 lines max); Return = newline
- Send morphs to **Stop** while generating
- Nav: back chevron; edge swipe pop to list
- Nav title: tap to rename inline; `titleLocked` on save
- `⋯` menu: Rename, Export

### Settings

- Back chevron (same as chat); edge swipe pop to list
- Model import (GGUF picker) + Forget
- Global system prompt (multiline editor; token/char hint below)
- Context length (`n_ctx`), temperature
- Inference status indicator

## Mock workflow

Per `design-mock-probe` skill:

1. Grill-me locks surface decisions in this doc
2. Emit `<mock-handoff>` packet → subagent builds HTML/CSS
3. Review in Safari (side-by-side: empty/populated, idle/generating, no-model)
4. Mocks are **ephemeral** — never literal-ported to SwiftUI
5. Canonical mocks → `docs/archive/design-mocks/`

## Mock inventory

| Surface | Canonical file | Status |
|---------|----------------|--------|
| Conversation list | `docs/archive/design-mocks/conversation-list-ad-empty-populated.html` | Done — Empty, Populated, Swipe delete/export, No-model banner |
| Chat thread | `docs/archive/design-mocks/chat-ad-idle-generating.html` | Done — At rest, Generating |
| Settings | `docs/archive/design-mocks/settings-ad-grouped-a.html` | Done — Model loaded, No model |

Open in Safari: see `docs/archive/design-mocks/README.md`.

## Changelog

| Date | Change |
|------|--------|
| 2026-06-06 | Checkpoint 1 — direction, tokens, screens from grill-me Q6–Q8 |
| 2026-06-06 | Checkpoint 2 — Q14–Q20 UX: title edit, compose, stop/send, empty states, export menu |
| 2026-06-06 | Mock probe — palette/spacing finalized; list, chat, settings HTML mocks |
| 2026-06-06 | List mock v2 — Mail-style swipe (trailing delete, leading rename/export); chat stop icon fix |
| 2026-06-06 | Canonical mocks v3 — premium polish pass (spacing, ink, active row, compose alignment) |
| 2026-06-06 | Nav: back chevron + edge-swipe pop; banner spacing aligned to row inset |
| 2026-06-06 | Accent updated to shiny bronze `#CDA963` |
| 2026-06-06 | Discovery signed off — phase complete; mocks canonical |
