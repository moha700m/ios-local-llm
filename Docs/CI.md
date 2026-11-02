# SanadAI iOS CI/CD

`.github/workflows/ios-build.yml` builds, tests, and packages the full
**SanadAI** iOS app (app target plus the `SanadAIShare` extension) on a
GitHub-hosted macOS runner. Every run publishes a downloadable IPA together
with the metadata and logs needed to verify or diagnose it without a local Mac.

Nothing in this document requires a Mac: the workflow is the supported build
path for release and sideload artifacts.

## Triggers

| Trigger | When it runs | Defaults |
| --- | --- | --- |
| `push` to `main` | A commit touches one of the paths listed under `on.push.paths` | `version=3.2.6`, `build_number=<workflow run number>`, `signing=auto`, `export_method=ad-hoc`, `run_tests=true` |
| `workflow_dispatch` | Manual run from the Actions tab or `gh workflow run` | Taken from the inputs below |

Pushes are path-filtered so documentation-only commits do not consume macOS
runner minutes. When a new top-level directory starts feeding the `SanadAI`
target, add it to `on.push.paths`; otherwise its changes will not be built.
Changes to `.github/workflows/ios-build.yml` itself are always built.

Concurrency is grouped by ref (`sanadai-ios-build-<ref>`) with
`cancel-in-progress: true`: a newer push cancels the in-flight build for the
same branch instead of queueing behind it.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `version` | `3.2.6` | `CFBundleShortVersionString`. Validated against `[0-9]+(\.[0-9]+){1,2}` and written into every `CFBundleShortVersionString` entry in `project.yml`. |
| `build_number` | workflow run number | `CFBundleVersion`, passed as `CURRENT_PROJECT_VERSION`. |
| `signing` | `auto` | `auto` signs when Apple secrets are present and falls back to unsigned otherwise. `unsigned` always produces a re-signable IPA. `signed` fails fast if a secret is missing. |
| `export_method` | `ad-hoc` | `xcodebuild -exportArchive` method for signed builds: `ad-hoc`, `app-store-connect`, `development`, or `enterprise`. |
| `run_tests` | `true` | Runs the `SanadAITests` unit-test suite on an iOS Simulator. |

Example release build:

```bash
gh workflow run ios-build.yml -R moha700m/ios-local-llm --ref main \
  -f version=3.2.6 -f build_number=7 -f signing=unsigned -f run_tests=true
```

## Runner and toolchain

| Item | Value |
| --- | --- |
| Runner | `macos-26`, Apple silicon |
| Xcode | 26.6 (Build 17F113) |
| iOS SDK | 26.5 |
| Deployment target | iOS 18.0 |
| Project generation | XcodeGen from `project.yml` |
| Dependencies | CocoaPods (`onnxruntime-objc 1.23.0`) + Swift Package Manager |
| Native libraries | llama.cpp and whisper.cpp built as XCFrameworks from `ThirdParty/` |
| Timeout | 180 minutes |

XcodeGen, CocoaPods, and CMake are installed with Homebrew only when the runner
image does not already provide them, so the workflow tracks
`macos-26` image updates instead of pinning stale versions.

## Pipeline stages

1. **Checkout** with `submodules: recursive` and `persist-credentials: false`.
   `ThirdParty/llama.cpp` and `ThirdParty/whisper.cpp` are pinned by commit in
   `.gitmodules` / the index.
2. **Select Xcode** from `/Applications/Xcode_26.6.app` and export
   `DEVELOPER_DIR`.
3. **Restore the native framework cache** (`native-macOS-<hash>-v1`), build
   `scripts/build_native_frameworks.sh` on a miss, then save the cache. The key
   hashes the build scripts, the llama.cpp iOS-only patch, and the upstream
   `build-xcframework.sh` files.
4. **Verify native frameworks** — `llama.xcframework` and `whisper.xcframework`
   must exist before any Xcode work starts.
5. **Restore the SPM cache** (`.spm-cache`, key `spm-v1-macOS`).
6. **Apply version** — rewrites `CFBundleShortVersionString` in `project.yml`
   with a validated marketing version.
7. **`xcodegen generate`** — regenerates `SanadAI.xcodeproj` and
   `SanadAI.xcworkspace`.
8. **`pod install`** into `SanadAI.xcworkspace`.
9. **`xcodebuild -resolvePackageDependencies`**, then save the SPM cache.
10. **Prepare code signing** — decides signed vs unsigned, imports the
    certificate into an ephemeral keychain, installs and validates both
    provisioning profiles against `com.sanadai.app` and
    `com.sanadai.app.share`.
