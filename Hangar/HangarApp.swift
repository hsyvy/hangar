import SwiftUI
import AppKit
import Sparkle

@MainActor
final class AppServices {
    static let shared = AppServices()
    let store = ServerStore()
    let manager = ProcessManager()
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
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
    @AppStorage("appearance") private var appearance: AppearanceSetting = .system

    var body: some Scene {
        WindowGroup("Hangar", id: "main") {
            MainWindow()
                .environment(AppServices.shared.store)
                .environment(AppServices.shared.manager)
                .frame(minWidth: 880, minHeight: 540)
                .preferredColorScheme(appearance.colorScheme)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: AppServices.shared.updaterController.updater)
            }
        }

        Settings {
            SettingsView()
                .preferredColorScheme(appearance.colorScheme)
        }

        MenuBarExtra("Hangar", systemImage: "server.rack") {
            MenuBarContent()
                .environment(AppServices.shared.store)
                .environment(AppServices.shared.manager)
                .preferredColorScheme(appearance.colorScheme)
        }
        .menuBarExtraStyle(.window)
    }
}
