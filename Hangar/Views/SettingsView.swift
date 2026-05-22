import SwiftUI

enum AppearanceSetting: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage("appearance") private var appearance: AppearanceSetting = .system
    @AppStorage("backgroundTint") private var tint: BackgroundTint = .pearl

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SectionHeader(
                        title: "Appearance",
                        subtitle: "Choose how Hangar looks. “System” follows your macOS appearance."
                    )

                    HStack(spacing: 12) {
                        ForEach(AppearanceSetting.allCases) { option in
                            AppearanceCard(
                                option: option,
                                tint: tint,
                                isSelected: appearance == option
                            )
                            .onTapGesture { appearance = option }
                        }
                    }

                    Divider().opacity(0.35)

                    SectionHeader(
                        title: "Background tint",
                        subtitle: "Pick a pastel background. Applies in both light and dark mode."
                    )

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                        spacing: 10
                    ) {
                        ForEach(BackgroundTint.allCases) { option in
                            TintSwatch(option: option, isSelected: tint == option)
                                .onTapGesture { tint = option }
                        }
                    }

                    Divider().opacity(0.35)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.system(size: 13, weight: .semibold))
                        HStack {
                            Text("Hangar")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(versionString)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        CheckForUpdatesView(updater: AppServices.shared.updaterController.updater)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .padding(.top, 2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(24)
            }
        }
        .frame(width: 560, height: 560)
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "v\(version) (\(build))"
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

private struct AppearanceCard: View {
    let option: AppearanceSetting
    let tint: BackgroundTint
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            Preview(option: option, tint: tint)
                .frame(height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                }

            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(option.label)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .foregroundStyle(isSelected ? HangarTheme.Status.running : .primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: HangarTheme.controlRadius + 4, style: .continuous)
                .fill(.regularMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: HangarTheme.controlRadius + 4, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? HangarTheme.Status.running.opacity(0.7)
                        : .primary.opacity(0.06),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        }
        .contentShape(Rectangle())
    }

    private struct Preview: View {
        let option: AppearanceSetting
        let tint: BackgroundTint

        var body: some View {
            switch option {
            case .system:
                HStack(spacing: 0) {
                    swatch(tint.lightColor)
                    swatch(tint.darkColor)
                }
            case .light:
                swatch(tint.lightColor)
            case .dark:
                swatch(tint.darkColor)
            }
        }

        private func swatch(_ color: Color) -> some View {
            ZStack(alignment: .topLeading) {
                color
                miniChip(over: color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private func miniChip(over base: Color) -> some View {
            HStack(spacing: 4) {
                Circle()
                    .fill(HangarTheme.Status.running)
                    .frame(width: 4, height: 4)
                Capsule()
                    .fill(.primary.opacity(0.18))
                    .frame(width: 22, height: 3)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background {
                Capsule().fill(.regularMaterial)
            }
            .padding(8)
        }
    }
}

private struct TintSwatch: View {
    let option: BackgroundTint
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                option.lightColor
                option.darkColor
            }
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(.primary.opacity(0.10), lineWidth: 0.5)
            }

            Text(option.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? HangarTheme.Status.running : .primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.regularMaterial.opacity(isSelected ? 1 : 0.5))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? HangarTheme.Status.running.opacity(0.7)
                        : .primary.opacity(0.06),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        }
        .contentShape(Rectangle())
    }
}
