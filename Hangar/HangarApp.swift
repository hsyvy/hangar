import SwiftUI
import AppKit

@MainActor
final class AppServices {
    static let shared = AppServices()
    let store = ServerStore()
    let manager = ProcessManager()
    private init() {}
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        AppServices.shared.manager.killAll()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct HangarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup("Hangar", id: "main") {
            MainWindow()
                .environment(AppServices.shared.store)
                .environment(AppServices.shared.manager)
                .frame(minWidth: 880, minHeight: 540)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra("Hangar", systemImage: "server.rack") {
            MenuBarContent()
                .environment(AppServices.shared.store)
                .environment(AppServices.shared.manager)
        }
        .menuBarExtraStyle(.window)
    }
}
