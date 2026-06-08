# Technical brief — Intrai-2

**Status:** MVP signed off — Slices 0–9 shipped; smoke passed 2026-06-08 ([mvp-smoke-checklist.md](mvp-smoke-checklist.md)). Slice 10 (A1) signed off — smoke passed 2026-06-08 ([post-mvp-smoke-checklist.md](post-mvp-smoke-checklist.md)).
**Last updated:** 2026-06-08

## Stack (locked)

| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| Platform | iPhone, iOS 26+, iPhone 16 Pro minimum |
| Inference | llama.cpp via vendored `llama.xcframework` |
| GPU | Metal on device (`n_gpu_layers = -1`); CPU on simulator (`n_gpu_layers = 0`) |
| Models | User-imported GGUF (security-scoped bookmarks) |
| Persistence | SwiftData (`Conversation` + `Message`) |
| Markdown | MarkdownUI (`swift-markdown-ui`) — approved SPM exception |

## Phathom code reuse (Q10 — locked)

**Selective copy** — adapt for chat efficiency; greenfield app shell.

### Copy from Phathom

- `LlamaCppBridge` protocol, `LlamaCppRuntime` (**text-only** — strip mtmd/vision)
- `GenerationOptions`, `LlamaInferenceError`
- Build pipeline: `intrai-llama/scripts/setup-llama-xcframework.sh` → `vendor/llama/llama.xcframework`

### Adapt (do not copy verbatim)

- `ModelManager` → single GGUF bookmark (no tagging/vision roles)
- `SharedLlamaInference` → slim chat session actor (`withSession`, `unloadOnExit: false` while chatting); drop summarize/tags/extracts pipeline
- Default `n_ctx` **4096** for chat (Phathom uses 8192 for article prefill)
- No `generateWithSharedPrefix` in v1

### Greenfield

- SwiftUI views (list, chat, settings)
- `ChatService`, `ChatViewModel`, history trimmer, title gen, markdown export

### Not doing

- Shared SPM package across repos
- Reference-only rewrite of inference bridge
- Fork Phathom app shell

## Build / binary

- Text-only xcframework (no `mtmd` unless vision added later)
- Upstream llama.cpp, CMake Xcode builds, `GGML_METAL=ON`
- Import llama C module directly — no `llama.swift` / SPM wrappers
- Weights **not** in repo

## Inference lifecycle (hard rules)

- **One context, one inference at a time** — serialize with actor + lock
- Warm model during active chat session (`unloadOnExit: false` while chatting)
- Chat template from **GGUF metadata** — not hand-rolled
- Token-count budgets before send — not character limits
- `n_batch >=` max prompt length (SIGABRT if too small)
- Reject encoder-decoder GGUFs explicitly
- Real perf validation on device only (simulator Metal unreliable)

### Simulator limitations (Slice 9)

| Capability | Simulator | Device |
|------------|-----------|--------|
| UI / SwiftData / export / copy | Yes | Yes |
| Light + dark appearance | Yes | Yes |
| Metal inference | CPU only; not perf-representative | Full path |
| MVP smoke inference stories | Partial | Required for acceptance |

See [docs/mvp-smoke-checklist.md](mvp-smoke-checklist.md).

### Layer stack

```
ChatViewModel
  → ChatService (history trim, ContextAugmentation hook)
    → SharedLlamaInference.withSession(unloadOnExit: false)
      → LlamaCppBridge.startRawPrompt(fullHistory)
        → loop nextTokenChunk() → UI stream
```

### Streaming (SwiftUI)

- `ChatGenerationService.stream(userPrompt:) -> AsyncThrowingStream<String, Error>`
- Coalesce UI updates (~16ms) for sub-word token fragments
- Cancel in-flight before new send; Send morphs to Stop in UI
- Partial assistant message persisted on stop
- `ScrollViewReader` scroll-to-bottom on draft text change

### Post-MVP chat UX polish