11. **Archive** for `generic/platform=iOS` in `Release`. Unsigned archives pass
    `CODE_SIGNING_ALLOWED=NO`; signed archives use manual signing with the
    profile names read from the `.mobileprovision` files.
12. **Package or export the IPA** — unsigned builds are repacked as
    `Payload/*.app` + `zip`; signed builds go through `xcodebuild
    -exportArchive` with a generated `ExportOptions.plist`.
13. **Validate IPA contents** — asserts `arm64`, `llama.framework`,
    `whisper.framework`, and `SanadAI.app/PlugIns/SanadAIShare.appex`, and
    records bundle ID, version, and signature state.
14. **Run `SanadAITests`** on the `iPhone 17` simulator (skipped when
    `run_tests=false`).
15. **Write metadata** — `build-metadata.json`, `<ipa>.sha256`, then upload
    artifacts.
16. **Diagnose failure** — on failure, appends matching `error:` lines and log
    tails to the job summary.
17. **Clean up** the ephemeral signing keychain and write the job summary.

## Artifacts

| Artifact | Contents | Retention |
| --- | --- | --- |
| `SanadAI-ipa-<run_number>` | `SanadAI-<version>-<build>-unsigned.ipa` or `...-signed.ipa` | 30 days |
| `SanadAI-metadata-<run_number>` | `build-metadata.json`, `ipa-validation.txt`, `ipa-contents.txt`, `<ipa>.sha256`, `SanadAI.entitlements`, `SanadAIShare.entitlements`, `build-xcode-version.txt` | 30 days |
| `SanadAI-logs-<run_number>` | `archive.log`, `export.log`, `resolve-packages.log`, `tests.log`, `native-frameworks.log`, `pod-install.log` | 30 days |

Download from the CLI:

```bash
gh run download <run-id> -R moha700m/ios-local-llm -n SanadAI-ipa-<run_number>
gh run download <run-id> -R moha700m/ios-local-llm -n SanadAI-metadata-<run_number>
```

## Unsigned IPA and ESign

An unsigned run produces an IPA with no `_CodeSignature` and no embedded
provisioning profile. That is the intended input for ESign, Sideloadly, or any
other re-signing tool:

1. Download `SanadAI-ipa-<run_number>` and import the `.ipa` into ESign.
2. Pick a signing certificate whose provisioning profile covers **both**
   `com.sanadai.app` and `com.sanadai.app.share`. The extension is signed as a
   nested plug-in; a profile that only covers the app bundle ID fails at
   install time.
3. Apply the entitlements shipped with the metadata artifact —
   `SanadAI.entitlements` (app) and `SanadAIShare.entitlements` (extension).
   ESign: **Signature → Entitlements → Import**, then enable App Groups.
   Sideloadly: paste both files into the entitlements fields. They declare:
   `com.apple.security.application-groups` = `group.com.sanadai.shared`,
   `com.apple.developer.kernel.increased-memory-limit`, and
   `com.apple.developer.kernel.extended-virtual-addressing`.

Dropping the App Group breaks the share extension's handoff to the app.
Dropping the kernel entitlements still installs, but large models hit the
per-process Jetsam limit. Both kernel entitlements require a paid Apple
Developer account; free personal teams cannot grant them.

The unsigned IPA carries the sandbox `sanadai` and `ios-local-llm` URL schemes,
so deep links keep working after re-signing as long as the bundle ID is
unchanged.

Verify a downloaded IPA before installing:

```bash
shasum -a 256 SanadAI-<version>-<build>-unsigned.ipa
# compare with the value in build-metadata.json and the job summary
```

## Memory entitlement on sideloaded builds

An unsigned archive is not signed, so it carries **no entitlements at all**.
Declaring the keys in `SanadAI.entitlements` only matters once a signing step
copies them into the code signature. That is why a re-signed IPA can install
and run while still reporting:

> This installed build is missing the iOS Increased Memory Limit entitlement.

Diagnose it inside the app: **Home → device strip → Memory entitlement**. The
value comes from `SecTaskCopyValueForEntitlement` on the running process, not
from the source plist, so it reflects what iOS actually granted.

To grant it:

1. The provisioning profile must include the Increased Memory Limit capability.
   Free personal teams cannot issue it; a paid Apple Developer account is
   required.
2. The entitlements file must list `com.apple.developer.kernel.increased-memory-limit`
   (and, for models above ~4 GB, `com.apple.developer.kernel.extended-virtual-addressing`).
