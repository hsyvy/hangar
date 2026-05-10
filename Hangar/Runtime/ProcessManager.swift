import Foundation
import Observation

@Observable
final class ProcessManager {
    private(set) var runners: [UUID: ServerRunner] = [:]

    func runner(for server: Server) -> ServerRunner {
        if let existing = runners[server.id] {
            existing.updateServer(server)
            return existing
        }
        let r = ServerRunner(server: server)
        runners[server.id] = r
        return r
    }

    func discardRunner(for serverID: UUID) {
        if let r = runners[serverID] {
            r.killImmediately()
        }
        runners.removeValue(forKey: serverID)
    }

    func killAll() {
        for r in runners.values {
            r.killImmediately()
        }
    }
}
