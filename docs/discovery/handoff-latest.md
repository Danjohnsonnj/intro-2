# Session handoff — Intrai-2

**Updated:** 2026-06-07 (session end — Slice 3 complete, simulator build verified)

Cold-start agents: read [CONTEXT.md](../../CONTEXT.md), this file, [docs/design-handoff.md](../design-handoff.md), then the approved plan.

**Canonical design:** HTML mocks in `docs/archive/design-mocks/` are canonical. Swift components live in `Intrai2/Design/`.

```
<handoff>
GOAL: Slice 4 — Stop morph, partial persist, cancel-then-send
ENV: intrai-2 | main (uncommitted S3) | Intrai2.xcodeproj iOS 26.4+ | 27 Swift files
STATE: S0–S3 done | chat streams + persists | plain-text bubbles (MarkdownUI = S7)
PHASE: implementation
DECISIONS:
  - HTML mocks canonical; design-handoff.md wins conflicts
  - Nav: flat bronze glyphs, no Liquid Glass; instrumentHidesSystemBackButton re-enables edge-swipe pop
  - Chat: SharedLlamaInference.withSession(unloadOnExit: false); 16ms stream coalesce
  - ChatPromptBuilder: multi-turn llama_chat_apply_template + default system prompt (Settings prompt = S6)
  - Send disabled when !modelStore.isModelReady or isGenerating (Stop morph = S4)
DONE:
  - Slices 0–2: prior commits (03ff246)
  - Slice 3: ChatViewModel, ChatGenerationService, ChatPromptBuilder, ChatThreadView thread+compose
  - formatChatPrompt on LlamaCppBridge; updatedAt bump on append/stream finalize
  - Flat ⋯ toolbar (menu actions deferred S7/8)
  - Simulator build: pass (iPhone 17 Pro, 26.4.1)
TODO:
  - Slice 4: Send→Stop morph, abort decode, partial persist, cancel-then-send
  - Device smoke: first message stream + relaunch restore
NEXT: implement Slice 4 per plan + chat mock generating frame
BLOCKED: none
</handoff>
```

## Git

| Commit | Contents |
|--------|----------|
| `819222d` | Slice 0 scaffold |
| `c5c1dc8` | Slice 1 inference + design alignment |
| `03ff246` | Slice 2 CRUD, ChatThreadView shell, ModelStore warm-load |

Branch `main`, 2 commits ahead of `origin/main`. Slice 3 changes uncommitted.

## Code map (27 Swift files)

| Area | Files |
|------|-------|
| **App** | `Intrai2App.swift`, `RootView.swift` |
| **Design** | `Theme.swift`, `InstrumentPanel.swift`, `InstrumentNavChrome.swift`, `TextPresentationGlyph.swift`, `ConversationTimestampFormatter.swift` |
| **Data** | `Conversation.swift`, `Message.swift` |
| **Features** | `ConversationListView`, `NoModelBannerView`, `ChatThreadView`, `ChatViewModel`, `SettingsView`, `ModelStatusRow` |
| **Inference** | `LlamaCppBridge`, `LlamaCppRuntime`, `ChatPromptBuilder`, `GenerationOptions`, `LlamaInferenceError` |
| **Services** | `ChatGenerationService`, `ModelManager`, `ModelStore`, `SharedLlamaInference`, `AsyncLock`, `Notifications+Intrai` |

## Slice 4 scope

Per plan + `chat-ad-idle-generating.html` generating frame:

- Send button morphs to Stop (solid bronze + square stop icon)
- Stop: `cancelGeneration()`, keep partial assistant content, persist
- New send while generating: cancel in-flight first, then new stream
- Status copy: "Generating…" (already shown in S3)

## Resume prompt (next session)

```
Resume Intrai-2. Read CONTEXT.md, docs/discovery/handoff-latest.md, docs/design-handoff.md, and ~/.cursor/plans/intrai-2_mvp_plan_ce25251c.plan.md.

Implement Slice 4: Stop morph, partial persist, cancel-then-send per plan and chat mock.
```
