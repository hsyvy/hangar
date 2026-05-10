import Foundation
import Observation

@Observable
final class ServerStore {
    private(set) var servers: [Server] = []
    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Hangar", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("servers.json")

        let legacyURL = appSupport
            .appendingPathComponent("lsStack", isDirectory: true)
            .appendingPathComponent("servers.json")
        if !fm.fileExists(atPath: fileURL.path),
           fm.fileExists(atPath: legacyURL.path) {
            try? fm.copyItem(at: legacyURL, to: fileURL)
        }

        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([Server].self, from: data) {
            servers = decoded
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(servers) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }

    func add(_ server: Server) {
        servers.append(server)
        save()
    }

    func update(_ server: Server) {
        guard let idx = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[idx] = server
        save()
    }

    func remove(_ server: Server) {
        servers.removeAll { $0.id == server.id }
        save()
    }
}
