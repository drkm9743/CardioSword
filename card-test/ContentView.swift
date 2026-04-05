import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var exploit = ExploitManager.shared
    @State private var selectedTab = 0
    @State private var showNoCardsError = false
    @State private var cards: [Card] = []
    @State private var detectedCardsRoot = "not-detected"
    @State private var usedKfsForScan = false
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

    private func listDirectory(_ path: String, usedKfs: inout Bool) -> [String] {
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
            let viaKfs = helper.kfsListDirectory(variant)
            if !viaKfs.isEmpty {
                usedKfs = true
                return viaKfs
            }
        }

        return []
    }

    private func cardBackgroundFile(in cardDirectory: String, usedKfs: inout Bool) -> String? {
        let files = listDirectory(cardDirectory, usedKfs: &usedKfs)
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

    private func collectCardBundles(in cardsRoot: String, usedKfs: inout Bool) -> [CardBundleCandidate] {
        let entries = listDirectory(cardsRoot, usedKfs: &usedKfs)
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
            if let backgroundFile = cardBackgroundFile(in: candidateDirectory, usedKfs: &usedKfs) {
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
            let nestedEntries = listDirectory(candidateDirectory, usedKfs: &usedKfs)
            for nested in nestedEntries {
                if nested == "." || nested == ".." {
                    continue
                }

                let nestedDirectory = joinPath(candidateDirectory, nested)
                if let backgroundFile = cardBackgroundFile(in: nestedDirectory, usedKfs: &usedKfs), !seenDirectories.contains(nestedDirectory) {
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

    private func discoverCardsRoot(usedKfs: inout Bool) -> String? {
        var candidates: [String] = []

        if let detected = exploit.detectedCardsRootPath {
            candidates.append(detected)
        }
        for candidate in exploit.knownCardsRootCandidates where !candidates.contains(candidate) {
            candidates.append(candidate)
        }

        for candidate in candidates {
            let found = collectCardBundles(in: candidate, usedKfs: &usedKfs)
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
            let topEntries = listDirectory(container, usedKfs: &usedKfs)

            for primary in ["Cards", "Passes", "Wallet"] where topEntries.contains(primary) {
                let candidate = joinPath(container, primary)
                if !collectCardBundles(in: candidate, usedKfs: &usedKfs).isEmpty {
                    return candidate
                }

                let nestedCards = joinPath(candidate, "Cards")
                if !collectCardBundles(in: nestedCards, usedKfs: &usedKfs).isEmpty {
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
                if !collectCardBundles(in: candidate, usedKfs: &usedKfs).isEmpty {
                    return candidate
                }

                let nestedCards = joinPath(candidate, "Cards")
                if !collectCardBundles(in: nestedCards, usedKfs: &usedKfs).isEmpty {
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
            "kfs_ready=\(exploit.kfsReady)",
            "kernproc_offset=\(exploit.hasKernprocOffset ? String(format: "0x%llx", exploit.kernprocOffset) : "missing")",
            "cards_root=\(detectedCardsRoot)",
            "scan_mode=\(usedKfsForScan ? "kfs" : "direct")",
            ""
        ].joined(separator: "\n")

        let body = exploit.logText.isEmpty ? "No logs yet." : exploit.logText
        return header + body
    }

    private func loadCards() {
        cards = getPasses()
    }

    private func getPasses() -> [Card] {
        var usedKfs = false
        guard let cardsRoot = discoverCardsRoot(usedKfs: &usedKfs) else {
            usedKfsForScan = usedKfs
            detectedCardsRoot = "not-detected"
            exploit.setDetectedCardsRootPath(nil)
            return []
        }

        exploit.setDetectedCardsRootPath(cardsRoot)
        detectedCardsRoot = cardsRoot

        var data = [Card]()

        let bundles = collectCardBundles(in: cardsRoot, usedKfs: &usedKfs)
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

        usedKfsForScan = usedKfs
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
        // After returning, a "Scan Again" will find entries via KFS.
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
                Text("Tap a card to customize")
                    .font(.system(size: 25))
                    .foregroundColor(.white)

                Text("Swipe to view different cards")
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if !exploit.canApplyCardChanges {
                    Text(exploit.statusMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                }

                if !cards.isEmpty {
                    TabView {
                        ForEach(cards) { card in
                            CardView(card: card, exploit: exploit)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 340)

                    Button("Refresh Cards") {
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

                        Text("No Cards Found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)

                        Text("Path: \(detectedCardsRoot)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))

                        if !exploit.darkswordReady {
                            Text("Go to the Exploit tab and tap Run All first.")
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        } else if exploit.kfsReady {
                            Text("KFS namecache may be cold. Open Wallet first to warm it, then scan again.")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        HStack(spacing: 12) {
                            Button("Open Wallet") {
                                openWalletApp()
                            }
                            .foregroundColor(.cyan)

                            if !exploit.darkswordReady {
                                Button("Run All + Scan") {
                                    runAllAndReload()
                                }
                                .foregroundColor(.white)
                            }
                        }

                        Button("Scan Again") {
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
                    title: Text("No Cards Were Found"),
                    message: Text("Last detected cards root: \(detectedCardsRoot)")
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
                    Text("Exploit Engine")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(exploit.statusMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(exploit.canApplyCardChanges ? .green : .orange)

                    Group {
                        Text(String(
                            format: "darksword=%@ | sandbox=%@ | kfs=%@",
                            exploit.darkswordReady ? "ready" : "not-ready",
                            exploit.sandboxEscaped ? "escaped" : "blocked",
                            exploit.kfsReady ? "ready" : "not-ready"
                        ))

                        Text(exploit.hasKernprocOffset
                             ? String(format: "kernproc_offset=0x%llx", exploit.kernprocOffset)
                             : "kernproc_offset=missing")
                        .foregroundColor(exploit.hasKernprocOffset ? .green.opacity(0.9) : .orange)

                        Text("cards_root=\(detectedCardsRoot)")
                        Text("scan_mode=\(usedKfsForScan ? "kfs" : "direct")")

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
                        TextField("kernproc offset (hex)", text: $offsetInput)
                            .textFieldStyle(.roundedBorder)

                        Button("Set") {
                            if exploit.setKernprocOffset(from: offsetInput) {
                                refreshOffsetInputFromState()
                                recheckAndReload()
                            }
                        }
                        .foregroundColor(.white)
                    }

                    HStack(spacing: 10) {
                        Button(exploit.darkswordRunning ? "Running..." : "Run DarkSword") {
                            exploit.runDarksword { _ in
                                recheckAndReload()
                            }
                        }
                        .disabled(exploit.darkswordRunning || exploit.kfsRunning)
                        .foregroundColor(.white)

                        Button(exploit.kfsRunning ? "Init KFS..." : "Init KFS") {
                            exploit.initKFS { _ in
                                recheckAndReload()
                            }
                        }
                        .disabled(exploit.darkswordRunning || exploit.kfsRunning)
                        .foregroundColor(.white)

                        Button("Run All") {
                            runAllAndReload()
                        }
                        .disabled(exploit.darkswordRunning || exploit.kfsRunning)
                        .foregroundColor(.white)
                    }

                    Button("Copy Logs") {
                        UIPasteboard.general.string = buildLogExportText()
                        exploit.addLog("[scan] logs copied to clipboard")
                    }
                    .foregroundColor(.white)

                    Text(exploit.logText.isEmpty ? "No logs yet." : exploit.logText)
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
                    Text("Cards")
                }
                .tag(0)

            CommunityView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("Community")
                }
                .tag(1)

            exploitTab
                .tabItem {
                    Image(systemName: "terminal.fill")
                    Text("Exploit")
                }
                .tag(2)
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
