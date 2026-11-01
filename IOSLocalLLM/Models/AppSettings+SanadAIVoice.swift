import Foundation

// MARK: - AppSettings + SanadAI voice compatibility
//
// The server-only OnDeviceLAS product dropped the voice-engine proxies from
// AppSettings. The full SanadAI app still exposes Settings → Voice and the
// voice library, so keep the same computed bridge available there. This file
// is excluded from the OnDeviceLAS target (which does not compile
// VoiceSettingsStore) and is only part of the SanadAI application target.

extension AppSettings {
    /// Selected TTS engine, persisted by VoiceSettingsStore.
    @MainActor var voiceEngine: String {
        get { VoiceSettingsStore.shared.selectedEngine.rawValue }
        set {
            VoiceSettingsStore.shared.selectEngine(
                VoiceEngineKind(rawValue: newValue) ?? .appleSystem
            )
        }
    }

    /// Selected voice identifier, persisted by VoiceSettingsStore.
    @MainActor var voiceID: String {
        get { VoiceSettingsStore.shared.selectedVoiceID }
        set { VoiceSettingsStore.shared.selectVoice(newValue) }
    }
}
