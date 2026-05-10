import Foundation
import Observation
import Darwin

enum ServerStatus: Equatable {
    case stopped
    case starting
    case running
    case stopping
    case crashed(Int32)

    var label: String {
        switch self {
        case .stopped: return "Stopped"
        case .starting: return "Starting…"
        case .running: return "Running"
        case .stopping: return "Stopping…"
        case .crashed(let code): return "Crashed (\(code))"
        }
    }

    var isActive: Bool {
        switch self {
        case .starting, .running, .stopping: return true
        case .stopped, .crashed: return false
        }
    }
}

private let urlDetectionRegex = try! NSRegularExpression(
    pattern: #"https?://(?:localhost|127\.0\.0\.1|0\.0\.0\.0):(\d+)(?:/[^\s\)\]\},;'"]*)?"#,
    options: []
)

@Observable
final class ServerRunner {
    private(set) var server: Server
    let logs: LogBuffer
    private(set) var status: ServerStatus = .stopped
    private(set) var pid: Int32?
    private(set) var detectedURLs: [URL] = []

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var detectedURLStrings: Set<String> = []

    init(server: Server) {
        self.server = server
        self.logs = LogBuffer()
    }

    func updateServer(_ server: Server) {
        self.server = server
    }

    func start() {
        guard process == nil else { return }
        let cmd = server.command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else {
            logs.appendSystem("Cannot start: command is empty")
            return
        }
        let dir = server.expandedDirectory
        guard FileManager.default.fileExists(atPath: dir) else {
            logs.appendSystem("Cannot start: directory does not exist: \(dir)")
            return
        }

        detectedURLs.removeAll()
        detectedURLStrings.removeAll()

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-lc", cmd]
        proc.currentDirectoryURL = URL(fileURLWithPath: dir)

        var env = ProcessInfo.processInfo.environment
        for (k, v) in server.environment { env[k] = v }
        proc.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        self.stdoutPipe = outPipe
        self.stderrPipe = errPipe

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.logs.append(text, stream: .stdout)
                self?.scanForURLs(in: text)
            }
        }
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.logs.append(text, stream: .stderr)
                self?.scanForURLs(in: text)
            }
        }

        proc.terminationHandler = { [weak self] p in
            DispatchQueue.main.async {
                guard let self else { return }
                let code = p.terminationStatus
                if code == 0 || self.status == .stopping {
                    self.status = .stopped
                    self.logs.appendSystem("Process exited with code \(code)")
                } else {
                    self.status = .crashed(code)
                    self.logs.appendSystem("Process crashed with code \(code)")
                }
                self.pid = nil
                self.process = nil
                self.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                self.stderrPipe?.fileHandleForReading.readabilityHandler = nil
                self.stdoutPipe = nil
                self.stderrPipe = nil
            }
        }

        do {
            status = .starting
            try proc.run()
            self.process = proc
            self.pid = proc.processIdentifier
            self.status = .running
            logs.appendSystem("Started (pid \(proc.processIdentifier)): \(cmd)")
        } catch {
            status = .stopped
            logs.appendSystem("Failed to start: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard let proc = process, proc.isRunning else { return }
        status = .stopping
        let rootPid = proc.processIdentifier
        logs.appendSystem("Stopping process tree (root pid \(rootPid))…")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.killTree(pid: rootPid, signal: SIGTERM)
        }

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            if let p = self.process, p.isRunning {
                DispatchQueue.main.async {
                    self.logs.appendSystem("Force killing tree (SIGKILL)")
                }
                self.killTree(pid: rootPid, signal: SIGKILL)
            }
        }
    }

    func killImmediately() {
        guard let proc = process, proc.isRunning else { return }
        killTree(pid: proc.processIdentifier, signal: SIGKILL)
    }

    private func killTree(pid: Int32, signal: Int32) {
        for child in directChildren(of: pid) {
            killTree(pid: child, signal: signal)
        }
        kill(pid, signal)
    }

    private func directChildren(of pid: Int32) -> [Int32] {
        let pgrep = Process()
        pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        pgrep.arguments = ["-P", "\(pid)"]
        let outPipe = Pipe()
        pgrep.standardOutput = outPipe
        pgrep.standardError = Pipe()
        do {
            try pgrep.run()
            pgrep.waitUntilExit()
        } catch {
            return []
        }
        let data = (try? outPipe.fileHandleForReading.readToEnd()) ?? Data()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
    }

    private func scanForURLs(in text: String) {
        let range = NSRange(text.startIndex..., in: text)
        urlDetectionRegex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match, let r = Range(match.range, in: text) else { return }
            var raw = String(text[r])
            raw = raw.replacingOccurrences(of: "://0.0.0.0:", with: "://localhost:")
            raw = raw.replacingOccurrences(of: "://127.0.0.1:", with: "://localhost:")
            if !detectedURLStrings.contains(raw), let url = URL(string: raw) {
                detectedURLStrings.insert(raw)
                detectedURLs.append(url)
            }
        }
    }
}