3. Re-sign both the app and `SanadAIShare.appex` with that profile. ESign applies
   one entitlements file per signature, so import `SanadAI.entitlements` for the
   app and `SanadAIShare.entitlements` for the extension.

Without the entitlement the app still runs, but the per-process ceiling stays at
the default iOS budget (roughly 2–3 GB on 6 GB devices). Models above that are
blocked by `MemoryAdvisor` before loading, with a message that explains the
shortfall instead of crashing the process.

## Signed builds

Set these repository secrets (`Settings → Secrets and variables → Actions`, or
`gh secret set`) before running with `signing=signed`:

| Secret | Value |
| --- | --- |
| `APPLE_CERTIFICATE_P12` | Base64 of an Apple Distribution `.p12` (`base64 -i cert.p12 \| pbcopy`) |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `APPLE_PROVISIONING_PROFILE_APP` | Base64 of the App Store / Ad Hoc profile for `com.sanadai.app` |
| `APPLE_PROVISIONING_PROFILE_EXTENSION` | Base64 of the profile for `com.sanadai.app.share` |
| `APPLE_TEAM_ID` | Ten-character Apple Developer team identifier |

The signing step decodes each profile and rejects it when
`Entitlements.application-identifier` does not end in the expected bundle ID, so
a mismatched profile fails in seconds instead of during `exportArchive`.

`signing=auto` keeps the pipeline green for contributors who have no Apple
credentials: it builds unsigned and states so in the job summary.
`signing=signed` is deliberately strict and fails when any secret is empty.

## Reproducing a build locally

```bash
git clone --recurse-submodules https://github.com/moha700m/ios-local-llm.git
cd ios-local-llm
./scripts/build_native_frameworks.sh        # ~10 min cold, cached afterwards
xcodegen generate
pod install
open SanadAI.xcworkspace                    # scheme: SanadAI
```

Archive and package exactly as CI does:

```bash
xcodebuild archive \
  -workspace SanadAI.xcworkspace -scheme SanadAI -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/SanadAI.xcarchive \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""

mkdir -p build/ipa/Payload
ditto build/SanadAI.xcarchive/Products/Applications/SanadAI.app build/ipa/Payload/SanadAI.app
(cd build/ipa && zip -qry ../SanadAI-unsigned.ipa Payload)
```

## Troubleshooting

| Symptom | Cause | Fix in the workflow |
| --- | --- | --- |
| `Multiple commands produce .../SanadAI.app/Info.plist` | The legacy `IOSLocalLLM/Info.plist` was treated as a resource | Excluded in `project.yml` `sources.excludes`; `Info-SanadAI.plist` is the only plist |
| `Sandbox: bash deny file-write-create` during archive | User-script sandboxing blocks build phases that write into the build directory | `ENABLE_USER_SCRIPT_SANDBOXING: NO` on the `SanadAI` target |
| `cannot find 'llama.h' in scope` / missing whisper bridge | Generated project had no bridging header for the native frameworks | `SWIFT_OBJC_BRIDGING_HEADER` points at `IOSLocalLLM/Services/LlamaCpp/SanadAI-Bridging-Header.h` |
| `invalid redeclaration of 'HTTPRequest'` | A local model shadowed a type from another module | Renamed to `BridgeHTTPRequest` |
| `switch must be exhaustive` after adding a case | New `ModelState.paused` case was not handled | Handled in every affected switch |
| `whisper.cpp` builds a static XCFramework and the app link fails | Upstream build script defaults | `BUILD_STATIC_XCFRAMEWORK=OFF` in `scripts/native/build_whisper_ios.sh` |
| `Podfile.lock` checksum mismatch | Pods restored from a stale cache | Manifest checksum committed alongside `Podfile` |
| `Xcode couldn't find any iOS App Development provisioning profiles` | `signing=auto` with no secrets, or a profile for the wrong bundle ID | Use `signing=unsigned`, or upload both profiles |
| Unit tests fail on a model catalog expectation | Catalog fixture and published context window drifted | Tests assert against `project.yml`/catalog values |

## Security posture

- Every `uses:` reference is pinned to a full commit SHA; the repository's
  `scripts/validate_open_source.sh` fails the `Validate` workflow if an action
  tag appears in any workflow file.
- `actions/checkout` runs with `persist-credentials: false` and the workflow
  declares `permissions: contents: read`.
- The signing certificate lives in a per-run keychain under `$RUNNER_TEMP`,
  unlocked with a random UUID password and deleted in an `always()` step.
- No signing material, IPA, or build log is committed; only artifacts with a
  30-day retention are published.
