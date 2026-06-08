# Product brief — Intrai-2

**Status:** Discovery complete (signed off 2026-06-06)  
**Last updated:** 2026-06-06

## Vision

Intrai-2 is a **private, on-device AI chat app** for individuals who want conversational AI without sending data to the cloud. The core job: *talk to an AI that never leaves my device.*

Built primarily for personal use. Unlikely App Store publication.

## Background

Intrai v1 was under-planned, lacked cohesive design, and accumulated technical debt that was difficult to fix. Intrai-2 front-loads discovery to ensure smooth delivery.

## Target user

- **Primary:** Dan (solo user, power-user comfortable importing GGUF models)
- **Not targeting:** Mass-market consumers, teams, cloud sync users

## Platform constraints

| Constraint | Value |
|------------|-------|
| Device | iPhone only (v1) |
| Minimum hardware | iPhone 16 Pro or later |
| Minimum OS | iOS 26+ |
| Non-Apple platforms | Never |

## MVP scope (v1)

### In

- Import a GGUF file; persist security-scoped bookmark across launches
- Multiple conversations (local only)
- Multi-turn chat with **token streaming**
- **Stop generation** mid-stream
- **Persist messages** across app restarts
- **Markdown rendering** in assistant (and user) messages (MarkdownUI)
- **Export conversation** to `.md` file (share sheet)
- **Copy message** as markdown to clipboard
- Basic settings: model path, context length, creativity, **global system prompt**
- Conversation list with **auto-generated titles** (see below)
- Navigation: list → chat push; Settings via gear; swipe trailing delete, leading rename & export

### Out (v1)

- RAG / document upload
- Vision / multimodal
- Per-conversation system prompt editor
- iCloud sync
- Prompt library
- Widgets
- Background inference
- Web search (see roadmap)
- App Store polish / onboarding for novices

## Conversation list UX

- **No** last-message preview on list rows
- Row content: **subject title** + relative timestamp
- New conversation placeholder title: **"New conversation"**
- `+` creates row immediately and pushes empty chat
- After first complete exchange (user message + assistant reply): **one-time** auto-title (3–6 words) via on-device LLM from **first user message only**
- Manual title edit (tap nav title or `⋯` → Rename) sets `titleLocked` — auto-gen skipped
- **No** title regeneration

## Navigation

- Single `NavigationStack`, no tab bar
- Root: conversation list → push chat; gear pushes Settings
- **Back:** chevron in nav bar on pushed views (chat, Settings) — not "Done"
- **Edge swipe:** interactive pop from leading screen edge navigates back on pushed views (Phathom / system pattern)
- List row swipe (Mail pattern): trailing delete, leading rename & export — distinct from edge back gesture
- **No model:** persistent banner on list → Settings; send disabled in chat
- **Empty list:** minimal centered copy (*"No conversations"* / *"Tap + to start"*) — no onboarding wizard

## Chat UX

- Multiline compose: Return = newline, Send only to submit (~5 line max height)
- Send button morphs to **Stop** while generating; partial reply kept on stop
- New send while generating cancels in-flight stream first
- Per-message context menu: **Copy markdown**
- Conversation `⋯` menu: Rename, Export

## Roadmap (post-v1)

### Web search (v2)

- **User-initiated** per outgoing message
- Flow: user triggers search → query derived from message → privacy-focused provider (TBD) with **explicit permission** → results compressed into **hidden context block** for that turn → model replies; optional collapsible "Sources" under reply
- Architecture: pluggable `ContextAugmentation` step before inference (v1 ships no-op)

### Web search (later phase)

- Model-driven tool calling (LLM decides when to search)
- Still requires privacy-focused providers and explicit user permission

## User stories (MVP)

1. **Import model** — As a user, I can pick a GGUF from Files so the app remembers it across launches.
2. **Start chat** — As a user, I can create a new conversation and send a message that streams back token-by-token.
3. **Stop generation** — As a user, I can stop the assistant mid-reply.
4. **Resume history** — As a user, I can quit the app and return to the same conversations and messages.
5. **Manage conversations** — As a user, I can see titled conversations (no previews), open, delete, and edit titles.
6. **Read formatted replies** — As a user, I see markdown (code blocks, lists, emphasis) rendered cleanly in messages.
7. **Configure inference** — As a user, I can adjust model, context length, creativity, and global system prompt in Settings.
8. **Export & copy** — As a user, I can export a conversation as markdown or copy any message as markdown.

## Settings (v1 fields)

| Field | Default | Notes |
|-------|---------|-------|
| GGUF model | none | Security-scoped bookmark; global single model |
| System prompt | see technical brief | Editable; empty save restores default |
| Context length (`n_ctx`) | 4096 | 2048 / 4096 / 8192; reload on change |
| Creativity | 0.7 | Range 0.1–1.5, step 0.1; maps to sampler temperature; applies on next send |

Changing or removing model reloads on save; all conversations use active model on next send (no confirmation).

## Context & trimming

Long conversations exceed model context. v1: oldest turns dropped automatically (sliding window) with a subtle in-chat notice. v1.1+: optional summarization of dropped turns (see technical brief).

## Open product questions

- [x] Default system prompt exact copy — shipped in Slice 6 (`ChatPromptBuilder.defaultSystemPrompt`)

## Changelog

| Date | Change |
|------|--------|
| 2026-06-06 | Checkpoint 1 — initial brief from grill-me Q1–Q8 |
| 2026-06-06 | Q9 — sliding window trim v1; summarizing trimmer v1.1+ |
| 2026-06-06 | Checkpoint 2 — Q10–Q20: persistence, settings, markdown export/copy, title UX, chat controls, model policy, empty states |
| 2026-06-08 | Slice 7 shipped — MarkdownUI bubbles, per-message copy, chat Export → `.md` share sheet |
| 2026-06-08 | Slice 8 shipped — auto title after first exchange; rename (nav inline, ⋯ sheet, list swipe sheet); list leading Export/Rename swipes; active-row bronze accent |
