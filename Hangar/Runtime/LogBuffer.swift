import Foundation
import Observation

enum LogStream: String, Codable {
    case stdout
    case stderr
    case system
}

struct LogLine: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let stream: LogStream
    let text: String
}

@Observable
final class LogBuffer {
    private let capacity: Int
    private(set) var lines: [LogLine] = []

    init(capacity: Int = 5_000) {
        self.capacity = capacity
    }

    func append(_ chunk: String, stream: LogStream) {
        let now = Date()
        let pieces = chunk.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" })
        var newLines: [LogLine] = []
        for piece in pieces where !piece.isEmpty {
            newLines.append(LogLine(timestamp: now, stream: stream, text: String(piece)))
        }
        guard !newLines.isEmpty else { return }
        lines.append(contentsOf: newLines)
        if lines.count > capacity {
            lines.removeFirst(lines.count - capacity)
        }
    }

    func appendSystem(_ text: String) {
        append(text + "\n", stream: .system)
    }

    func clear() {
        lines.removeAll()
    }
}
