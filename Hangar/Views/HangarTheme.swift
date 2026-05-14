import SwiftUI
import AppKit

enum HangarTheme {
    static let cornerRadius: CGFloat = 14
    static let controlRadius: CGFloat = 8
    static let pillRadius: CGFloat = 999

    enum Status {
        static let running   = Color(red: 0.18, green: 0.82, blue: 0.45)
        static let stopped   = Color(red: 0.55, green: 0.56, blue: 0.60)
        static let starting  = Color(red: 1.00, green: 0.78, blue: 0.20)
        static let crashed   = Color(red: 1.00, green: 0.36, blue: 0.36)
    }
}

extension ServerStatus {
    var tint: Color {
        switch self {
        case .stopped:               return HangarTheme.Status.stopped
        case .starting, .stopping:   return HangarTheme.Status.starting
        case .running:               return HangarTheme.Status.running
        case .crashed:               return HangarTheme.Status.crashed
        }
    }
}

enum BackgroundTint: String, CaseIterable, Identifiable {
    case pearl, blush, mint, sky, lilac, sand

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pearl: return "Pearl"
        case .blush: return "Blush"
        case .mint:  return "Mint"
        case .sky:   return "Sky"
        case .lilac: return "Lilac"
        case .sand:  return "Sand"
        }
    }

    var lightColor: Color {
        switch self {
        case .pearl: return Color(red: 0.965, green: 0.957, blue: 0.937)
        case .blush: return Color(red: 0.980, green: 0.930, blue: 0.930)
        case .mint:  return Color(red: 0.920, green: 0.960, blue: 0.935)
        case .sky:   return Color(red: 0.925, green: 0.945, blue: 0.980)
        case .lilac: return Color(red: 0.940, green: 0.930, blue: 0.980)
        case .sand:  return Color(red: 0.960, green: 0.935, blue: 0.885)
        }
    }

    var darkColor: Color {
        switch self {
        case .pearl: return Color(red: 0.090, green: 0.090, blue: 0.100)
        case .blush: return Color(red: 0.105, green: 0.085, blue: 0.090)
        case .mint:  return Color(red: 0.080, green: 0.100, blue: 0.085)
        case .sky:   return Color(red: 0.080, green: 0.090, blue: 0.110)
        case .lilac: return Color(red: 0.090, green: 0.085, blue: 0.110)
        case .sand:  return Color(red: 0.105, green: 0.095, blue: 0.075)
        }
    }

    func color(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkColor : lightColor
    }
}

struct AmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("backgroundTint") private var tint: BackgroundTint = .pearl

    var body: some View {
        tint.color(for: colorScheme)
            .ignoresSafeArea()
    }
}

struct GlassPanel: ViewModifier {
    var radius: CGFloat = HangarTheme.cornerRadius
    var material: Material = .regularMaterial

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(material)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(0.06)
                            : Color.black.opacity(0.05),
                        lineWidth: 0.5
                    )
            }
    }
}

extension View {
    func glassPanel(radius: CGFloat = HangarTheme.cornerRadius,
                    material: Material = .regularMaterial) -> some View {
        modifier(GlassPanel(radius: radius, material: material))
    }
}

struct GlassCapsuleButtonStyle: ButtonStyle {
    enum Variant { case neutral, primary, destructive }

    var variant: Variant = .neutral
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let bg: AnyShapeStyle = {
            switch variant {
            case .neutral:
                return AnyShapeStyle(.regularMaterial)
            case .primary:
                return AnyShapeStyle(HangarTheme.Status.running.opacity(0.18))
            case .destructive:
                return AnyShapeStyle(HangarTheme.Status.crashed.opacity(0.16))
            }
        }()
        let stroke: Color = {
            switch variant {
            case .neutral:      return colorScheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08)
            case .primary:      return HangarTheme.Status.running.opacity(0.45)
            case .destructive:  return HangarTheme.Status.crashed.opacity(0.45)
            }
        }()
        let fg: Color = {
            switch variant {
            case .neutral:      return .primary
            case .primary:      return HangarTheme.Status.running
            case .destructive:  return HangarTheme.Status.crashed
            }
        }()

        configuration.label
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(fg)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule(style: .continuous).fill(bg)
            }
            .overlay {
                Capsule(style: .continuous).strokeBorder(stroke, lineWidth: 0.6)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassCapsuleButtonStyle {
    static var glassNeutral:     GlassCapsuleButtonStyle { .init(variant: .neutral) }
    static var glassPrimary:     GlassCapsuleButtonStyle { .init(variant: .primary) }
    static var glassDestructive: GlassCapsuleButtonStyle { .init(variant: .destructive) }
}

struct PrimaryFilledButtonStyle: ButtonStyle {
    var tint: Color = HangarTheme.Status.running

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous).fill(tint)
            }
            .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 4)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryFilledButtonStyle {
    static var primaryFilled: PrimaryFilledButtonStyle { .init() }
}

struct StatusDot: View {
    let status: ServerStatus
    var size: CGFloat = 9

    var body: some View {
        let color = status.tint
        ZStack {
            Circle()
                .fill(color.opacity(status == .running ? 0.28 : 0))
                .frame(width: size * 2.2, height: size * 2.2)
                .blur(radius: 3)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 0.5)
                }
                .shadow(color: color.opacity(0.6), radius: status == .running ? 4 : 0)
        }
        .frame(width: size, height: size)
    }
}

struct FilterChip: View {
    let label: String
    let dotColor: Color
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor.opacity(isOn ? 1 : 0.3))
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(isOn ? .primary : .secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(.regularMaterial.opacity(isOn ? 1 : 0.4))
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(.primary.opacity(isOn ? 0.08 : 0.04), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
