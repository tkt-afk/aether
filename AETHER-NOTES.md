# AETHER customization

The existing SwiftUI dashboard has been customized in place. The central title and window title now read AETHER. The default ARC palette retains its persisted `arc` identifier and is labeled AETHER in Settings. It now uses light cyan, violet and silver. The original dial geometry, animation timing, spectrum input and CPU/MEM gauges are retained. Panels use a subtle metallic gradient; the title uses a silver-to-cyan gradient.

No changes were made to audio capture, Codex launching, wake-word recognition, network/weather/market/usage services, existing settings persistence, bundle identifiers, executable names or permissions. Existing wake phrases remain supported. Other theme choices remain available.

## Personal workspace revision

### English instrument-style revision

The assistant panels and main voice control use English labels. Added outlined conversation, checklist, calendar and processor icons; a task completion gauge based on saved tasks; session/event counters; a decorative daily timeline; and a demo audio waveform in the browser. The native AI status panel includes actual CPU/MEM gauges and CPU history from the existing SystemMonitor. Native compilation remains unverified because Swift/macOS are unavailable here.

- Default surrounding panels: conversation session history, tasks, schedule notes and AI status.
- Native sidebar switch restores all original system/network/usage/weather/market panels with their existing settings.
- Native tasks and schedule notes support adding and deleting; tasks also support completion. Notes persist locally in UserDefaults under new AETHER-specific keys.
- Conversation history means local HUD session-start timestamps, not Codex chat transcripts. No chat or calendar API is connected.
- Native AI status reflects the existing HUD session state and audio source, not a model's internal reasoning or network connectivity.
- Browser preview has locally persisted tasks, schedule notes and simulated session history. Voice controls simulate the appearance; they do not launch Codex.

## Validation on 2026-10-20

- `git diff --check`: passed.
- Reviewed the native diff: presentation changes plus the new AssistantPanels.swift and sidebar switch in HUDView.swift.
- Browser preview loaded in Chrome at 1440 × 960. No JavaScript runtime errors.
- Preview voice simulation starts and stops; source, microphone and wake controls toggle in both directions.
- Personal workspace checks passed: task add, complete, persist across reload, delete; schedule add and persist; safe text rendering; session history persistence; no horizontal overflow at 390px; no runtime errors.
- `swift build -c release`: attempted, failed because Swift is not installed in the Windows environment. The application requires macOS 14+, AppKit, SwiftUI and ScreenCaptureKit. No native executable was produced, and native functionality has not been verified.
- `aether-preview.png` is a real browser screenshot of `preview/index.html`, which is a separate design approximation using sample values. It is not a screenshot of the macOS app, and preview toggles do not control native services.

## Complete native verification on macOS

1. Install Xcode Command Line Tools and use macOS 14 or later.
2. Run `swift build -c release` in this project directory.
3. Run `./ORRERYを起動.command` to assemble and launch the existing Orrery.app bundle (see README for permissions).
4. In Settings select AETHER if another theme was previously saved.
5. Confirm AETHER text, cyan/violet/silver rings, task and schedule persistence, session history, assistant/system sidebar switch, responsive layout, CPU/MEM and network updates, weather/market refresh, theme switching, voice start/end, microphone and wake phrases, and window modes.
6. Capture the actual app with macOS Screenshot (Shift-Command-4, then Space).

The name Orrery is retained for the package and app bundle for compatibility with the existing launch and permission workflow.
