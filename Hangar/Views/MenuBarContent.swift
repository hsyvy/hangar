import SwiftUI
import AppKit

struct MenuBarContent: View {
    @Environment(ServerStore.self) private var store
    @Environment(ProcessManager.self) private var manager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Hangar")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            if store.servers.isEmpty {
                Text("No servers registered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(20)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.servers) { server in
                            MenuBarServerRow(server: server)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 320)
            }

            Divider()

            HStack {
                Button("Open Hangar") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
            .padding(10)
        }
        .frame(width: 320)
    }
}

private struct MenuBarServerRow: View {
    @Environment(ProcessManager.self) private var manager
    let server: Server

    var body: some View {
        let runner = manager.runner(for: server)
        HStack(spacing: 8) {
            StatusDot(status: runner.status)
            VStack(alignment: .leading, spacing: 1) {
                Text(server.name.isEmpty ? "(unnamed)" : server.name)
                    .font(.body)
                    .lineLimit(1)
                Text(runner.status.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            let openURL = runner.detectedURLs.first ?? server.url
            if runner.status == .running, let url = openURL {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
            }

            if runner.status.isActive {
                Button {
                    runner.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    runner.start()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