| Item | Phase | Status |
|------|-------|--------|
| **UI state before inference (A1)** | Slice 10 | **Shipped** — spec below |
| **Responsiveness during generation (A3)** | Post–Slice 10 | Deferred |
| **Immediate stop interrupt (A2)** | Post–Slice 10 | Deferred |
| **Proactive trim / summarization** | v1.1+ | Deferred — device UAT (2026-06-07): trim notice rare; latency grows on long threads |

#### Slice 10 A1 — UI settle before inference (shipped)

**UX sequence on Send:** (1) keyboard dismisses, (2) compose clears, (3) Send → Stop, (4) compose row anchors bottom, (5) empty assistant bubble + "Generating…", (6) scroll to bottom — **then** inference.

**Architecture:** Two-phase send. `prepareSend` (ViewModel: in-memory messages, `isGenerating`, no persist) → View settle (resign focus, scroll, 200ms post-scroll + 300ms cap) → `startPreparedInference` (persist + stream). Cancel-then-send uses the same path after `stopAndWaitForCompletion`.

**Rollback (settle window):** Stop or navigate back before infer → remove user + assistant placeholders, restore sent text to compose, revert `updatedAt`; Stop also re-focuses compose. `stopGeneration()` is active-inference only; settling cancel is view-driven via `cancelPreparedSend`.

**Persist:** No `saveContext` until `startPreparedInference`. Skip `migrateLegacyOrderIndicesIfNeeded` save while `isSettling` (render path would otherwise bypass defer).

**Orchestration:** `ChatThreadBody` owns focus, `settleTask`, `activeSettleSendID`, and `onDisappear`. Plan: `~/.cursor/plans/slice_10_a1_settle_b79a4cd1.plan.md`.

**Acceptance:** [post-mvp-smoke-checklist.md](post-mvp-smoke-checklist.md). MVP checklist stays frozen.

## Multi-turn context (locked)

**Rebuild full history each turn** via `llama_chat_apply_template` + `startRawPrompt`. No warm KV append in v1.

### History trimming — `HistoryTrimmer` protocol

| Implementation | Phase | Behavior |
|----------------|-------|----------|
| `SlidingWindowTrimmer` | **v1** | Token-count formatted history; drop oldest user/assistant pairs until within budget; subtle in-chat note (not persisted) |
| `SummarizingTrimmer` | **v1.1+** | LLM-summarize dropped turns into compact context block |

Trim at `n_ctx=4096` likely around turn 15–20+ for concise 1-sentence use — rare in normal sessions.

## Persistence (Q11 — locked)

SwiftData greenfield schema — do not copy Phathom `ChatThread`/`ChatMessage` (RAG-tagged, different shape).

```swift
@Model Conversation {
  id: UUID
  title: String
  titleLocked: Bool
  createdAt: Date
  updatedAt: Date
  messages: [Message]  // cascade delete
}

@Model Message {
  id: UUID
  role: String         // "user" | "assistant"
  content: String      // raw markdown
  createdAt: Date
}
```

Settings (model bookmark, system prompt, `n_ctx`, creativity) in **UserDefaults**. Creativity is stored as sampler temperature.

List: `@Query(sort: \Conversation.updatedAt, order: .reverse)`.

## Settings defaults (Q12 — locked)

| Setting | Default | Notes |
|---------|---------|-------|
| System prompt | Global, editable in Settings | Strong default on first run; empty save → silently restore default |
| `n_ctx` | 4096 | User: 2048 / 4096 / 8192; capped at `llama_model_n_ctx_train`; reload on change |
| Creativity | 0.7 | User: 0.1–1.5, step 0.1; UI label **Creativity**; persisted as sampler temperature; applies on next send (no context reload) |

Default system prompt intent: helpful, complete, concise responses. Proposed copy:

> *"You are a helpful assistant. Give complete but concise responses. Prefer short paragraphs and avoid unnecessary preamble."*

Per-conversation system prompt: **v1.1+** (not in v1 schema).

## Model policy (Q17 — locked)

- One global active GGUF; no per-conversation model ID
- Change model in Settings → reload on save; all threads use new model on next send
- No confirmation dialog (solo personal app)
- Forget model → clear bookmark; messages persist; send blocked until re-import

## Title generation (Q14, Q18 — locked)

