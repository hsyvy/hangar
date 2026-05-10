import SwiftUI

struct MainWindow: View {
    @Environment(ServerStore.self) private var store
    @State private var selection: Server.ID?
    @State private var showingRegister = false
    @State private var editingServer: Server?

    var body: some View {
        NavigationSplitView {
            ServerListView(selection: $selection, onAdd: { showingRegister = true })
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            if let id = selection, let server = store.servers.first(where: { $0.id == id }) {
                ServerDetailView(
                    server: server,
                    onEdit: { editingServer = server }
                )
            } else {
                EmptyDetail(onAdd: { showingRegister = true })
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
    }
}

private struct EmptyDetail: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No server selected")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Register a Server", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
