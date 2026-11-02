import SwiftUI

// MARK: - SanadMemoryHelpSheet
// Explains, in the user's language, why a sideloaded build can install and run
// while still refusing to load a 4B model. The short version: the entitlement
// has to be in the *signature*, not in the source tree.

struct SanadMemoryHelpSheet: View {
    @Environment(\.koduTheme) private var T
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = LocalizationService.shared

    private var granted: Bool { MemoryAdvisor.hasIncreasedMemoryLimitEntitlement }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                statusCard

                Text(loc.t("iOS gives every app a memory budget. Models are loaded into that budget, and a model that needs more is stopped before it can crash the app. The Increased Memory Limit entitlement raises the budget, but it only exists once the app is signed with a profile that grants it."))
                    .font(T.sans(14))
                    .foregroundStyle(T.ink2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    step(1,
                         loc.t("Use a paid Apple Developer account"),
                         loc.t("Free personal teams cannot issue the Increased Memory Limit capability."))
                    step(2,
                         loc.t("Re-sign both bundles"),
                         loc.t("Import SanadAI.entitlements for com.sanadai.app and SanadAIShare.entitlements for the share extension in ESign or Sideloadly."))
                    step(3,
                         loc.t("Check it inside the app"),
                         loc.t("This sheet reads the entitlement from the running process, so it turns green the moment the signature is right."))
                }

                Text(loc.t("Until then, pick a model that fits the current budget. The Models tab shows a fit badge for every model."))
                    .font(T.sans(12.5))
                    .foregroundStyle(T.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
        }
        .background(LiquidPinkBackdrop())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.t("Memory entitlement"))
                    .font(T.sans(12, .semibold))
                    .foregroundStyle(T.ink3)
                Text(granted ? loc.t("Granted") : loc.t("Not granted"))
                    .font(T.display(26, .semibold))
                    .foregroundStyle(granted ? T.good : T.warn)
            }
            Spacer(minLength: 8)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(T.ink2)
                    .frame(width: 34, height: 34)
                    .background(T.surface2, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc.t("Close"))
        }
    }

    private var statusCard: some View {
        VStack(spacing: 0) {
            row(loc.t("Device memory"), Self.gb(MemoryAdvisor.deviceTotalRAM))
            divider
            row(loc.t("App memory limit"), Self.gb(MemoryAdvisor.processMemoryCeiling))
            divider
            row(loc.t("Increased Memory Limit"), granted ? loc.t("Granted") : loc.t("Not granted"),
                tint: granted ? T.good : T.warn)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(T.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(T.rule, lineWidth: 0.5)
                )
        )
    }

    private var divider: some View {
        Rectangle().fill(T.rule).frame(height: 0.5).padding(.leading, 14)
    }

    private func row(_ label: String, _ value: String, tint: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(T.sans(13.5))
                .foregroundStyle(T.ink2)
            Spacer(minLength: 8)
            Text(value)
                .font(T.sans(13.5, .semibold))
                .foregroundStyle(tint ?? T.ink)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
    }

    private func step(_ number: Int, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(T.sans(12, .bold))
                .foregroundStyle(T.accent)
                .frame(width: 26, height: 26)
                .background(T.accentSoft, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(T.sans(14, .semibold))
                    .foregroundStyle(T.ink)
                Text(body)
                    .font(T.sans(12.5))
                    .foregroundStyle(T.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private static func gb(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "—" }
        return String(format: "%.1f GB", Double(bytes) / 1_000_000_000)
    }
}
