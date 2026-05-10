import SwiftUI

struct ServerListView: View {
    @Environment(ServerStore.self) private var store
    @Environment(ProcessManager.self) private var manager
    @Binding var selection: Server.ID?
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(store.servers) { server in
                    ServerRow(server: server)
                        .tag(server.id)
                }
            }
            .listStyle(.sidebar)

            Divider()

            Button(action: onAdd) {
                Label("Add Server", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 0.5)
            )
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
}

private struct ServerRow: View {
    @Environment(ProcessManager.self) private var manager
    let server: Server

    var body: some View {
        let runner = manager.runner(for: server)
        HStack(spacing: 8) {
            StatusDot(status: runner.status)
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name.isEmpty ? "(unnamed)" : server.name)
                    .font(.body)
                    .lineLimit(1)
                Text(runner.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

struct StatusDot: View {
    let status: ServerStatus

    var color: Color {
        switch status {
        case .stopped: return .gray
        case .starting, .stopping: return .yellow
        case .running: return .green
        case .crashed: return .red
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .overlay(
                Circle().stroke(color.opacity(0.4), lineWidth: 2)
                    .scaleEffect(1.4)
                    .opacity(status == .running ? 0.6 : 0)
            )
    }
}
