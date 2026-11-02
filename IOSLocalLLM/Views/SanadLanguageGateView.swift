import SwiftUI

// MARK: - SanadLanguageGateView
// First launch asks one question before anything else: which language should
// the app speak? The answer is persisted, applied immediately to the whole
// process (including legacy screens, via LocalizationBridge), and can be
// changed later in Settings.

struct SanadLanguageGateView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var loc = LocalizationService.shared

    @State private var appeared = false

    var body: some View {
        ZStack {
            gateBackground

            VStack(spacing: 0) {
                SanadMark()
                    .stroke(
                        LinearGradient(
                            colors: [GateInk.mint, GateInk.mintDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 64, height: 64)

                Text("اختر لغتك")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(GateInk.paper)
                    .padding(.top, 22)

                Text("Choose your language")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(GateInk.paper.opacity(0.62))
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    option(.arabic,
                           title: "العربية",
                           subtitle: "واجهة عربية كاملة · من اليمين إلى اليسار",
                           identifier: "language-gate-ar")
                    option(.english,
                           title: "English",
                           subtitle: "Full English interface · left to right",
                           identifier: "language-gate-en")
                }
                .padding(.top, 36)

                Text("يمكنك تغيير اللغة لاحقاً من الإعدادات · You can change this later in Settings")
                    .font(.system(size: 11.5))
                    .foregroundStyle(GateInk.paper.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 26)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appeared = true }
        }
    }

    private func option(_ language: AppLanguage,
                        title: String,
                        subtitle: String,
                        identifier: String) -> some View {
        let selected = loc.resolvedLanguage == language
        return Button {
            HapticManager.impact(.medium)
            settings.uiLanguage = language.rawValue
            loc.setLanguage(language)
            withAnimation(.easeInOut(duration: 0.3)) {
                settings.hasChosenLanguage = true
            }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(GateInk.paper)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(GateInk.paper.opacity(0.58))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selected ? GateInk.mint : GateInk.paper.opacity(0.28))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(GateInk.paper.opacity(selected ? 0.12 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? GateInk.mint.opacity(0.7) : GateInk.paper.opacity(0.12),
                                          lineWidth: selected ? 1 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private var gateBackground: some View {
        ZStack {
            GateInk.night
            RadialGradient(
                colors: [GateInk.mint.opacity(0.20), .clear],
                center: UnitPoint(x: 0.5, y: 0.10),
                startRadius: 0,
                endRadius: 520
            )
            RadialGradient(
                colors: [GateInk.mintDeep.opacity(0.16), .clear],
                center: UnitPoint(x: 0.15, y: 0.95),
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

private enum GateInk {
    static let night = Color(red: 0.027, green: 0.059, blue: 0.051)
    static let mint = Color(red: 0.290, green: 0.914, blue: 0.678)
    static let mintDeep = Color(red: 0.106, green: 0.639, blue: 0.443)
    static let paper = Color(red: 0.945, green: 0.961, blue: 0.953)
}
