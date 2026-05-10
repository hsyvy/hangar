import Foundation

struct Server: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var directory: String
    var command: String
    var port: Int?
    var urlPath: String
    var environment: [String: String]

    init(
        id: UUID = UUID(),
        name: String = "",
        directory: String = "",
        command: String = "",
        port: Int? = nil,
        urlPath: String = "/",
        environment: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.directory = directory
        self.command = command
        self.port = port
        self.urlPath = urlPath
        self.environment = environment
    }

    var url: URL? {
        guard let port else { return nil }
        let path = urlPath.hasPrefix("/") ? urlPath : "/\(urlPath)"
        return URL(string: "http://localhost:\(port)\(path)")
    }

    var expandedDirectory: String {
        (directory as NSString).expandingTildeInPath
    }
}
