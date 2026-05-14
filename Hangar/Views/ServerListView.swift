import SwiftUI

struct ServerListView: View {
    @Environment(ServerStore.self) private var store
    @Environment(ProcessManager.self) private var manager
    @Binding var selection: Server.ID?
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Servers")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(store.servers) { server in
                        ServerRow(
                            server: server,
                            isSelected: selection == server.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selection = server.id
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            Spacer(minLength: 0)

            Button {
                onAdd()
            } label: {
                Label("Add Server", systemImage: "plus")
                    .font(.system(size: 12.5, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassNeutral)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

private struct ServerRow: View {
    @Environment(ProcessManager.self) private var manager
    let server: Server
    let isSelected: Bool

    var body: some View {
        let runner = manager.runner(for: server)
        HStack(spacing: 10) {
            StatusDot(status: runner.status)
            Text(server.name.isEmpty ? "(unnamed)" : server.name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
            Spacer(minLength: 0)
            if let port = server.port {
                Text(":\(port)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(runner.status.tint.opacity(0.18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(runner.status.tint.opacity(0.35), lineWidth: 0.6)
                    }
            }
        }
    }
}
