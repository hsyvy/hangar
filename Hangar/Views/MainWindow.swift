import SwiftUI

struct MainWindow: View {
    @Environment(ServerStore.self) private var store
    @State private var selection: Server.ID?
    @State private var showingRegister = false
    @State private var editingServer: Server?

    var body: some View {
        NavigationSplitView {
            ServerListView(selection: $selection, onAdd: { showingRegister = true })
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
                .background(AmbientBackground())
        } detail: {
            ZStack {
                AmbientBackground()
                if let id = selection, let server = store.servers.first(where: { $0.id == id }) {
                    ServerDetailView(
                        server: server,
                        onEdit: { editingServer = server }
                    )
                } else {
                    EmptyDetail(onAdd: { showingRegister = true })
                }
            }
        }
        .sheet(isPresented: $showingRegister) {
            RegisterServerSheet(mode: .create) { newServer in
                store.add(newServer)
                selection = newServer.id
            }
        }
        .sheet(item: $editingServer) { server in
            RegisterServerSheet(mode: .edit(server)) { updated in
                store.update(updated)
            }
        }
        .navigationTitle("Hangar")
        .navigationSubtitle("local API Gateway")
    }
}

private struct EmptyDetail: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(HangarTheme.Status.running.opacity(0.12))
                    .frame(width: 116, height: 116)
                    .blur(radius: 6)
                Circle()
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                    .background(Circle().fill(.regularMaterial))
                    .frame(width: 96, height: 96)
                Image(systemName: "server.rack")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(HangarTheme.Status.running.gradient)
            }

            VStack(spacing: 6) {
                Text("No server selected")
                    .font(.system(size: 17, weight: .semibold))
                Text("Choose a server from the sidebar to view its status\nand logs, or register a new local server to get started.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onAdd()
            } label: {
                Label("Register a Server", systemImage: "plus")
            }
            .buttonStyle(.primaryFilled)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
