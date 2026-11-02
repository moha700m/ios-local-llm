import SwiftUI

// MARK: - SanadSplashView
// First-launch identity: the Sanad mark draws itself over a deep emerald
// field, the Arabic wordmark settles, and the whole layer hands off to the
// app. Deliberately short (≈2s) — a splash is a handshake, not a showreel.

struct SanadSplashView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false
    @State private var settled = false
    @State private var leaving = false

    var body: some View {
        ZStack {
            SplashField()

            VStack(spacing: 0) {
                SanadMark()
                    .trim(from: 0, to: drawn ? 1 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [SplashInk.mint, SplashInk.mintDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 92, height: 92)
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(SplashInk.sand)
                            .frame(width: 9, height: 9)
                            .offset(x: 4, y: -2)
                            .opacity(settled ? 1 : 0)
                            .scaleEffect(settled ? 1 : 0.4)
                    }
                    .scaleEffect(settled ? 1 : 0.94)

                Text("سند")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(SplashInk.paper)
                    .padding(.top, 26)
                    .opacity(settled ? 1 : 0)
                    .offset(y: settled ? 0 : 8)

                Text("SANAD AI")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(6)
                    .foregroundStyle(SplashInk.mint.opacity(0.9))
                    .padding(.top, 10)
                    .opacity(settled ? 1 : 0)
            }
            .opacity(leaving ? 0 : 1)
            .scaleEffect(leaving ? 1.02 : 1)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear(perform: animateIn)
    }

    private func animateIn() {
        let duration = reduceMotion ? 0.2 : 0.85
        withAnimation(.easeOut(duration: duration)) { drawn = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86).delay(reduceMotion ? 0 : 0.35)) {
            settled = true
        }
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 1.0 : 2.0))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.32)) { leaving = true }
            try? await Task.sleep(for: .seconds(0.32))
            guard !Task.isCancelled else { return }
            await MainActor.run { onFinished() }
        }
    }
}

// MARK: - Mark

/// The Sanad monogram: one continuous stroke that reads as a support arch at
/// small sizes and as an "S" at display sizes. Drawn in a 100 × 100 box.
struct SanadMark: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + w * x / 100, y: rect.minY + h * y / 100)
        }
        var path = Path()
        path.move(to: p(70, 26))
        path.addCurve(to: p(30, 26), control1: p(60, 12), control2: p(38, 12))
        path.addCurve(to: p(50, 50), control1: p(20, 40), control2: p(50, 42))
        path.addCurve(to: p(70, 74), control1: p(50, 58), control2: p(80, 60))
        path.addCurve(to: p(30, 74), control1: p(60, 88), control2: p(38, 88))
        return path
    }
}

// MARK: - Field

private struct SplashField: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                SplashInk.night

                RadialGradient(
                    colors: [SplashInk.mint.opacity(0.22), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: w * 0.85
                )
                .frame(width: w * 1.7, height: w * 1.7)
                .offset(x: w * 0.20, y: -h * 0.26)
                .scaleEffect(drift ? 1.06 : 1)

                RadialGradient(
                    colors: [SplashInk.sand.opacity(0.10), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: w * 0.7
                )
                .frame(width: w * 1.4, height: w * 1.4)
                .offset(x: -w * 0.35, y: h * 0.28)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

private enum SplashInk {
    static let night = Color(red: 0.027, green: 0.059, blue: 0.051)   // #070F0D
    static let mint = Color(red: 0.290, green: 0.914, blue: 0.678)    // #4AE9AD
    static let mintDeep = Color(red: 0.106, green: 0.639, blue: 0.443) // #1BA371
    static let sand = Color(red: 0.937, green: 0.804, blue: 0.545)    // #EFCD8B
    static let paper = Color(red: 0.945, green: 0.961, blue: 0.953)
}
