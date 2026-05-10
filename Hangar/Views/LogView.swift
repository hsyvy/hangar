import SwiftUI
import AppKit

struct LogView: View {
    let buffer: LogBuffer
    @State private var autoscroll: Bool = true
    @State private var showStdout: Bool = true
    @State private var showStderr: Bool = true
    @State private var showSystem: Bool = true
    @State private var showingCopied: Bool = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private var visibleLines: [LogLine] {
        buffer.lines.filter { line in
            switch line.stream {
            case .stdout: return showStdout
            case .stderr: return showStderr
            case .system: return showSystem
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Toggle("stdout", isOn: $showStdout)
                Toggle("stderr", isOn: $showStderr)
                Toggle("system", isOn: $showSystem)
                Spacer()
                Toggle("Autoscroll", isOn: $autoscroll)
                Button {
                    copyVisibleLogs()
                } label: {
                    Label(showingCopied ? "Copied" : "Copy",
                          systemImage: showingCopied ? "checkmark" : "doc.on.doc")
                }
                .disabled(visibleLines.isEmpty)
                Button {
                    buffer.clear()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            }
            .toggleStyle(.checkbox)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(visibleLines) { line in
                            LogLineRow(line: line, formatter: Self.timeFormatter)
                                .id(line.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: buffer.lines.count) { _, _ in
                    if autoscroll, let last = visibleLines.last {
                        withAnimation(.linear(duration: 0.05)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private func copyVisibleLogs() {
        let text = visibleLines
            .map { "\(Self.timeFormatter.string(from: $0.timestamp))  \($0.text)" }
            .joined(separator: "\n")
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        showingCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingCopied = false
        }
    }
}

private struct LogLineRow: View {
    let line: LogLine
    let formatter: DateFormatter

    var streamColor: Color {
        switch line.stream {
        case .stdout: return .primary
        case .stderr: return .red
        case .system: return .secondary
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(formatter.string(from: line.timestamp))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
            Text(line.text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(streamColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
