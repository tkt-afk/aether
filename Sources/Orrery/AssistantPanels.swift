import SwiftUI

/// Personal notes stay on this device; no calendar or conversation API is assumed.
struct AssistantLeftPanels: View {
    @EnvironmentObject private var windowState: HUDWindowState
    @AppStorage("aetherSessionHistory") private var history = ""

    private var entries: [String] {
        history.split(separator: "\n").map(String.init)
    }

    var body: some View {
        VStack(spacing: 14) {
            HUDPanel(title: "CONVERSATIONS", trailing: "LOCAL") {
                Label("Session archive", systemImage: "bubble.left.and.bubble.right")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(HUD.silver)
                Text("Local session log. Conversation transcripts are not connected.")
                    .font(.system(size: 11))
                    .foregroundStyle(HUD.silver.opacity(0.65))
                if entries.isEmpty {
                    Label("No sessions recorded", systemImage: "waveform.path")
                        .font(HUD.mono(11))
                        .foregroundStyle(HUD.cyan.opacity(0.7))
                        .padding(.vertical, 14)
                } else {
                    ForEach(Array(entries.prefix(5).enumerated()), id: \.offset) { _, entry in
                        Label(entry, systemImage: "waveform")
                            .font(HUD.mono(10))
                            .foregroundStyle(HUD.silver)
                    }
                }
            }
            AssistantNotePanel(title: "TASKS", subtitle: "Focus queue",
                               storageKey: "aetherTasks", allowsCompletion: true)
            Spacer(minLength: 0)
        }
        .onChange(of: windowState.sessionActive) { _, active in
            guard active else { return }
            let stamp = Date().formatted(date: .abbreviated, time: .shortened)
            history = ([stamp + " · CODEX"] + entries).prefix(20).joined(separator: "\n")
        }
    }
}

struct AssistantRightPanels: View {
    @ObservedObject var system: SystemMonitor
    @EnvironmentObject private var windowState: HUDWindowState
    @EnvironmentObject private var audio: AudioSpectrum

    var body: some View {
        VStack(spacing: 14) {
            AssistantNotePanel(title: "SCHEDULE", subtitle: "Mission timeline",
                               storageKey: "aetherSchedule", allowsCompletion: false)
            HUDPanel(title: "AI STATUS", trailing: "CODEX") {
                HStack(spacing: 8) {
                    Circle().fill(windowState.sessionActive ? HUD.up : HUD.cyan).frame(width: 6, height: 6)
                    Text(windowState.starting ? "INITIALIZING" : (windowState.sessionActive ? "SESSION ACTIVE" : "STANDBY"))
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(HUD.silver)
                }
                statusRow("SESSION", windowState.sessionActive ? "ACTIVE" : "IDLE")
                statusRow("AUDIO", audio.isLive ? "SPEAKING" : "QUIET")
                statusRow("SOURCE", audio.sourceLabel)
                HStack {
                    ArcGauge(value: system.cpu, label: "CPU", tint: HUD.cyan, size: 66)
                    Spacer()
                    ArcGauge(value: system.memoryTotal > 0 ? system.memoryUsed / system.memoryTotal : 0,
                             label: "MEM", tint: HUD.violet, size: 66)
                }
                Sparkline(points: system.cpuHistory, tint: HUD.cyan)
                    .frame(height: 32)
                Label("SYSTEM TELEMETRY / LIVE", systemImage: "cpu")
                    .font(HUD.mono(8))
                    .foregroundStyle(HUD.cyan.opacity(0.7))
                Text("HUD session and audio input status.")
                    .font(.system(size: 10))
                    .foregroundStyle(HUD.silver.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(HUD.silver.opacity(0.55))
            Spacer()
            Text(value).foregroundStyle(HUD.cyan).lineLimit(1)
        }
        .font(HUD.mono(10))
    }
}

private struct AssistantNote: Codable, Identifiable {
    var id = UUID()
    var text: String
    var done = false
}

private struct AssistantNotePanel: View {
    let title: String
    let subtitle: String
    let storageKey: String
    let allowsCompletion: Bool
    @AppStorage private var saved: String
    @State private var draft = ""

    init(title: String, subtitle: String, storageKey: String, allowsCompletion: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.storageKey = storageKey
        self.allowsCompletion = allowsCompletion
        _saved = AppStorage(wrappedValue: "[]", storageKey)
    }

    private var notes: [AssistantNote] {
        (try? JSONDecoder().decode([AssistantNote].self, from: Data(saved.utf8))) ?? []
    }

    var body: some View {
        HUDPanel(title: title, trailing: "LOCAL") {
            Label(subtitle, systemImage: allowsCompletion ? "checklist" : "calendar.badge.clock")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(HUD.silver)
            if notes.isEmpty {
                Text(allowsCompletion ? "Clear your queue. One task at a time." : "Add a time and a mission. Local notes only.")
                    .font(.system(size: 11))
                    .foregroundStyle(HUD.silver.opacity(0.65))
            }
            if allowsCompletion {
                HStack {
                    Text("COMPLETED")
                    Spacer()
                    Text("\(notes.filter { $0.done }.count) / \(notes.count)")
                }
                .font(HUD.mono(9))
                .foregroundStyle(HUD.cyan)
                ProgressView(value: Double(notes.filter { $0.done }.count), total: Double(max(1, notes.count)))
                    .tint(HUD.violet)
            }
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(notes) { note in
                        HStack(alignment: .top, spacing: 8) {
                            if allowsCompletion {
                                Button {
                                    save(notes.map { item in
                                        var updated = item
                                        if item.id == note.id { updated.done.toggle() }
                                        return updated
                                    })
                                } label: {
                                    Image(systemName: note.done ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(HUD.cyan)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(note.done ? "Mark incomplete" : "Complete task")
                            }
                            Text(note.text)
                                .strikethrough(note.done)
                                .foregroundStyle(HUD.silver.opacity(note.done ? 0.4 : 1))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                save(notes.filter { $0.id != note.id })
                            } label: {
                                Image(systemName: "xmark").foregroundStyle(HUD.silver.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete")
                        }
                        .font(.system(size: 12))
                    }
                }
            }
            .frame(maxHeight: 150)
            HStack {
                TextField(allowsCompletion ? "Add a task" : "14:00 Mission briefing", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .onSubmit(add)
                Button(action: add) { Image(systemName: "plus") }
                    .buttonStyle(.plain)
                    .foregroundStyle(HUD.cyan)
                    .accessibilityLabel("Add")
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(10)
            .background(HUD.cyan.opacity(0.05))
            Text("STORED ON THIS DEVICE")
                .font(HUD.mono(9))
                .foregroundStyle(HUD.silver.opacity(0.45))
        }
    }

    private func add() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        save(notes + [AssistantNote(text: String(text.prefix(300)))])
        draft = ""
    }

    private func save(_ values: [AssistantNote]) {
        guard let data = try? JSONEncoder().encode(values), let text = String(data: data, encoding: .utf8) else { return }
        saved = text
    }
}
