import SwiftUI

// MARK: - SanadTabBar
// Floating bottom navigation. Replaces the system tab bar chrome (the tabs
// themselves still live in a TabView, so selection, state restoration and
// deep links keep working) with a single glass capsule: five destinations,
// one accent, 44pt targets, and a hairline that separates it from content.

struct SanadTabItem<Tag: Hashable>: Identifiable {
    let tag: Tag
    let title: String
    let symbol: String
    var id: Tag { tag }
}

struct SanadTabBar<Tag: Hashable>: View {
    let items: [SanadTabItem<Tag>]
    @Binding var selection: Tag

    @Environment(\.koduTheme) private var T
    @ObservedObject private var loc = LocalizationService.shared

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                let active = item.tag == selection
                Button {
                    guard !active else { return }
                    HapticManager.tabSwitch()
                    withAnimation(.snappy(duration: 0.24, extraBounce: 0.04)) {
                        selection = item.tag
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: active ? .semibold : .regular))
                            .frame(height: 21)
                        Text(loc.t(item.title))
                            .font(.system(size: 10, weight: active ? .semibold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(active ? T.accent : T.ink3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        if active {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(T.accentSoft)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .strokeBorder(T.accent.opacity(0.18), lineWidth: 0.5)
                                }
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(loc.t(item.title))
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background {
            ZStack {
                // Opaque by design: a navigation surface must never let the
                // list underneath read through it. The sheen supplies the
                // glass character without sacrificing legibility.
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(T.bg)
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(T.isDark ? 0.06 : 0.55),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .strokeBorder(T.rule, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(T.isDark ? 0.45 : 0.12), radius: 22, y: 10)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}
