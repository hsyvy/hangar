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

        VStack(alignment: .leading, spacing: 14) {
            HeaderBar(server: server, runner: runner, onEdit: onEdit, onDelete: {
                confirmingDelete = true
            })
            MetadataBar(server: server, runner: runner)
            LogView(buffer: runner.logs)
                .glassPanel()
        }
        .padding(16)
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
        HStack(alignment: .center, spacing: 14) {
            StatusDot(status: runner.status, size: 11)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name.isEmpty ? "(unnamed)" : server.name)
                    .font(.system(size: 22, weight: .semibold))
                Text(runner.status.label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if runner.status.isActive {
                Button {
                    runner.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.glassDestructive)
            } else {
                Button {
                    runner.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.glassPrimary)
            }

            let openableURLs: [URL] = runner.detectedURLs.isEmpty
                ? (server.url.map { [$0] } ?? [])
                : runner.detectedURLs
            if !openableURLs.isEmpty, runner.status == .running {
                if openableURLs.count == 1 {
                    Button {
                        NSWorkspace.shared.open(openableURLs[0])
                    } label: {
                        HStack(spacing: 6) {
                            Text(openableURLs[0].absoluteString)
                                .lineLimit(1)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .buttonStyle(.glassNeutral)
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
                    .buttonStyle(.glassNeutral)
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
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 30, height: 26)
            }
            .menuStyle(.button)
            .buttonStyle(.glassNeutral)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassPanel()
    }
}

private struct MetadataBar: View {
    let server: Server
    let runner: ServerRunner

    var body: some View {
        let displayURL: URL? = runner.detectedURLs.first ?? server.url
        HStack(alignment: .top, spacing: 26) {
            MetaField(label: "Directory", value: server.directory)
            MetaField(label: "Command", value: server.command, mono: true)
            if let port = server.port {
                MetaField(label: "Port", value: "\(port)", mono: true)
            }
            MetaField(label: "PID", value: runner.pid.map { "\($0)" } ?? "—", mono: true)
            if let url = displayURL {
                MetaField(
                    label: runner.detectedURLs.isEmpty ? "URL" : "URL (detected)",
                    value: url.absoluteString,
                    mono: true
                )
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassPanel()
    }
}

private struct MetaField: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FieldLabel(text: label)
            Text(value)
                .font(mono
                      ? .system(size: 12, design: .monospaced)
                      : .system(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(minWidth: 60, alignment: .leading)
    }
}
