# Intrai-2

Private, on-device LLM chat for iPhone. Runs local models via llama.cpp + Metal.

## Prerequisites

- **Xcode 26+** (iOS 26.4 SDK)
- **cmake** (`brew install cmake`)
- **llama.cpp** cloned at `~/Local Documents/repos/llama.cpp`
- **Physical device:** iPhone 16 Pro or newer recommended for Metal inference performance

## One-time setup: llama.xcframework

The xcframework is not committed to git. Build it once from upstream llama.cpp:

```bash
./scripts/setup-llama-xcframework.sh
```

This produces `vendor/llama/llama.xcframework` (iPhone device + arm64 simulator slices). First run typically takes 10–20 minutes.

## Build and run

1. Open `Intrai2.xcodeproj` in Xcode.
2. Select an **iPhone** simulator (arm64) or a connected device.
3. Build and run (**⌘R**).

### Simulator vs device

| Target | Metal | Inference |
|--------|-------|-----------|
| Simulator (arm64) | CPU only (`n_gpu_layers = 0`) | UI + SwiftData; model load in Slice 1+ |
| Device | Metal (`n_gpu_layers = -1`) | Full on-device generation |

Slice 0 ships navigation and persistence shell only — no model import or chat generation yet.

## Project layout

```
Intrai2/              SwiftUI app (folder-sync Xcode group)
  App/                Entry point, root navigation
  Design/             Theme tokens from docs/design-handoff.md
  Data/               SwiftData models
  Features/           Conversations, Chat, Settings
  Inference/          llama.cpp bridge (Slice 1+)
scripts/              xcframework build script
vendor/llama/         gitignored — llama.xcframework output
docs/                 Product, technical, and design briefs
```

## Docs

- [CONTEXT.md](CONTEXT.md) — project status and bootstrap
- [docs/product-brief.md](docs/product-brief.md) — MVP scope
- [docs/technical-brief.md](docs/technical-brief.md) — architecture
- [docs/design-handoff.md](docs/design-handoff.md) — visual language

## License

Personal project — not intended for App Store distribution.
