# CardioDS

![87](https://user-images.githubusercontent.com/29115431/193304861-3eb9f323-8d9e-46d9-a539-26565a655832.png)

> Customize your Apple Pay card artwork on iOS (17.2.1 - 26.0.1).

## Features

- **Apple Pay card customization** — Replace card background images directly from your photo library
- **Auto kernproc offset resolution** — Downloads your device's kernelcache and resolves kernel offsets via XPF (XNU PatchFinder), no manual hex input needed
- **Integrated exploit engine** — DarkSword + sandbox escape + KFS, all built-in
- **Card management** — Backup, restore, rename cards with nicknames
- **Community cards** — Browse and download card designs from a built-in catalog
- **8-language localization** — English, Spanish, French, Italian, German, Russian, Chinese (Simplified), Japanese
  
- **iOS 26.0.1/iOS 18.7.1 is the max scope, anything more recent than that will likely never be compatible**
- **Only tested on 18.6.2 arm64e A18 Pro, if you are unable to make CardioDS work, message me on Discord: drkm43**

## How It Works

1. On first launch, CardioDS downloads the correct kernelcache for your device model and iOS version using `libgrabkernel2`
2. XPF (XNU PatchFinder) parses the kernelcache Mach-O to resolve `kernproc`, `rootvnode`, and process struct size
3. Offsets are cached in UserDefaults — no re-download needed unless you update iOS
4. The exploit engine uses the resolved offsets to gain kernel read/write access
5. Card artwork is written directly to `/var/mobile/Library/Passes/Cards`

## Setup

### 1. Clone

```bash
git clone https://github.com/cisc0disco/CardioDS.git
cd CardioDS
```

### 2. Download XPF + libgrabkernel2 dylibs

```bash
chmod +x setup_xpf.sh
./setup_xpf.sh
```

This downloads `libxpf.dylib` and `libgrabkernel2.dylib` from Lara's repository into `card-test/lib/`.

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
4. Go to the **Cards** tab, tap a card, and pick a replacement image from your photo library
5. Changes persist on disk; after reboot, run **Run All** again

## Architecture

```
card-test/
├── ContentView.swift          # Main tab view (Cards, My Cards, Community, Exploit)
├── CardView.swift             # Individual card display + replacement
├── MyCardsView.swift          # Card backup/restore management
├── CommunityView.swift        # Community card catalog browser
├── ExploitManager.swift       # Exploit state machine + XPF integration
├── card_testApp.swift         # App entry point + offset init
├── ImagePicker.swift          # Photo library picker
├── ObjcHelper.h/m             # ObjC bridge (KFS, daemon refresh)
├── kexploit/
│   ├── darksword.h/m          # DarkSword kernel exploit
│   ├── kfs.h/m                # Kernel file system read
│   ├── utils.h/m              # Kernel utilities (proc walking, task resolution)
│   ├── sandbox_escape.h/m     # Sandbox escape
│   ├── offsets.h/m            # XPF-based auto offset resolution
│   ├── xpf_minimal.h          # Minimal XPF struct declarations
│   └── libgrabkernel2.h       # Kernelcache download API
├── en.lproj/Localizable.strings
├── es.lproj/Localizable.strings
├── fr.lproj/Localizable.strings
├── it.lproj/Localizable.strings
├── de.lproj/Localizable.strings
├── ru.lproj/Localizable.strings
├── zh-Hans.lproj/Localizable.strings
└── ja.lproj/Localizable.strings
```

## Credits

- [cisc0disco](https://github.com/cisc0disco/Cardio) — Original Cardio app
- [htimesnine](https://github.com/htimesnine/DarkSword-RCE) — Original DarkSword exploit source
- [opa334](https://github.com/opa334) — DarkSword kexploit PoC, ChOma (MIT), XPF (MIT)
- [rooootdev](https://github.com/rooootdev/lara) — Lara (AGPL-3.0), XPF integration reference
- [AlfieCG](https://github.com/alfiecg24) — libgrabkernel2 (MIT)
- [AppInstallerIOS](https://github.com/AppInstalleriOS) — Community card images

## License

This project is licensed under the [MIT License](LICENSE).

**Third-party components have their own licenses:**
- Lara (rooootdev) — AGPL-3.0 (used only as reference; no AGPL code is copied)
