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

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !directory.trimmingCharacters(in: .whitespaces).isEmpty &&
        !command.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    field("Name") {
                        TextField("My API", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    field("Directory") {
                        HStack {
                            TextField("/path/to/server", text: $directory)
                                .textFieldStyle(.roundedBorder)
                            Button("Choose…") { pickDirectory() }
                        }
                    }

                    field("Command") {
                        TextField("bun run dev", text: $command)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    HStack(spacing: 12) {
                        field("Port (optional)") {
                            TextField("3000", text: $portText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        field("URL Path") {
                            TextField("/", text: $urlPath)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 140)
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Environment Variables")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Button {
                                envRows.append(EnvRow())
                            } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.borderless)
                        }

                        if envRows.isEmpty {
                            Text("None")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach($envRows) { $row in
                                HStack {
                                    TextField("KEY", text: $row.key)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                    TextField("value", text: $row.value)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                    Button {
                                        envRows.removeAll { $0.id == row.id }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
            }
            .padding(16)
        }
        .frame(width: 560, height: 540)
        .onAppear { loadFromMode() }
    }

    @ViewBuilder
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.weight(.medium))
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
