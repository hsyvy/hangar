import SwiftUI
import AppKit

struct MenuBarContent: View {
    @Environment(ServerStore.self) private var store
    @Environment(ProcessManager.self) private var manager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Hangar")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if !store.servers.isEmpty {
                    Text(summaryLine)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider().opacity(0.4)

            if store.servers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 22))
                        .foregroundStyle(.tertiary)
                    Text("No servers registered")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(store.servers) { server in
                            MenuBarServerRow(server: server)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 360)
            }

            Divider().opacity(0.4)

            HStack(spacing: 14) {
                Button {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    HStack(spacing: 4) {
                        Text("Open Hangar")
                        Text("⌘O")
                            .foregroundStyle(.tertiary)
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("o", modifiers: .command)

                Button {
                    if #available(macOS 14.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    HStack(spacing: 4) {
                        Text("Settings…")
                        Text("⌘,")
                            .foregroundStyle(.tertiary)
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)

                Spacer()

                Button {
                    NSApp.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Text("Quit")
                        Text("⌘Q")
                            .foregroundStyle(.tertiary)
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 340)
    }

    private var summaryLine: String {
        var running = 0
        var starting = 0
        var crashed = 0
        var stopped = 0
        for s in store.servers {
            switch manager.runner(for: s).status {
            case .running:                  running += 1
            case .starting, .stopping:      starting += 1
            case .crashed:                  crashed += 1
            case .stopped:                  stopped += 1
            }
        }
        var parts: [String] = []
        if running  > 0 { parts.append("\(running) running") }
        if starting > 0 { parts.append("\(starting) starting") }
        if crashed  > 0 { parts.append("\(crashed) crashed") }
        if stopped  > 0 { parts.append("\(stopped) stopped") }
        return parts.joined(separator: " · ")
    }
}

private struct MenuBarServerRow: View {
    @Environment(ProcessManager.self) private var manager
    let server: Server
    @State private var isHovered = false

    var body: some View {
        let runner = manager.runner(for: server)
        HStack(spacing: 10) {
            StatusDot(status: runner.status)

            VStack(alignment: .leading, spacing: 1) {
                Text(server.name.isEmpty ? "(unnamed)" : server.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(detailLine(runner: runner))
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            HStack(spacing: 4) {
                let openURL = runner.detectedURLs.first ?? server.url
                if runner.status == .running, let url = openURL {
                    iconButton(systemName: "arrow.up.right.square", tint: .secondary) {
                        NSWorkspace.shared.open(url)
                    }
                }

                if runner.status.isActive {
                    iconButton(systemName: "stop.fill", tint: HangarTheme.Status.crashed) {
                        runner.stop()
                    }
                } else {
                    iconButton(systemName: "play.fill", tint: HangarTheme.Status.running) {
                        runner.start()
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.primary.opacity(0.06))
            }
        }
        .onHover { isHovered = $0 }
    }

    private func detailLine(runner: ServerRunner) -> String {
        if let port = server.port {
            return "\(runner.status.label) · :\(port)"
        }
        return runner.status.label
    }

    @ViewBuilder
    private func iconButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint.opacity(0.14))
                }
        }
        .buttonStyle(.plain)
    }
}
