# CardioDS (iOS 15.0 - 26.0.1)

![87](https://user-images.githubusercontent.com/29115431/193304861-3eb9f323-8d9e-46d9-a539-26565a655832.png)

> CardioDS supports sideloading, **TrollStore** (iOS 15–17.0), and **LiveContainer**.

## Features

- **Apple Wallet card customization** — Replace card background images directly from your photo library or the Files app
- **Non-Apple Pay card support** — Browse, preview, and manage non-payment Wallet passes (boarding passes, loyalty cards, tickets, etc.) with Wallet-style previews and category-based tabs
- **Hide expired passes** — Optionally hide old boarding passes and expired items from the card list
- **Card number editor** — Read and edit the last 4 digits displayed on your card (primaryAccountSuffix in pass.json), with automatic backup/restore
- **Metadata editor overlay** — Open a built-in JSON/text editor for `pass.json` and nearby `.strings` files, with per-file backup/restore
- **Bundle Editor** — Inspect and edit pass.json, localized strings, and bundled artwork directly in-app, including backup/restore and asset replacement
- **Auto kernproc offset resolution** — Downloads your device's kernelcache and resolves kernel offsets via XPF (XNU PatchFinder)
- **Integrated exploit engine** — DarkSword + sandbox escape, all built-in
- **TrollStore support (iOS 15–17.0)** — Direct filesystem access via entitlements; no exploit needed. Displays "Access" instead of "Exploit" when running under TrollStore
- **LiveContainer support** — Detects LiveContainer guest runtime and uses process marker matching for reliable exploit execution in rehosted environments
- **Card management** — Backup, restore, rename cards with nicknames
- **My Cards** — Save and submit card designs to the community catalog with card name, issuer, and country metadata
- **Community Cards** — Browse and download 300+ card designs from a community-driven catalog, with remote updates that don't require a rebuild
- **Custom card submissions** — Submit your own card artwork directly from the app for review
- **Auto-approve pipeline** — Approved submissions are automatically added to the remote catalog via GitHub Actions
- **8-language localization** — English, Spanish, French, Italian, German, Russian, Chinese (Simplified), Japanese

### Important Notes

- **iOS 26.0.1 / iOS 18.7.1 is the maximum scope** — anything more recent will likely never be compatible
- **iOS 18.7.2 / 18.7.3 / iOS 18.7.7** fixed DarkSword vulnerability, these versions are exceptions and it will never be supported.
- **Only tested on 18.6.2 arm64e A18 Pro** — if you are unable to make CardioDS work, report it through Discord or GitHub Issues
- **TrollStore users (iOS 15–17.0)** — CardioDS detects TrollStore entitlements at launch and uses direct filesystem access. No exploit step is required.
- **LiveContainer** — Supported. CardioDS detects the LiveContainer guest environment automatically and adjusts process identification for the exploit engine.
- **Community Cards tab may load slowly** — The catalog contains hundreds of high-resolution card images; it may take a little while for the tab to load.
- **Submitted card image quality** — Cards submitted through the app are compressed to base64 JPEG to fit within GitHub's issue body limits (65,536 characters). This may noticeably reduce image quality compared to the original. For best results, submit images at card resolution (1536×969 or similar) with clean backgrounds.

## How It Works

1. On first launch, CardioDS downloads the correct kernelcache for your device model and iOS version using `libgrabkernel2`
2. XPF (XNU PatchFinder) parses the kernelcache Mach-O to resolve `kernproc`, `rootvnode`, and process struct size
3. Offsets are cached in UserDefaults — no re-download needed unless you update iOS
4. The exploit engine uses the resolved offsets to gain kernel read/write access
5. Card artwork is written directly to `/var/mobile/Library/Passes/Cards`

> **TrollStore / LiveContainer:** When running with the appropriate entitlements (e.g. `com.apple.private.security.no-sandbox`), CardioDS skips the exploit flow entirely and writes directly to the Wallet path. Offset resolution is deferred until explicitly triggered.

## Setup

### 1. Clone

```bash
git clone https://github.com/drkm9743/CardioDS.git
cd CardioDS
```

### 2. Download XPF + libgrabkernel2 dylibs

```bash
mkdir -p card-test/lib
curl -L -o card-test/lib/libgrabkernel2.dylib \
  https://github.com/rooootdev/lara/raw/main/lara/lib/libgrabkernel2.dylib
curl -L -o card-test/lib/libxpf.dylib \
  https://github.com/rooootdev/lara/raw/main/lara/lib/libxpf.dylib
```

This downloads `libxpf.dylib` and `libgrabkernel2.dylib` from Lara's repository into `card-test/lib/`. If the downloads fail, grab them manually from [rooootdev/lara](https://github.com/rooootdev/lara/tree/main/lara/lib).

### 3. Xcode setup

1. Open `Cardio.xcodeproj` in Xcode
2. Drag `card-test/lib/` into the Xcode navigator
3. Select the **Cardio** target → **General** → **Frameworks, Libraries, and Embedded Content**
4. Add both `libxpf.dylib` and `libgrabkernel2.dylib` → set **Embed & Sign**
5. In **Build Settings**:
   - **Library Search Paths**: add `$(SRCROOT)/card-test/lib`
   - **Header Search Paths**: add `$(SRCROOT)/card-test/kexploit`
6. Build and install via your preferred signing method

## Usage

1. Open CardioDS
2. The app auto-resolves kernel offsets on first run (or tap **Resolve Offsets** in the Exploit tab)
3. Tap **Run All** to run DarkSword + sandbox escape
4. Go to the **Cards** tab, tap a card, and pick a replacement image from your photo library or the Files app
5. Tap **Metadata** to edit `pass.json` or the card's `.strings` files directly in-app
6. Tap the **Number** button to edit the last 4 digits shown on the card
7. Changes persist on disk; after reboot, run **Run All** again

> **TrollStore / LiveContainer:** Steps 2–3 are skipped automatically. The Cards tab is available immediately.

## Troubleshooting

If the exploit fails to find your process or offset resolution fails:

1. Go to the **Exploit** tab and tap **Clear Kernel Cache**
2. Tap **Resolve Offsets** to re-download and re-parse the kernelcache
3. Then tap **Run All** again

Deleting and re-downloading the kernelcache fixes most issues. Try this before opening a GitHub issue.

The exploit execution could trigger reboots on your device, don't consider it as an issue until it happens like 10 times in a row.

Alternatively, exploit execution could take from seconds to minutes, be patient.

## Architecture

```
card-test/
├── ContentView.swift          # Main tab view (Cards, My Cards, Community, Exploit)
├── CardView.swift             # Individual card display + replacement + bundle editor
├── AssetDocumentPicker.swift  # File picker for bundle asset replacement
├── MyCardsView.swift          # Card backup/restore + submit to community
├── CommunityView.swift        # Community card catalog (built-in + remote)
├── GitHubService.swift        # GitHub Issues API for card submissions
├── ExploitManager.swift       # Exploit state machine + XPF integration + runtime mode detection
├── LanguageManager.swift      # In-app language override (persisted)
├── card_testApp.swift         # App entry point + stale launch state cleanup
├── ImagePicker.swift          # Photo library picker
├── DocumentPicker.swift       # Files app document picker
├── ObjcHelper.h/m             # ObjC bridge (KFS, daemon refresh, entitlement inspection, direct I/O, LiveContainer detection)
├── kexploit/
│   ├── darksword.h/m          # DarkSword kernel exploit + LiveContainer process marker system
│   ├── kfs.h/m                # Kernel file system read
│   ├── utils.h/m              # Kernel utilities (proc walking, task resolution, LiveContainer-aware proc lookup)
│   ├── sandbox_escape.h/m     # Sandbox escape + rehosted process name matching
│   ├── offsets.h/m            # XPF-based auto offset resolution with retry
│   ├── xpf_minimal.h          # Minimal XPF struct declarations
│   └── libgrabkernel2.h       # Kernelcache download API
├── {en,es,fr,it,de,ru,zh-Hans,ja}.lproj/
│   └── Localizable.strings    # Localized strings (8 languages)
CardioTrollStore.entitlements   # TrollStore entitlements (no-sandbox, platform-application, etc.)
community-cards/
├── catalog.json               # Remote card catalog (auto-updated by GitHub Actions)
└── images/                    # Approved card images
.github/workflows/
├── build-ios.yml              # CI: build unsigned IPA + TrollStore TIPA on push
└── approve-card.yml           # Auto-approve: label issue → add to catalog
```

## Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-5865F2?logo=discord&logoColor=white)](https://discord.com/invite/77FT6fNmBc)

### Contributing Card Designs

Help build the community card catalog! You can submit designs directly from the app:

#### From My Cards (existing Apple Wallet cards)
1. Go to the **Cards** tab and apply the card background you'd like to share
2. Go to **My Cards** → tap **Backup All Current Cards** to save it
3. Find the card in your saved list and tap the green **Submit** button (↑)
4. Fill in the card name, issuer, and country in the submit sheet
5. The submission creates a GitHub Issue for review

#### Custom designs (from photo library)
1. Go to the **Community** tab → tap **Submit Custom Card Design**
2. Pick an image from your photo library
3. Enter the card name → submit
4. The submission is sent with `Issuer: Custom` and `Country: N/A`

#### How approvals work
1. A maintainer reviews the GitHub Issue
2. Adding the `approved` label triggers an automatic GitHub Action
3. The card image is decoded and saved to `community-cards/images/`
4. The card entry is appended to `community-cards/catalog.json`
5. The issue is closed with a confirmation comment
6. **The card appears in the Community tab automatically** — no app update needed

> **Note:** Submitted images are compressed to base64 JPEG (max ~44KB) to fit GitHub's 65,536-character issue body limit. This may reduce image quality. For best results, use clean card-resolution images (1536×969).

**Requirements for submissions:**
- Include the card name, issuer, and country
- One card per submission
- Submitted card images must not contain any personal information (card numbers are automatically stripped by Apple Wallet)

## Support

If you find CardioDS useful, consider buying me a coffee:

[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/argz97)

## Credits

- [GitHub - cisc0disco](https://github.com/cisc0disco/Cardio) — Original Cardio app
- [GitHub - htimesnine](https://github.com/htimesnine/DarkSword-RCE) — Original DarkSword exploit source
- [GitHub - opa334](https://github.com/opa334) — DarkSword kexploit PoC, ChOma, XPF
- [GitHub - AlfieCG](https://github.com/alfiecg24) — libgrabkernel2
- [GitHub - rooootdev](https://github.com/rooootdev/lara) — Lara (AGPL-3.0), XPF integration reference
- [reddit r/CreditCards - chaoxu](https://dynalist.io/d/ldKY6rbMR3LPnWz4fTvf_HCh) — Community card images post
- [dynalist.io - chaoxu & others](https://dynalist.io/d/ldKY6rbMR3LPnWz4fTvf_HCh) — Community card images

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0).

**Third-party components:**

- DarkSword (htimesnine / opa334)
- XPF, ChOma (opa334)
- libgrabkernel2 (AlfieCG)
- Lara (rooootdev) — AGPL-3.0
