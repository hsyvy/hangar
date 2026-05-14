import SwiftUI
import AppKit

struct RegisterServerSheet: View {
    enum Mode {
        case create
        case edit(Server)
    }

    let mode: Mode
    let onSave: (Server) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var directory: String = ""
    @State private var command: String = ""
    @State private var portText: String = ""
    @State private var urlPath: String = "/"
    @State private var envRows: [EnvRow] = []
    @State private var existingID: UUID?

    private struct EnvRow: Identifiable {
        let id = UUID()
        var key: String = ""
        var value: String = ""
    }

    private var title: String {
        switch mode {
        case .create: return "Register Server"
        case .edit: return "Edit Server"
        }
    }

    private var subtitle: String {
        switch mode {
        case .create: return "Add a new local server. You can edit any of these later."
        case .edit:   return "Update the details for this server."
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !directory.trimmingCharacters(in: .whitespaces).isEmpty &&
        !command.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    field("Name") {
                        TextField("My API", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    field("Working directory") {
                        HStack(spacing: 8) {
                            TextField("~/code/my-service", text: $directory)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                pickDirectory()
                            } label: {
                                Label("Choose…", systemImage: "folder")
                            }
                            .buttonStyle(.glassNeutral)
                        }
                    }

                    field("Command") {
                        TextField("bun run dev", text: $command)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    HStack(alignment: .top, spacing: 14) {
                        field("Port") {
                            TextField("3000", text: $portText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                        }
                        field("URL path") {
                            TextField("/", text: $urlPath)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 160)
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("Environment Variables")
                                .font(.system(size: 12, weight: .semibold))
                            Button {
                                envRows.append(EnvRow())
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(HangarTheme.Status.running)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }

                        if envRows.isEmpty {
                            Text("None")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach($envRows) { $row in
                                HStack(spacing: 8) {
                                    TextField("KEY", text: $row.key)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: 180)
                                    TextField("value", text: $row.value)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                    Button {
                                        envRows.removeAll { $0.id == row.id }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(HangarTheme.Status.crashed)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }

            Divider().opacity(0.5)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.glassNeutral)
                    .keyboardShortcut(.cancelAction)
                Button {
                    save()
                } label: {
                    Text("Save")
                        .frame(minWidth: 64)
                }
                .buttonStyle(.primaryFilled)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(width: 580, height: 560)
        .background(AmbientBackground())
        .onAppear { loadFromMode() }
    }

    @ViewBuilder
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
            content()
        }
    }

    private func loadFromMode() {
        if case .edit(let server) = mode {
            existingID = server.id
            name = server.name
            directory = server.directory
            command = server.command
            portText = server.port.map { String($0) } ?? ""
            urlPath = server.urlPath
            envRows = server.environment.map { EnvRow(key: $0.key, value: $0.value) }
        }
    }

    private func pickDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            directory = url.path
        }
    }

    private func save() {
        var env: [String: String] = [:]
        for row in envRows {
            let k = row.key.trimmingCharacters(in: .whitespaces)
            guard !k.isEmpty else { continue }
            env[k] = row.value
        }
        let server = Server(
            id: existingID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            directory: directory.trimmingCharacters(in: .whitespaces),
            command: command.trimmingCharacters(in: .whitespacesAndNewlines),
            port: Int(portText.trimmingCharacters(in: .whitespaces)),
            urlPath: urlPath.trimmingCharacters(in: .whitespaces).isEmpty ? "/" : urlPath,
            environment: env
        )
        onSave(server)
        dismiss()
    }
}

extension RegisterServerSheet.Mode: Identifiable {
    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let s): return "edit-\(s.id.uuidString)"
        }
    }
}
