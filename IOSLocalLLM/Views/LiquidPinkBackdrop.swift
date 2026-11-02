import SwiftUI

// MARK: - LiquidPinkBackdrop
// Historical type name kept so every screen keeps one background entry point.
// The artwork is now "Sanad Aura": a warm stone canvas with three slow colour
// fields (mint, teal, sand) that give the clear-glass chrome real pixels to
// refract. It is static by design — a decorative animation that never stops is
// a battery tax on a screen the user leaves open.

struct LiquidPinkBackdrop: View {
    @Environment(\.koduTheme) private var T
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                T.bg

                if !reduceTransparency {
                    // Mint field — anchors the top trailing corner.
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    T.accent.opacity(T.isDark ? 0.22 : 0.16),
                                    T.accent.opacity(0.0),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.9
                            )
                        )
                        .frame(width: w * 1.6, height: w * 1.6)
                        .offset(x: w * 0.46, y: -h * 0.30)

                    // Cool teal field — balances the mint on the lower leading side.
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.55, blue: 0.62)
                                        .opacity(T.isDark ? 0.20 : 0.12),
                                    .clear,
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.8
                            )
                        )
                        .frame(width: w * 1.4, height: w * 1.4)
                        .offset(x: -w * 0.55, y: h * 0.20)

                    // Warm sand field — the single non-green hue, kept faint.
                    Ellipse()
                        .fill(
                            Color(red: 0.86, green: 0.70, blue: 0.46)
                                .opacity(T.isDark ? 0.10 : 0.14)
                        )
                        .frame(width: w * 1.2, height: h * 0.42)
                        .blur(radius: 70)
                        .offset(x: w * 0.18, y: h * 0.40)

                    // Hairline horizon — a quiet architectural cue near the top.
                    LinearGradient(
                        colors: [.clear, T.rule, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    .offset(y: -h * 0.42)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Card / pill primitives

struct LiquidGlassCard<Content: View>: View {
    @Environment(\.koduTheme) private var T
    let radius: CGFloat
    let intensity: Intensity
    let content: Content

    enum Intensity { case lo, med, hi }

    init(radius: CGFloat = 22, intensity: Intensity = .med, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.intensity = intensity
        self.content = content()
    }

    var body: some View {
        let fill: Color = {
            switch intensity {
            case .hi:  return T.surface2
            case .med: return T.surface
            case .lo:  return T.surface3
            }
        }()
        content
            .kGlass(
                cornerRadius: radius,
                fallbackFill: fill,
                fallbackStroke: T.rule
            )
    }
}

struct LiquidGlassPill<Content: View>: View {
    @Environment(\.koduTheme) private var T
    let active: Bool
    let content: Content

    init(active: Bool = false, @ViewBuilder content: () -> Content) {
        self.active = active
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .kClearGlass(
                in: Capsule(),
                tint: active ? T.accentStrong : nil,
                fallbackFill: active ? T.accentStrong : T.surface,
                fallbackStroke: active ? Color.clear : T.rule
            )
            .foregroundColor(active ? T.accentStrong : T.ink)
    }
}

struct LiquidGlassIconButton<Content: View>: View {
    @Environment(\.koduTheme) private var T
    let size: CGFloat
    let action: () -> Void
    let label: Content

    init(size: CGFloat = 36, action: @escaping () -> Void, @ViewBuilder label: () -> Content) {
        self.size = size
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .frame(width: size, height: size)
                .kClearGlass(
                    in: Circle(),
                    interactive: true,
                    fallbackFill: T.surface,
                    fallbackStroke: T.rule
                )
                .foregroundColor(T.ink)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active badge
struct KActivePinkBadge: View {
    @Environment(\.koduTheme) private var T
    let text: String

    init(_ text: String = "ACTIVE") { self.text = text }

    var body: some View {
        HStack(spacing: 3) {
            Text(text)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0)
        }
        .foregroundColor(T.ink)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .kClearGlass(
            in: RoundedRectangle(cornerRadius: 4),
            fallbackFill: T.surface2,
            fallbackStroke: T.rule
        )
    }
}