- **Once** after first complete exchange; input = first user message only (~500 char cap)
- Async on inference actor (serialized with chat); non-blocking UI
- Skip if `titleLocked`; on failure keep current title
- **No** regenerate

**Implementation (Slice 8):** `TitleGenerationService` — dedicated system prompt (3–6 word title), `GenerationOptions(maxTokens: 24, temperature: 0.3)`, output sanitized (first line, max 6 words). Triggered from `ChatViewModel` when `messages.count == 2`, title is `Conversation.defaultTitle` (`"New conversation"`), and `!titleLocked`; assistant content non-empty. Runs via `SharedLlamaInference.withSession` after chat generation completes (including stop-with-partial). No retry on later turns (message count > 2).

**Rename:** `ConversationTitleEditing.applyManualRename` sets `titleLocked` on save. Surfaces: chat nav title (inline `TextField`), chat `⋯` + list leading swipe (`ConversationRenameSheet`).

## Markdown (Q13 — locked)

- **Storage:** raw markdown in `Message.content` (source of truth)
- **Render:** MarkdownUI, live during stream (coalesced re-parse)
- **Export:** conversation `⋯` → `.md` file → share sheet (format in product brief)
- **Copy:** per-message menu → pasteboard as plain markdown text
- Code blocks: SF Mono + subtle background per design-handoff
- Syntax highlighting by language tag: **not** v1

**Implementation (Slice 7):** `ChatMessageMarkdown` — 16ms coalesced re-parse during stream; `ChatMarkdownTheme` (heading1–6, code blocks `#2A2826`). `ExportFormatter` + `ConversationShareSheet`; list export reuses `ConversationExport`.

## Extensibility: web search (v2+)

```swift
protocol ContextAugmentation {
  func augment(messages: [Message], trigger: AugmentationTrigger) async throws -> [Message]
}
```

- v1: `NoOpContextAugmentation`
- v2: user-initiated per message; permission gate; privacy-focused providers
- Later: tool-calling path

## Pitfalls checklist (Phathom-validated)

1. `n_batch` too small → SIGABRT
2. Parallel `llama_decode` on same context → corruption/crash
3. Wrong chat template → garbage output
4. Large models on 8GB → Jetsam
5. Assuming char limits bound tokens

## Distribution

Personal / sideload / dev install. Follow iOS sandbox rules for file access.

## Changelog

| Date | Change |
|------|--------|
| 2026-06-06 | Checkpoint 1 — initial brief from grill-me Q1–Q8 |
| 2026-06-06 | Q9 — rebuild history + SlidingWindowTrimmer |
| 2026-06-06 | Checkpoint 2 — Q10–Q20: Phathom copy scope, SwiftData, settings, MarkdownUI, title gen, model policy |
| 2026-06-07 | Post-MVP chat UX polish — UI state before inference (settle sequence locked), responsiveness during generation |
| 2026-06-07 | Device UAT note — trim notice rare in practice; proactive trim/summarization deferred |
| 2026-06-08 | Slice 6 — `SettingsStore`, creativity slider, `n_ctx` reload on save |
| 2026-06-08 | Slice 7 — MarkdownUI bubbles, export/copy |
| 2026-06-08 | Slice 8 — `TitleGenerationService`, rename UX, list swipes, `activeConversationID` active row |
| 2026-06-08 | Slice 9 — light mode (removed forced dark), smoke checklist, README, MVP docs checkpoint |
| 2026-06-08 | MVP signed off — smoke checklist passed (device + simulator) |
| 2026-06-08 | Slice 10 A1 — grill-me locked; implementation plan reviewed (`slice_10_a1_settle_b79a4cd1.plan.md`) |
| 2026-06-08 | Slice 10 — two-phase send (`prepareSend` → settle → `startPreparedInference`), deferred persist, settle rollback |
| 2026-06-08 | Slice 10 — long-thread scroll fix (`scrollToBottomAfterLayout` + `streamingMessageID` focus) |
| 2026-06-08 | Slice 10 signed off — post-mvp-smoke-checklist passed (device + simulator) |