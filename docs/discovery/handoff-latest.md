# Session handoff — Intrai-2

**Updated:** 2026-06-07 (Slice 2 conversation CRUD)

Cold-start agents: read [CONTEXT.md](../../CONTEXT.md), this file, [docs/design-handoff.md](../design-handoff.md), then the approved plan.

**Canonical design:** HTML mocks in `docs/archive/design-mocks/` are canonical. Swift components live in `Intrai2/Design/`.

```
<handoff>
GOAL: Slice 3 — ChatViewModel, streaming generation, message persist, compose bar
ENV: intrai-2 | main uncommitted S2 work | Intrai2.xcodeproj iOS 26.4+ | 23 Swift files
STATE: S0 scaffold | S1 inference+model | S2 list CRUD + ChatThreadView shell | design components reused
PHASE: implementation
DECISIONS:
  - HTML mocks canonical for design; handoff.md wins conflicts
  - nav glyphs: flat bronze, no Liquid Glass (sharedBackgroundVisibility hidden)
  - Unicode symbols: TextPresentationGlyph U+FE0E for tintable glyphs not emoji
  - List rows: Button + NavigationPath (no disclosure chevron); rename/export swipes deferred Slice 8
  - ModelStore: isInferenceReady separate from banner; warm load via warmLoadIfNeeded()
DONE:
  - Slice 0–1 (see git c5c1dc8 + post-review ModelStore fixes)
  - Slice 2: + creates Conversation + pushes ChatThreadView; row tap opens chat; trailing Delete (Theme.swipeDelete)
  - ChatThreadView: flat back, centered title, empty thread shell for Slice 3
TODO:
  - Slice 3: ChatViewModel, ChatGenerationService stream, compose bar, message persist, bump updatedAt
  - Slice 3 design: thread layout, compose bar, flat ⋯ nav (defer ⋯ menu items where noted)
NEXT: implement Slice 3 per plan
BLOCKED: none
</handoff>
```

## Code map (23 Swift files)

| Area | Files |
|------|-------|
| **App** | `Intrai2App.swift`, `RootView.swift` |
| **Design** | `Theme.swift`, `InstrumentPanel.swift`, `InstrumentNavChrome.swift`, `TextPresentationGlyph.swift`, `ConversationTimestampFormatter.swift` |
| **Data** | `Conversation.swift`, `Message.swift` |
| **Features** | `ConversationListView`, `NoModelBannerView`, `ChatThreadView`, `SettingsView`, `ModelStatusRow` |
| **Inference** | `LlamaCppBridge`, `LlamaCppRuntime`, `GenerationOptions`, `LlamaInferenceError` |
| **Services** | `ModelManager`, `ModelStore`, `SharedLlamaInference`, `AsyncLock`, `Notifications+Intrai` |

## Slice 3 scope

Per plan + [design-handoff.md](../design-handoff.md):

- `ChatViewModel` + streaming via `SharedLlamaInference`
- User message append → assistant placeholder → stream → finalize
- Multiline compose (~5 lines); Send disabled when `!modelStore.isModelReady`
- Bump `Conversation.updatedAt` on message activity
- Chat nav: flat back (done), centered title (done), flat **⋯** (Slice 3 design checklist)

## Manual smoke (Slice 2)

- Tap **+** → new conversation pushes empty chat with title "New conversation"
- Back (chevron or edge swipe) → list
- Row tap → opens same chat
- Trailing swipe **Delete** → row removed
- Relaunch → conversations persist; sort by `updatedAt` desc
