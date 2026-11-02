# Sanad design language

Sanad (سند) is an Arabic-first on-device AI workbench. The interface is built
around one idea: **the device is the product**. Trust, privacy and capability
are communicated with restraint — warm paper, deep emerald ink, a single mint
accent, and Apple's clear glass for chrome.

This document is the source of truth for the visual system. Code lives in
`IOSLocalLLM/Models/KoduTheme.swift` (tokens) and `IOSLocalLLM/Views/`
(components).

## Brand

| Item | Value |
| --- | --- |
| Name | Sanad (سند) — "support", "backing" |
| Wordmark | `سند` in SF Arabic semibold, `SANAD` in tracked mono as a secondary lockup |
| Mark | A single continuous "S" stroke that also reads as a support arch |
| App icon | Mint `S` on a deep green-black field (`AppIcon-1024.png`) |
| Voice | Direct, calm, technical. No exclamation marks, no hype. |

The inherited pink/plum "eye" identity and its splash animation were removed in
the Sanad rebrand; nothing in the app should reference them.

## Colour

One brand hue, three neutrals, three semantic colours. Never introduce a fourth
decorative hue — use `voiceTint` / `imageTint` only for model-role coding.

| Token | Light | Dark | OLED |
| --- | --- | --- | --- |
| `bg` | `#F5F7F3` stone | `#0B0F0E` green-black | `#000000` |
| `surface` | white 78% | white 7.5% | white 6.5% |
| `surface2` | white 58% | white 12% | white 11% |
| `ink` | `#0E1412` | `#ECF1EE` | `#EEF2EF` |
| `ink2` | `#47524D` | `#A7B2AC` | `#ABB5AF` |
| `ink3` | `#6C7671` | `#7C8781` | `#828C86` |
| `accent` | `#0E7A5C` | `#45E3A6` | `#4AE9AD` |
| `accentStrong` | `#0B6B51` | `#2BC98C` | `#2BC98C` |
| `good` / `warn` / `bad` | `#12805C` / `#A96A12` / `#B3261E` | mint / `#F2C063` / `#FF8A80` | same as dark |

Rules:

- Colour is state or action, never decoration. A screen with four accent colours
  has no accent.
- Body text is `ink` or `ink2`; `ink3` is metadata only and never paragraph copy.
- Tinted fills are `accent.opacity(0.12)` light / `0.18` dark. Never fill a large
  card with the accent.
- The backdrop (`LiquidPinkBackdrop`) supplies three static colour fields; it is
  decorative and must stay below 0.22 opacity so glass keeps contrast.

## Typography

System fonts only (SF Pro / SF Arabic). No bundled font files.

| Role | Helper | Size / weight |
| --- | --- | --- |
| Screen title | `T.display` | 27–30, semibold |
| Section title | `T.sans` | 14, semibold |
| Body | `T.sans` | 13.5–15, regular |
| Metadata | `T.sans` | 11–12, regular/medium |
| Data / code | `T.mono` | 9–11 |

- No letter-spacing on Arabic. Tracking is reserved for Latin eyebrows and the
  `SANAD` lockup.
- Dynamic Type is capped at `.accessibility2` via `koduScaledType()`.
- Arabic and English share the same hierarchy: do not shrink Arabic to fit.

## Shape and depth

| Element | Radius |
| --- | --- |
| Hero card | 24 |
| Standard card | 18–20 |
| Button / input | 12–16 |
| Tab bar | 26 (capsule) |
| Chip / badge | capsule |

Depth comes from a 0.5pt `rule` border plus translucency — not from stacked
shadows. One soft shadow is allowed on the floating tab bar.

## Motion

| Interaction | Curve | Duration |
| --- | --- | --- |
| Tab change | `.snappy` | 240 ms |
| Sheet / splash handoff | `.easeInOut` | 320 ms |
| Press feedback | `KTactileButtonStyle` | 120 ms |
| Splash | draw + settle | 2.0 s total |

Respect `accessibilityReduceMotion` (splash shortens to 1.0 s and the backdrop
stops drifting) and `accessibilityReduceTransparency` (the backdrop drops its
colour fields).

## Layout

- Horizontal page margin: 18pt.
- Vertical rhythm: 14pt between cards, 9pt between a section label and its card.
- Minimum touch target: 44×44pt.
- Bottom navigation: `SanadTabBar` floats above the safe area; the system tab bar
  is hidden. Content is inset by the bar, never padded manually.
- One primary action per screen. Secondary actions are 40pt bordered buttons.

## Arabic and RTL

- Arabic is the default language (`AppSettings.uiLanguage`); English is one tap
  away in Settings.
- The root applies `.environment(\.layoutDirection, ...)` and `.environment(\.locale, ...)`
  from `LocalizationService`, so a language switch mirrors the whole app without
  a relaunch.
- Use SF Symbols with directional names (`chevron.forward`, `arrow.up`) — they
  mirror automatically. Never hardcode `flipsForRightToLeftLayoutDirection`.
- Numbers inside Arabic copy use Western digits (the app's convention); dates use
  the active locale via `formatted(...)`.
- Keep `.leading` / `.trailing`, never `.left` / `.right`.

## Components

| Component | File | Use |
| --- | --- | --- |
| `SanadTabBar` | `Views/SanadTabBar.swift` | Floating bottom navigation |
| `HomeView` | `Views/HomeView.swift` | Landing dashboard |
| `SanadSplashView` | `Views/SanadSplashView.swift` | First-frame identity |
| `SanadMemoryHelpSheet` | `Views/SanadMemoryHelpSheet.swift` | Memory entitlement explainer |
| `KSection`, `KRow`, `KPrimaryButton` | `Views/KoduComponents.swift` | Settings and forms |
| `kGlass`, `kClearGlass` | `Views/GlassEffects.swift` | Single glass primitive |

## Adding a screen

1. Start from `LiquidPinkBackdrop()` and `ScrollView` with 18pt margins.
2. Use `card(radius)` for surfaces and `sectionLabel(_:)` for section headers.
3. Route every string through `loc.t("English source")` and add the Arabic entry
   to `LocalizationService.arEntries`.
4. Test in Arabic (RTL), English (LTR), light, dark, OLED, and with Larger Text at
   `.accessibility2`.
5. No emoji as icons; no hardcoded colours outside `KoduTheme`.
