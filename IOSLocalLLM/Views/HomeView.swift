import SwiftUI

// MARK: - HomeView
// The landing surface. One job: answer "what can I do right now?" in a single
// screen — start a conversation, check the device, reach a tool, resume work.
//
// Layout is intentionally editorial: a wordmark header, one hero composer,
// a device health strip, a 2×2 tool grid, the active model, then recents.
// Every string routes through LocalizationService so the screen flips to
// Arabic (RTL) without a relaunch.

struct HomeView: View {
    @Environment(\.koduTheme) private var T
    @ObservedObject private var assistant = CodingAssistantService.shared
    @ObservedObject private var center = ModelDownloadCenter.shared
    @ObservedObject private var convos = ConversationStore.shared
    @ObservedObject private var loc = LocalizationService.shared
    @State private var showMemoryHelp = false

    /// Start a fresh chat (→ Assistant tab).
    var onNewChat: () -> Void
    /// Switch to the Lens (camera) tab.
    var onOpenLens: () -> Void
    /// Switch to the Voice tab.
    var onOpenVoice: () -> Void
    /// Open the Models tab.
    var onOpenModels: () -> Void
    /// Present the Mac / Bridge screen.
    var onOpenMac: () -> Void
    /// Present the on-device image generation studio.
    var onGenerateImage: () -> Void
    /// Present Settings.
    var onOpenSettings: () -> Void
    /// Open the Assistant tab focused on a past conversation (best-effort).
    var onOpenConversation: (StoredConversation) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                askCard
                deviceStrip
                toolsGrid
                activeModelCard
                recentSection
                footer
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 26)
        }
        .background(LiquidPinkBackdrop())
        .scrollIndicators(.hidden)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(T.sans(12, .medium))
                    .foregroundStyle(T.ink3)
                HStack(spacing: 8) {
                    Text("سند")
                        .font(T.display(30, .semibold))
                        .foregroundStyle(T.ink)
                    Text("SANAD")
                        .font(T.mono(9, .medium))
                        .tracking(2.4)
                        .foregroundStyle(T.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(T.accentSoft, in: Capsule())
                        .offset(y: 2)
                }
            }
            Spacer(minLength: 0)
            Button(action: { HapticManager.impact(.light); onOpenSettings() }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(T.ink)
                    .frame(width: 42, height: 42)
                    .background(T.surface2, in: Circle())
                    .overlay(Circle().strokeBorder(T.rule, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc.t("settings"))
        }
        .padding(.top, 4)
    }

    // MARK: Hero — ask Sanad

    private var askCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Circle()
                    .fill(stateDot)
                    .frame(width: 6, height: 6)
                Text(loc.t(stateLabel))
                    .font(T.sans(11, .semibold))
                    .foregroundStyle(T.ink3)
                Spacer(minLength: 0)
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(T.ink4)
            }

            Text(loc.t("How can I help?"))
                .font(T.display(27, .semibold))
                .foregroundStyle(T.ink)
                .padding(.top, 14)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(T.sans(14))
                .foregroundStyle(T.ink2)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { HapticManager.impact(.medium); onNewChat() }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                    Text(loc.t("New chat"))
                        .font(T.sans(15, .semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.18), in: Circle())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [T.roseHi, T.accentStrong],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 18)

            HStack(spacing: 8) {
                Button(action: { HapticManager.impact(.light); onOpenVoice() }) {
                    Label(loc.t("voice"), systemImage: "waveform")
                        .font(T.sans(12.5, .medium))
                        .foregroundStyle(T.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(T.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(T.rule, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)

                Button(action: { HapticManager.impact(.light); onOpenLens() }) {
                    Label(loc.t("lens"), systemImage: "camera.viewfinder")
                        .font(T.sans(12.5, .medium))
                        .foregroundStyle(T.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(T.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(T.rule, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
        }
        .padding(20)
        .background(card(24))
    }

    private var stateDot: Color {
        switch assistant.state {
        case .ready, .generating: return T.good
        case .loading:            return T.warn
        case .failed(let e):
            return e.localizedCaseInsensitiveContains("cancel") ? T.ink3 : T.bad
        case .unloaded:           return downloadInProgress ? T.warn : T.ink3
        }
    }

    private var stateLabel: String {
        switch assistant.state {
        case .ready:      return "Assistant is ready"
        case .generating: return "Assistant is thinking…"
        case .loading:    return "Preparing model…"
        case .failed(let e):
            return e.localizedCaseInsensitiveContains("cancel") ? "On-device" : "Model needs setup"
        case .unloaded:   return downloadInProgress ? "Preparing model…" : "On-device"
        }
    }

    private var subtitle: String {
        if case .loading(let m) = assistant.state, !m.isEmpty { return m }
        if case .failed(let e) = assistant.state, !e.isEmpty,
           !e.localizedCaseInsensitiveContains("cancel") { return e }
        return "\(assistant.activeModel.displayName) · \(loc.t("replies stay on your iPhone"))"
    }

    private var downloadInProgress: Bool {
        center.models.contains { model in
            switch model.state {
            case .downloading, .enumerating: return true
            default: return false
            }
        }
    }

    // MARK: Device strip

    private var entitlementGranted: Bool {
        MemoryAdvisor.hasIncreasedMemoryLimitEntitlement
    }

    private var deviceStrip: some View {
        Button {
            HapticManager.impact(.light)
            showMemoryHelp = true
        } label: {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                statTile(
                    symbol: entitlementGranted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    value: entitlementGranted ? loc.t("Granted") : loc.t("Not granted"),
                    label: loc.t("Memory entitlement"),
                    tint: entitlementGranted ? T.good : T.warn
                )
                divider
                statTile(
                    symbol: "memorychip",
                    value: Self.byteString(MemoryAdvisor.processMemoryCeiling),
                    label: loc.t("App memory limit"),
                    tint: T.ink2
                )
                divider
                statTile(
                    symbol: "internaldrive",
                    value: Self.byteString(center.totalStorageUsed),
                    label: "\(center.models.filter(\.isReady).count) \(loc.t("models"))",
                    tint: T.ink2
                )
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)

            if !entitlementGranted {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(T.warn)
                    Text(loc.t("Models above ~2 GB may not load. Re-sign with a profile that grants the increased-memory entitlement."))
                        .font(T.sans(11.5))
                        .foregroundStyle(T.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 13)
            }
        }
        .background(card(20))
        }
        .buttonStyle(.plain)
        .accessibilityHint(loc.t("Explains the memory entitlement and how to grant it."))
        .sheet(isPresented: $showMemoryHelp) { SanadMemoryHelpSheet() }
    }

    private var divider: some View {
        Rectangle()
            .fill(T.rule)
            .frame(width: 0.5, height: 30)
    }

    private func statTile(symbol: String, value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(T.sans(15, .semibold))
                .foregroundStyle(T.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(T.sans(10.5))
                .foregroundStyle(T.ink3)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Tools

    private var toolsGrid: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel(loc.t("Tools"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                      spacing: 10) {
                toolTile(loc.t("Lens"), loc.t("Read the world"), "camera.viewfinder", T.accent, onOpenLens)
                toolTile(loc.t("Voice"), loc.t("Hands-free chat"), "waveform", T.voiceTint, onOpenVoice)
                toolTile(loc.t("Mac bridge"), loc.t("Pair a Mac"), "desktopcomputer", T.imageTint, onOpenMac)
                toolTile(loc.t("Images"), loc.t("Generate offline"), "wand.and.stars", T.accent2, onGenerateImage)
            }
        }
    }

    private func toolTile(_ title: String,
                          _ subtitle: String,
                          _ symbol: String,
                          _ tint: Color,
                          _ action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.impact(.light)
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(T.isDark ? 0.18 : 0.12),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(T.sans(14, .semibold))
                        .foregroundStyle(T.ink)
                    Text(subtitle)
                        .font(T.sans(11.5))
                        .foregroundStyle(T.ink3)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(card(18))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Active model

    private var activeModelCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(T.accentSoft)
                Image(systemName: "cube.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(T.accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(assistant.activeModel.displayName)
                    .font(T.sans(14, .semibold))
                    .foregroundStyle(T.ink)
                    .lineLimit(1)
                Text(loc.t("Active model"))
                    .font(T.sans(11.5))
                    .foregroundStyle(T.ink3)
            }
            Spacer(minLength: 6)
            Button(action: { HapticManager.impact(.light); onOpenModels() }) {
                Text(loc.t("Manage"))
                    .font(T.sans(12.5, .semibold))
                    .foregroundStyle(T.ink)
                    .padding(.horizontal, 13)
                    .frame(height: 32)
                    .background(T.surface2, in: Capsule())
                    .overlay(Capsule().strokeBorder(T.rule, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(card(20))
    }

    // MARK: Recent

    private var recentSection: some View {
        let recent = Array(convos.conversations
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(3))
        return VStack(alignment: .leading, spacing: 9) {
            sectionLabel(loc.t("Recent"))

            if recent.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(T.ink3)
                        .frame(width: 34, height: 34)
                        .background(T.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(loc.t("No recent activity yet"))
                        .font(T.sans(13.5))
                        .foregroundStyle(T.ink3)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(card(18))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, convo in
                        Button {
                            HapticManager.impact(.light)
                            onOpenConversation(convo)
                        } label: {
                            recentRow(convo, isLast: index == recent.count - 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(card(20))
            }
        }
    }

    private func recentRow(_ convo: StoredConversation, isLast: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(T.accent)
                .frame(width: 32, height: 32)
                .background(T.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(convo.title.isEmpty ? loc.t("Untitled chat") : convo.title)
                    .font(T.sans(14, .medium))
                    .foregroundStyle(T.ink)
                    .lineLimit(1)
                Text(Self.relative(convo.updatedAt))
                    .font(T.sans(11.5))
                    .foregroundStyle(T.ink3)
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.forward")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(T.ink4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(T.rule).frame(height: 0.5).padding(.leading, 58)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.shield")
                .font(.system(size: 11, weight: .medium))
            Text(loc.t("Private by design. Nothing leaves this iPhone."))
                .font(T.sans(11))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(T.ink3)
        .padding(.top, 4)
    }

    // MARK: Bits

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(T.sans(11, .semibold))
            .tracking(1.2)
            .foregroundStyle(T.ink3)
            .padding(.leading, 2)
    }

    private func card(_ radius: CGFloat) -> some View {
        Color.clear
            .kGlass(
                cornerRadius: radius,
                fallbackFill: T.surface,
                fallbackStroke: T.rule
            )
    }

    private static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private static func byteString(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = bytes >= 1_000_000_000 ? [.useGB] : [.useMB]
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: bytes)
    }
}
