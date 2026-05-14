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
                FilterChip(label: "stdout", dotColor: .primary.opacity(0.6), isOn: $showStdout)
                FilterChip(label: "stderr", dotColor: HangarTheme.Status.crashed, isOn: $showStderr)
                FilterChip(label: "system", dotColor: .secondary, isOn: $showSystem)
                Spacer()

                Toggle("Autoscroll", isOn: $autoscroll)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(HangarTheme.Status.running)

                Button {
                    copyVisibleLogs()
                } label: {
                    Label(showingCopied ? "Copied" : "Copy",
                          systemImage: showingCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.glassNeutral)
                .disabled(visibleLines.isEmpty)

                Button {
                    buffer.clear()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.glassNeutral)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
                .opacity(0.3)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(visibleLines) { line in
                            LogLineRow(line: line, formatter: Self.timeFormatter)
                                .id(line.id)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background {
                    LogSurfaceBackground()
                }
                .onChange(of: buffer.lines.count) { _, _ in
                    if autoscroll, let last = visibleLines.last {
                        withAnimation(.linear(duration: 0.05)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: HangarTheme.cornerRadius, style: .continuous)
                    .inset(by: 0)
            )
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

private struct LogSurfaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark
                ? Color(red: 0.05, green: 0.05, blue: 0.07)
                : Color(red: 0.09, green: 0.09, blue: 0.11))
        }
    }
}

private struct LogLineRow: View {
    let line: LogLine
    let formatter: DateFormatter

    private var isStderr: Bool { line.stream == .stderr }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Rectangle()
                .fill(isStderr ? HangarTheme.Status.crashed : Color.clear)
                .frame(width: 2)

            Text(formatter.string(from: line.timestamp))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.35))
                .frame(width: 92, alignment: .leading)

            Text(streamTag)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(streamTagColor)
                .frame(width: 28, alignment: .leading)

            Text(line.text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(messageColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.trailing, 12)
        .background {
            if isStderr {
                HangarTheme.Status.crashed.opacity(0.10)
            }
        }
    }

    private var streamTag: String {
        switch line.stream {
        case .stdout: return "out"
        case .stderr: return "err"
        case .system: return "sys"
        }
    }

    private var streamTagColor: Color {
        switch line.stream {
        case .stdout: return Color.white.opacity(0.30)
        case .stderr: return HangarTheme.Status.crashed.opacity(0.85)
        case .system: return Color.white.opacity(0.30)
        }
    }

    private var messageColor: Color {
        switch line.stream {
        case .stdout: return Color.white.opacity(0.88)
        case .stderr: return HangarTheme.Status.crashed
        case .system: return Color.white.opacity(0.55)
        }
    }
}
