import Combine
import Sparkle
import SwiftUI

/// Publishes whether Sparkle's updater can currently start a check, so the
/// "Check for Updates…" control disables itself while a check is in flight.
final class UpdaterViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

/// A "Check for Updates…" button wired to Sparkle. Renders as a menu item
/// under the app menu and as a plain button in Settings — callers apply
/// their own button style.
struct CheckForUpdatesView: View {
    @StateObject private var model: UpdaterViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        _model = StateObject(wrappedValue: UpdaterViewModel(updater: updater))
    }

    var body: some View {
        Button("Check for Updates…") {
            updater.checkForUpdates()
        }
        .disabled(!model.canCheckForUpdates)
    }
}
