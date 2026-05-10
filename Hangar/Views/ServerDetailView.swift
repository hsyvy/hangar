import SwiftUI
import AppKit

struct ServerDetailView: View {
    @Environment(ProcessManager.self) private var manager
    @Environment(ServerStore.self) private var store
    let server: Server
    let onEdit: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        let runner = manager.runner(for: server)

        VStack(alignment: .leading, spacing: 0) {
            HeaderBar(server: server, runner: runner, onEdit: onEdit, onDelete: {
                confirmingDelete = true
            })
            Divider()
            MetadataBar(server: server, runner: runner)
            Divider()
            LogView(buffer: runner.logs)
        }
        .alert("Remove \(server.name.isEmpty ? "this server" : server.name)?",
               isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                manager.discardRunner(for: server.id)
                store.remove(server)
            }
        } message: {
            Text("The running process (if any) will be killed. The server's source files are not touched.")
        }
    }
}

private struct HeaderBar: View {
    let server: Server
    let runner: ServerRunner
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StatusDot(status: runner.status)
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name.isEmpty ? "(unnamed)" : server.name)
                    .font(.title2.weight(.semibold))
                Text(runner.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            if runner.status.isActive {
                Button {
                    runner.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            } else {
                Button {
                    runner.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            let openableURLs: [URL] = runner.detectedURLs.isEmpty
                ? (server.url.map { [$0] } ?? [])
                : runner.detectedURLs
            if !openableURLs.isEmpty, runner.status == .running {
                if openableURLs.count == 1 {
                    Button {
                        NSWorkspace.shared.open(openableURLs[0])
                    } label: {
                        Label("Open", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Menu {
                        ForEach(openableURLs, id: \.self) { url in
                            Button(url.absoluteString) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    } label: {
                        Label("Open", systemImage: "arrow.up.right.square")
                    } primaryAction: {
                        NSWorkspace.shared.open(openableURLs[0])
                    }
                    .menuStyle(.button)
                    .buttonStyle(.bordered)
                    .fixedSize()
                }
            }

            Menu {
                Button("Edit…", action: onEdit)
                Button("Open in Finder") {
                    let url = URL(fileURLWithPath: server.expandedDirectory)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                Divider()
                Button("Remove…", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16))
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct MetadataBar: View {
    let server: Server
    let runner: ServerRunner

    var body: some View {
        let displayURL: URL? = runner.detectedURLs.first ?? server.url
        HStack(spacing: 16) {
            MetaField(label: "Directory", value: server.directory)
            MetaField(label: "Command", value: server.command, mono: true)
            if let port = server.port {
                MetaField(label: "Port", value: "\(port)")
            }
            if let pid = runner.pid {
                MetaField(label: "PID", value: "\(pid)")
            }
            if let url = displayURL {
                MetaField(
                    label: runner.detectedURLs.isEmpty ? "URL" : "URL (detected)",
                    value: url.absoluteString
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct MetaField: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(mono ? .system(.caption, design: .monospaced) : .caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(minWidth: 60, alignment: .leading)
    }
}
