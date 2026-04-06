import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var exploit = ExploitManager.shared
    @State private var selectedTab = 0
    @State private var showNoCardsError = false
    @State private var cards: [Card] = []
    @State private var detectedCardsRoot = "not-detected"
    @State private var offsetInput = ""


    private let helper = ObjcHelper()

    private struct CardBundleCandidate {
        let directoryPath: String
        let bundleName: String
        let backgroundFileName: String
    }

    private func joinPath(_ parent: String, _ child: String) -> String {
        if parent.hasSuffix("/") {
            return parent + child
        }
        return parent + "/" + child
    }

    private func scanLog(_ message: String) {
        exploit.addLog("[scan] \(message)")
    }

    private func pathVariants(for path: String) -> [String] {
        var variants: [String] = [path]
        if path.hasPrefix("/private/var/") {
            variants.append(String(path.dropFirst("/private".count)))
        } else if path.hasPrefix("/var/") {
            variants.append("/private" + path)
        }

        var unique: [String] = []
        for variant in variants where !unique.contains(variant) {
            unique.append(variant)
        }
        return unique
    }

    private func listDirectory(_ path: String) -> [String] {
        let fm = FileManager.default

        for variant in pathVariants(for: path) {
            if let direct = try? fm.contentsOfDirectory(atPath: variant) {
                return direct
            }
        }

        guard exploit.kfsReady else {
            return []
        }

        // Warm the namecache by touching the path — even if sandbox denies it,
        // the kernel resolves path components and populates the name cache.
        for variant in pathVariants(for: path) {
            _ = access(variant, F_OK)
        }

        for variant in pathVariants(for: path) {
            let entries = helper.kfsListDirectory(variant)
            if !entries.isEmpty {
                return entries
            }
        }

        return []
    }

    private func cardBackgroundFile(in cardDirectory: String) -> String? {
        let files = listDirectory(cardDirectory)
        guard !files.isEmpty else {
            return nil
        }

        let preferred = [
            "cardBackgroundCombined@2x.png",
            "cardBackgroundCombined@3x.png",
            "cardBackgroundCombined.png",
            "cardBackgroundCombined.pdf"
        ]

        for name in preferred where files.contains(name) {
            return name
        }

        return files.first { file in
            let lower = file.lowercased()
            return lower.hasPrefix("cardbackgroundcombined") && (lower.hasSuffix(".png") || lower.hasSuffix(".pdf"))
        }
    }

    private func collectCardBundles(in cardsRoot: String) -> [CardBundleCandidate] {
        let entries = listDirectory(cardsRoot)
        guard !entries.isEmpty else {
            return []
        }

        var bundles: [CardBundleCandidate] = []
        var seenDirectories: Set<String> = []

        for entry in entries {
            if entry == "." || entry == ".." {
                continue
            }

            let candidateDirectory = joinPath(cardsRoot, entry)
            if let backgroundFile = cardBackgroundFile(in: candidateDirectory) {
                if !seenDirectories.contains(candidateDirectory) {
                    bundles.append(
                        CardBundleCandidate(
                            directoryPath: candidateDirectory,
                            bundleName: entry,
                            backgroundFileName: backgroundFile
                        )
                    )
                    seenDirectories.insert(candidateDirectory)
                }
                continue
            }

            // On some versions, card bundles are nested one level deeper.
            let nestedEntries = listDirectory(candidateDirectory)
            for nested in nestedEntries {
                if nested == "." || nested == ".." {
                    continue
                }

                let nestedDirectory = joinPath(candidateDirectory, nested)
                if let backgroundFile = cardBackgroundFile(in: nestedDirectory), !seenDirectories.contains(nestedDirectory) {
                    bundles.append(
                        CardBundleCandidate(
                            directoryPath: nestedDirectory,
                            bundleName: "\(entry)/\(nested)",
                            backgroundFileName: backgroundFile
                        )
                    )
                    seenDirectories.insert(nestedDirectory)
                }
            }
        }

        return bundles
    }

    private func discoverCardsRoot() -> String? {
        var candidates: [String] = []

        if let detected = exploit.detectedCardsRootPath {
            candidates.append(detected)
        }
        for candidate in exploit.knownCardsRootCandidates where !candidates.contains(candidate) {
            candidates.append(candidate)
        }

        for candidate in candidates {
            let found = collectCardBundles(in: candidate)
            if !found.isEmpty {
                scanLog("candidate \(candidate) yielded \(found.count) card bundle(s)")
                return candidate
            }
        }

        let passContainers = [
            "/var/mobile/Library/Passes",
            "/private/var/mobile/Library/Passes"
        ]

        for container in passContainers {
            let topEntries = listDirectory(container)

            for primary in ["Cards", "Passes", "Wallet"] where topEntries.contains(primary) {
                let candidate = joinPath(container, primary)
                if !collectCardBundles(in: candidate).isEmpty {
                    return candidate
                }

                let nestedCards = joinPath(candidate, "Cards")
                if !collectCardBundles(in: nestedCards).isEmpty {
                    return nestedCards
                }
            }

            for entry in topEntries {
                if entry == "." || entry == ".." {
                    continue
                }

                let lower = entry.lowercased()
                if !(lower.contains("card") || lower.contains("pass") || lower.contains("wallet")) {
                    continue
                }

                let candidate = joinPath(container, entry)
                if !collectCardBundles(in: candidate).isEmpty {
                    return candidate
                }

                let nestedCards = joinPath(candidate, "Cards")
                if !collectCardBundles(in: nestedCards).isEmpty {
                    return nestedCards
                }
            }
        }

        scanLog("no card bundles found in known pass containers")
        return nil
    }

    private func buildLogExportText() -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let header = [
            "CardioSword diagnostic export",
            "timestamp=\(timestamp)",
            "status=\(exploit.statusMessage)",
            "darksword_ready=\(exploit.darkswordReady)",
            "sandbox_escaped=\(exploit.sandboxEscaped)",
            "kernproc_offset=\(exploit.hasKernprocOffset ? String(format: "0x%llx", exploit.kernprocOffset) : "missing")",
            "cards_root=\(detectedCardsRoot)",
            ""
        ].joined(separator: "\n")

        let body = exploit.logText.isEmpty ? "No logs yet." : exploit.logText
        return header + body
    }

    private func loadCards() {
        cards = getPasses()
    }

    private func getPasses() -> [Card] {
        guard let cardsRoot = discoverCardsRoot() else {
            detectedCardsRoot = "not-detected"
            exploit.setDetectedCardsRootPath(nil)
            return []
        }

        exploit.setDetectedCardsRootPath(cardsRoot)
        detectedCardsRoot = cardsRoot

        var data = [Card]()

        let bundles = collectCardBundles(in: cardsRoot)
        scanLog("final scan root=\(cardsRoot) bundles=\(bundles.count)")

        for bundle in bundles {
            data.append(
                Card(
                    imagePath: joinPath(bundle.directoryPath, bundle.backgroundFileName),
                    directoryPath: bundle.directoryPath,
                    bundleName: bundle.bundleName,
                    backgroundFileName: bundle.backgroundFileName
                )
            )
        }

        return data
    }

    private func refreshOffsetInputFromState() {
        if exploit.hasKernprocOffset {
            offsetInput = String(format: "0x%llx", exploit.kernprocOffset)
        }
    }

    private func recheckAndReload() {
        exploit.refreshAccessProbe()
        exploit.refreshKernprocOffsetState()
        loadCards()
    }

    private func runAllAndReload() {
        exploit.runAll { _ in
            recheckAndReload()
            if cards.isEmpty {
                showNoCardsError = true
            }
        }
    }

    private func openWalletApp() {
        // Open Wallet so it reads card directories, warming the kernel namecache.
        for scheme in ["shoebox://", "wallet://"] {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        exploit.addLog("Could not open Wallet app. Open it manually, then scan again.")
    }

    // MARK: - Cards Tab

    private var cardsTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Text("cards_tap_to_customize")
                    .font(.system(size: 25))
                    .foregroundColor(.white)

                Text("cards_swipe_hint")
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if !cards.isEmpty {
                    TabView {
                        ForEach(cards) { card in
                            CardView(card: card, exploit: exploit)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 340)

                    Button("cards_refresh") {
                        loadCards()
                        if cards.isEmpty {
                            showNoCardsError = true
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.top, 16)
                } else {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "creditcard.trianglebadge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("cards_none_found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)

                        Text(String(format: NSLocalizedString("cards_path_label", comment: ""), detectedCardsRoot))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))

                        HStack(spacing: 12) {
                            Button("cards_open_wallet") {
                                openWalletApp()
                            }
                            .foregroundColor(.cyan)
                        }

                        Button("cards_scan_again") {
                            loadCards()
                            if cards.isEmpty {
                                showNoCardsError = true
                            }
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()
                }
            }
            .alert(isPresented: $showNoCardsError) {
                Alert(
                    title: Text("cards_none_found_alert"),
                    message: Text(String(format: NSLocalizedString("cards_last_root", comment: ""), detectedCardsRoot))
                )
            }
        }
    }

    // MARK: - Exploit Tab

    private var exploitTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("exploit_engine")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(exploit.statusMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(exploit.canApplyCardChanges ? .green : .orange)

                    Group {
                        Text(String(
                            format: "darksword=%@ | sandbox=%@",
                            exploit.darkswordReady ? "ready" : "not-ready",
                            exploit.sandboxEscaped ? "escaped" : "blocked"
                        ))

                        Text(exploit.hasKernprocOffset
                             ? String(format: "kernproc_offset=0x%llx", exploit.kernprocOffset)
                             : "kernproc_offset=missing")
                        .foregroundColor(exploit.hasKernprocOffset ? .green.opacity(0.9) : .orange)

                        Text("cards_root=\(detectedCardsRoot)")

                        if exploit.darkswordReady {
                            Text(String(
                                format: "kernel_base=0x%llx slide=0x%llx",
                                exploit.kernelBase,
                                exploit.kernelSlide
                            ))
                            Text(String(
                                format: "our_proc=0x%llx our_task=0x%llx",
                                exploit.ourProc,
                                exploit.ourTask
                            ))
                        }
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 8) {
                        TextField(NSLocalizedString("exploit_offset_placeholder", comment: ""), text: $offsetInput)
                            .textFieldStyle(.roundedBorder)

                        Button("exploit_set") {
                            if exploit.setKernprocOffset(from: offsetInput) {
                                refreshOffsetInputFromState()
                                recheckAndReload()
                            }
                        }
                        .foregroundColor(.white)
                    }

                    HStack(spacing: 10) {
                        Button(exploit.xpfResolving ? NSLocalizedString("exploit_resolving", comment: "") : NSLocalizedString("exploit_resolve_offsets", comment: "")) {
                            exploit.resolveOffsetsViaXPF { _ in
                                refreshOffsetInputFromState()
                                recheckAndReload()
                            }
                        }
                        .disabled(exploit.xpfResolving)
                        .foregroundColor(.cyan)

                        Button("exploit_clear_cache") {
                            exploit.clearKernelCache()
                            refreshOffsetInputFromState()
                        }
                        .foregroundColor(.red.opacity(0.8))
                    }

                    HStack(spacing: 10) {
                        Button(exploit.darkswordRunning ? NSLocalizedString("exploit_running", comment: "") : NSLocalizedString("exploit_run_darksword", comment: "")) {
                            exploit.runDarksword { _ in
                                recheckAndReload()
                            }
                        }
                        .disabled(exploit.darkswordRunning || exploit.darkswordReady)
                        .foregroundColor(exploit.darkswordReady ? .green : .white)

                        Button("exploit_escape_sandbox") {
                            exploit.escapeSandbox { _ in
                                recheckAndReload()
                            }
                        }
                        .disabled(exploit.darkswordRunning || !exploit.darkswordReady || exploit.sandboxEscaped)
                        .foregroundColor(exploit.sandboxEscaped ? .green : .white)

                        Button("exploit_run_all") {
                            runAllAndReload()
                        }
                        .disabled(exploit.darkswordRunning || exploit.sandboxEscaped)
                        .foregroundColor(.cyan)
                    }
                    }

                    if exploit.darkswordReady && exploit.sandboxEscaped {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("exploit_complete")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }

                    Button("exploit_copy_logs") {
                        UIPasteboard.general.string = buildLogExportText()
                        exploit.addLog("[scan] logs copied to clipboard")
                    }
                    .foregroundColor(.white)

                    Text(exploit.logText.isEmpty ? NSLocalizedString("exploit_no_logs", comment: "") : exploit.logText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color.green.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                }
                .padding(14)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            cardsTab
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("tab_cards")
                }
                .tag(0)

            MyCardsView(exploit: exploit, cards: cards)
                .tabItem {
                    Image(systemName: "tray.full.fill")
                    Text("tab_mycards")
                }
                .tag(1)

            CommunityView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("tab_community")
                }
                .tag(2)

            exploitTab
                .tabItem {
                    Image(systemName: "terminal.fill")
                    Text("tab_exploit")
                }
                .tag(3)
        }
        .accentColor(.white)
        .onAppear {
            // Dark tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(white: 0.08, alpha: 1)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            recheckAndReload()
            refreshOffsetInputFromState()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
