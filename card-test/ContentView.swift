import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var exploit = ExploitManager.shared
    @ObservedObject private var langMgr = LanguageManager.shared
    @AppStorage("cardio.hide_archived_wallet_items") private var hideArchivedWalletItems = true
    @State private var selectedTab = 0
    @State private var showNoCardsError = false
    @State private var paymentCards: [Card] = []
    @State private var walletPasses: [Card] = []
    @State private var selectedCardsSection: WalletDisplayCategory = .paymentCards
    @State private var bundleEditorCard: Card?
    @State private var detectedCardsRoot = "not-detected"
    @State private var offsetInput = ""
    @State private var isLoadingCards = false
    @State private var cardsScanGeneration = 0
    @State private var hasAttemptedInitialScan = false

    private let helper = ObjcHelper()

    private struct CardBundleCandidate {
        let directoryPath: String
        let bundleName: String
        let backgroundFileName: String?
        let kind: CardKind
        let passStyle: WalletPassStyle?
        let displayCategory: WalletDisplayCategory
        let expirationDate: Date?
        let relevantDate: Date?
        let isVoided: Bool
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

    private func readFileData(_ path: String, maxSize: Int64 = 512 * 1024) -> Data? {
        let fm = FileManager.default

        for variant in pathVariants(for: path) {
            if let data = fm.contents(atPath: variant) {
                return data
            }
        }

        guard exploit.kfsReady else {
            return nil
        }

        for variant in pathVariants(for: path) {
            if let data = helper.kfsReadFile(variant, maxSize: maxSize) {
                return data
            }
        }

        return nil
    }

    private func trimmedString(_ value: Any?) -> String? {
        guard let string = value as? String else {
            return nil
        }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func hasWalletPassManifest(in passDirectory: String) -> Bool {
        let files = listDirectory(passDirectory)
        guard !files.isEmpty else {
            return false
        }

        let lowercasedFiles = Dictionary(uniqueKeysWithValues: files.map { ($0.lowercased(), $0) })
        return lowercasedFiles["pass.json"] != nil
    }

    private func walletPassRepresentativeAsset(in passDirectory: String) -> String? {
        let files = listDirectory(passDirectory)
        guard !files.isEmpty else {
            return nil
        }

        let preferred = [
            "strip@3x.png",
            "strip@2x.png",
            "strip.png",
            "background@3x.png",
            "background@2x.png",
            "background.png",
            "thumbnail@3x.png",
            "thumbnail@2x.png",
            "thumbnail.png",
            "logo@3x.png",
            "logo@2x.png",
            "logo.png",
            "icon@3x.png",
            "icon@2x.png",
            "icon.png"
        ]

        let lowercasedFiles = Dictionary(uniqueKeysWithValues: files.map { ($0.lowercased(), $0) })
        for name in preferred {
            if let match = lowercasedFiles[name] {
                return match
            }
        }

        return nil
    }

    private func walletPassManifest(in passDirectory: String) -> [String: Any]? {
        let passJsonPath = joinPath(passDirectory, "pass.json")
        guard let data = readFileData(passJsonPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }

    private func walletPassDisplayName(in passDirectory: String, fallbackName: String) -> String {
        guard let json = walletPassManifest(in: passDirectory) else {
            return fallbackName
        }

        if let logoText = trimmedString(json["logoText"]) {
            return logoText
        }

        if let description = trimmedString(json["description"]) {
            return description
        }

        if let organizationName = trimmedString(json["organizationName"]) {
            return organizationName
        }

        return fallbackName
    }

    private func walletPassStyle(in passDirectory: String) -> WalletPassStyle? {
        guard let json = walletPassManifest(in: passDirectory) else {
            return nil
        }

        return WalletPassStyle.detect(in: json)
    }

    private func parsePassDate(_ rawValue: Any?) -> Date? {
        guard let rawString = trimmedString(rawValue) else {
            return nil
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: rawString) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: rawString) {
            return date
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let formats = [
            "yyyy-MM-dd'T'HH:mmZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mmZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd"
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: rawString) {
                return date
            }
        }

        return nil
    }

    private func passFieldStrings(_ rawFields: Any?) -> [String] {
        guard let fields = rawFields as? [[String: Any]] else {
            return []
        }

        return fields.flatMap { field -> [String] in
            var strings: [String] = []
            for key in ["key", "label", "value"] {
                if let value = field[key] as? String {
                    strings.append(value)
                } else if let value = field[key] as? NSNumber {
                    strings.append(value.stringValue)
                }
            }
            return strings
        }
    }

    private func looksLikeMembershipPass(style: WalletPassStyle?, manifest: [String: Any]) -> Bool {
        let semantics = manifest["semantics"] as? [String: Any] ?? [:]
        let semanticKeys = semantics.keys.map { $0.lowercased() }
        if semanticKeys.contains(where: { key in
            key.contains("membership") || key.contains("loyalty") || key.contains("rewards")
        }) {
            return true
        }

        var textBuckets: [String] = [
            manifest["logoText"] as? String,
            manifest["description"] as? String,
            manifest["organizationName"] as? String
        ].compactMap { $0 }

        for value in semantics.values {
            if let string = value as? String {
                textBuckets.append(string)
            }
        }

        if let style, let stylePayload = manifest[style.rawValue] as? [String: Any] {
            textBuckets.append(contentsOf: passFieldStrings(stylePayload["headerFields"]))
            textBuckets.append(contentsOf: passFieldStrings(stylePayload["primaryFields"]))
            textBuckets.append(contentsOf: passFieldStrings(stylePayload["secondaryFields"]))
            textBuckets.append(contentsOf: passFieldStrings(stylePayload["auxiliaryFields"]))
            textBuckets.append(contentsOf: passFieldStrings(stylePayload["backFields"]))
        }

        let haystack = textBuckets
            .joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()

        let keywords = [
            "membership",
            "member",
            "loyalty",
            "rewards",
            "reward",
            "honors",
            "bonvoy",
            "club",
            "status",
            "member since",
            "member number",
            "membership number",
            "loyalty number",
            "rewards number",
            "points",
            "elite"
        ]

        return keywords.contains { haystack.contains($0) }
    }

    private func walletPassCategory(style: WalletPassStyle?, manifest: [String: Any]) -> WalletDisplayCategory {
        if looksLikeMembershipPass(style: style, manifest: manifest) {
            return .membershipCards
        }

        switch style {
        case .storeCard:
            return .storeCards
        case .eventTicket:
            return .eventTickets
        case .boardingPass:
            return .boardingPasses
        case .generic, .coupon, nil:
            return .otherPasses
        }
    }

    private func bundleCandidate(in directoryPath: String, fallbackName: String) -> CardBundleCandidate? {
        if let backgroundFile = cardBackgroundFile(in: directoryPath) {
            return CardBundleCandidate(
                directoryPath: directoryPath,
                bundleName: fallbackName,
                backgroundFileName: backgroundFile,
                kind: .paymentCard,
                passStyle: nil,
                displayCategory: .paymentCards,
                expirationDate: nil,
                relevantDate: nil,
                isVoided: false
            )
        }

        if let manifest = walletPassManifest(in: directoryPath) {
            let style = WalletPassStyle.detect(in: manifest)
            return CardBundleCandidate(
                directoryPath: directoryPath,
                bundleName: walletPassDisplayName(in: directoryPath, fallbackName: fallbackName),
                backgroundFileName: walletPassRepresentativeAsset(in: directoryPath),
                kind: .walletPass,
                passStyle: style,
                displayCategory: walletPassCategory(style: style, manifest: manifest),
                expirationDate: parsePassDate(manifest["expirationDate"]),
                relevantDate: parsePassDate(manifest["relevantDate"]),
                isVoided: manifest["voided"] as? Bool ?? false
            )
        }

        return nil
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
            if let candidate = bundleCandidate(in: candidateDirectory, fallbackName: entry) {
                if !seenDirectories.contains(candidateDirectory) {
                    bundles.append(candidate)
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
                if let candidate = bundleCandidate(in: nestedDirectory, fallbackName: "\(entry)/\(nested)"),
                   !seenDirectories.contains(nestedDirectory) {
                    bundles.append(candidate)
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
            "runtime_mode=\(exploit.prefersDirectAccessMode ? "direct" : "exploit")",
            "status=\(exploit.statusMessage)",
            exploit.entitlementSummary,
            "darksword_ready=\(exploit.darkswordReady)",
            "sandbox_escaped=\(exploit.sandboxEscaped)",
            "kernproc_offset=\(exploit.hasKernprocOffset ? String(format: "0x%llx", exploit.kernprocOffset) : "missing")",
            "cards_root=\(detectedCardsRoot)",
            ""
        ].joined(separator: "\n")

        let body = exploit.logText.isEmpty ? "No logs yet." : exploit.logText
        return header + body
    }

    private var hasAnyWalletItems: Bool {
        !paymentCards.isEmpty || !walletPasses.isEmpty
    }

    private var canScanWalletItems: Bool {
        exploit.canApplyCardChanges
    }

    private var hasVisibleWalletItems: Bool {
        !availableCardsSections.isEmpty
    }

    private var availableCardsSections: [WalletDisplayCategory] {
        WalletDisplayCategory.allCases.filter { !cards(for: $0).isEmpty }
    }

    private func cards(for section: WalletDisplayCategory) -> [Card] {
        let filteredPaymentCards = hideArchivedWalletItems ? paymentCards.filter { !$0.isArchivedLikeWallet } : paymentCards
        let filteredWalletPasses = hideArchivedWalletItems ? walletPasses.filter { !$0.isArchivedLikeWallet } : walletPasses

        switch section {
        case .paymentCards:
            return filteredPaymentCards
        case .membershipCards, .storeCards, .eventTickets, .boardingPasses, .otherPasses:
            return filteredWalletPasses.filter { $0.displayCategory == section }
        }
    }

    private var visibleCards: [Card] {
        cards(for: selectedCardsSection)
    }

    private var shouldShowCardsSectionPicker: Bool {
        availableCardsSections.count > 1
    }

    private var cardsPageHeight: CGFloat {
        visibleCards.map(\.preferredPageHeight).max() ?? WalletDisplayCategory.paymentCards.pageHeight
    }

    private func normalizeSelectedCardsSection() {
        if let firstAvailable = availableCardsSections.first,
           !availableCardsSections.contains(selectedCardsSection) {
            selectedCardsSection = firstAvailable
        }
    }

    private struct PassScanResult {
        let cardsRoot: String?
        let paymentCards: [Card]
        let walletPasses: [Card]
    }

    private func loadCards() {
        guard canScanWalletItems else {
            cardsScanGeneration += 1
            isLoadingCards = false
            paymentCards = []
            walletPasses = []
            detectedCardsRoot = exploit.detectedCardsRootPath ?? "not-ready"
            normalizeSelectedCardsSection()
            return
        }

        cardsScanGeneration += 1
        let generation = cardsScanGeneration
        isLoadingCards = true

        DispatchQueue.global(qos: .userInitiated).async {
            let discovered = scanPasses()
            DispatchQueue.main.async {
                guard generation == cardsScanGeneration else {
                    return
                }

                detectedCardsRoot = discovered.cardsRoot ?? "not-detected"
                exploit.setDetectedCardsRootPath(discovered.cardsRoot)
                paymentCards = discovered.paymentCards
                walletPasses = discovered.walletPasses
                isLoadingCards = false
                normalizeSelectedCardsSection()
            }
        }
    }

    private func scanPasses() -> PassScanResult {
        guard let cardsRoot = discoverCardsRoot() else {
            return PassScanResult(cardsRoot: nil, paymentCards: [], walletPasses: [])
        }

        var paymentCards = [Card]()
        var otherPasses = [Card]()

        let bundles = collectCardBundles(in: cardsRoot)
        scanLog(
            "final scan root=\(cardsRoot) payment=\(bundles.filter { $0.kind == .paymentCard }.count)" +
            " membership=\(bundles.filter { $0.displayCategory == .membershipCards }.count)" +
            " store=\(bundles.filter { $0.displayCategory == .storeCards }.count)" +
            " event=\(bundles.filter { $0.displayCategory == .eventTickets }.count)" +
            " boarding=\(bundles.filter { $0.displayCategory == .boardingPasses }.count)" +
            " other=\(bundles.filter { $0.displayCategory == .otherPasses }.count)" +
            " archived=\(bundles.filter { $0.isVoided || (($0.expirationDate ?? $0.relevantDate) ?? .distantFuture) < Date() }.count)"
        )

        for bundle in bundles {
            let card = Card(
                imagePath: bundle.backgroundFileName.map { joinPath(bundle.directoryPath, $0) } ?? joinPath(bundle.directoryPath, "pass.json"),
                directoryPath: bundle.directoryPath,
                bundleName: bundle.bundleName,
                backgroundFileName: bundle.backgroundFileName,
                kind: bundle.kind,
                passStyle: bundle.passStyle,
                displayCategory: bundle.displayCategory,
                expirationDate: bundle.expirationDate,
                relevantDate: bundle.relevantDate,
                isVoided: bundle.isVoided
            )

            switch bundle.kind {
            case .paymentCard:
                paymentCards.append(card)
            case .walletPass:
                otherPasses.append(card)
            }
        }

        return PassScanResult(
            cardsRoot: cardsRoot,
            paymentCards: paymentCards.sorted { $0.bundleName.localizedCaseInsensitiveCompare($1.bundleName) == .orderedAscending },
            walletPasses: otherPasses.sorted {
                if $0.displayCategory != $1.displayCategory {
                    return WalletDisplayCategory.allCases.firstIndex(of: $0.displayCategory) ?? 0
                        < WalletDisplayCategory.allCases.firstIndex(of: $1.displayCategory) ?? 0
                }
                return $0.bundleName.localizedCaseInsensitiveCompare($1.bundleName) == .orderedAscending
            }
        )
    }

    private func refreshOffsetInputFromState() {
        if exploit.hasKernprocOffset {
            offsetInput = String(format: "0x%llx", exploit.kernprocOffset)
        } else {
            offsetInput = ""
        }
    }

    private func refreshExploitTabState() {
        exploit.refreshAccessProbe()
        if !exploit.prefersDirectAccessMode {
            exploit.refreshKernprocOffsetState()
        }
        detectedCardsRoot = exploit.detectedCardsRootPath ?? "not-detected"
        refreshOffsetInputFromState()
    }

    private func recheckAndReload() {
        hasAttemptedInitialScan = true
        exploit.refreshAccessProbe()
        if !exploit.prefersDirectAccessMode {
            exploit.refreshKernprocOffsetState()
        }
        loadCards()
    }

    private func runAllAndReload() {
        exploit.runAll { _ in
            recheckAndReload()
            if !hasAnyWalletItems {
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

                if isLoadingCards {
                    ProgressView("Scanning Wallet bundles…")
                        .tint(.white)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 4)
                }

                if !hasAttemptedInitialScan {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("Wallet scan is manual on launch")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("This avoids hanging the first frame while Cardio probes or scans the Wallet bundle tree.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Button("Scan Wallet") {
                            recheckAndReload()
                        }
                        .foregroundColor(.cyan)

                        Button(exploit.accessTabTitle) {
                            selectedTab = 3
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()
                } else if !canScanWalletItems {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "lock.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("Wallet scan unavailable")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text(exploit.blockedReason)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        if !exploit.prefersDirectAccessMode {
                            Button("Open Exploit") {
                                selectedTab = 3
                            }
                            .foregroundColor(.cyan)
                        } else {
                            Button(exploit.accessTabTitle) {
                                selectedTab = 3
                            }
                            .foregroundColor(.cyan)
                        }

                        Button("Retry") {
                            recheckAndReload()
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()
                } else if hasVisibleWalletItems {
                    Text(selectedCardsSection.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(selectedCardsSection.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    if shouldShowCardsSectionPicker {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableCardsSections) { section in
                                    Button {
                                        selectedCardsSection = section
                                    } label: {
                                        Text(section.title)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedCardsSection == section ? .black : .white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedCardsSection == section ? Color.white : Color.white.opacity(0.12))
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Toggle(isOn: $hideArchivedWalletItems) {
                        Text("Hide Expired")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .toggleStyle(.switch)
                    .tint(.cyan)
                    .padding(.horizontal, 16)

                    TabView {
                        ForEach(visibleCards) { card in
                            CardView(
                                card: card,
                                exploit: exploit,
                                onOpenBundleEditor: { selectedCard in
                                    bundleEditorCard = selectedCard
                                }
                            )
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: cardsPageHeight)

                    Button("cards_refresh") {
                        loadCards()
                        if !hasAnyWalletItems {
                            showNoCardsError = true
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.top, 16)
                } else if hasAnyWalletItems {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("No active Wallet items")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("All scanned passes are currently hidden by the expired-pass filter.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Toggle(isOn: $hideArchivedWalletItems) {
                            Text("Hide Expired")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .toggleStyle(.switch)
                        .tint(.cyan)
                        .padding(.horizontal, 32)

                        Button("cards_refresh") {
                            loadCards()
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()
                } else {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "creditcard.trianglebadge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("cards_none_found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)

                        Text(String(format: L("cards_path_label"), detectedCardsRoot))
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
                            if !hasAnyWalletItems {
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
                    message: Text(String(format: L("cards_last_root"), detectedCardsRoot))
                )
            }
        }
        .overlay(alignment: .topTrailing) {
            languageMenu
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
    }

    // MARK: - Language Menu

    private var languageMenu: some View {
        Menu {
            Button {
                langMgr.currentLanguage = "system"
            } label: {
                HStack {
                    Text("🌐  " + L("settings_system_language"))
                    if langMgr.currentLanguage == "system" {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(LanguageManager.supportedLanguages) { lang in
                Button {
                    langMgr.currentLanguage = lang.id
                } label: {
                    HStack {
                        Text(lang.name)
                        if langMgr.currentLanguage == lang.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
                .padding(8)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }

    // MARK: - Exploit Tab

    private var directAccessTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Direct Access")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(exploit.statusMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(exploit.canApplyCardChanges ? .green : .orange)

                    Group {
                        Text("runtime_mode=direct")
                        Text(exploit.entitlementSummary)
                        Text("cards_root=\(detectedCardsRoot)")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 10) {
                        Button("Retry Access Probe") {
                            refreshExploitTabState()
                        }
                        .foregroundColor(.cyan)

                        Button("Scan Wallet") {
                            recheckAndReload()
                        }
                        .foregroundColor(.white)
                    }

                    Button("exploit_copy_logs") {
                        UIPasteboard.general.string = buildLogExportText()
                        exploit.addLog("[scan] logs copied to clipboard")
                    }
                    .foregroundColor(.white)

                    Text(exploit.logText.isEmpty ? L("exploit_no_logs") : exploit.logText)
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
                        TextField(L("exploit_offset_placeholder"), text: $offsetInput)
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
                        Button(exploit.xpfResolving ? L("exploit_resolving") : L("exploit_resolve_offsets")) {
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
                        Button(exploit.darkswordRunning ? L("exploit_running") : L("exploit_run_darksword")) {
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

                    Text(exploit.logText.isEmpty ? L("exploit_no_logs") : exploit.logText)
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
            Group {
                if selectedTab == 0 {
                    cardsTab
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("tab_cards")
                }
                .tag(0)

            Group {
                if selectedTab == 1 {
                    MyCardsView(exploit: exploit, cards: paymentCards)
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
                .tabItem {
                    Image(systemName: "tray.full.fill")
                    Text("tab_mycards")
                }
                .tag(1)

            Group {
                if selectedTab == 2 {
                    CommunityView()
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
                .tabItem {
                    Image(systemName: "globe")
                    Text("tab_community")
                }
                .tag(2)

            Group {
                if selectedTab == 3 {
                    if exploit.prefersDirectAccessMode {
                        directAccessTab
                    } else {
                        exploitTab
                    }
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
                .tabItem {
                    Image(systemName: exploit.accessTabSystemImage)
                    Text(exploit.accessTabTitle)
                }
                .tag(3)

            NFCEmulationView()
                .tabItem {
                    Image(systemName: "wave.3.right.circle")
                    Text("NFC")
                }
                .tag(4)
        }
        .onReceive(NotificationCenter.default.publisher(for: .cardioSelectTab)) { notif in
            if let tab = notif.object as? Int { selectedTab = tab }
        }
        .environment(\.locale, langMgr.locale)
        .accentColor(.white)
        .onAppear {
            // Dark tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(white: 0.08, alpha: 1)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            refreshOffsetInputFromState()
            normalizeSelectedCardsSection()
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 3 {
                refreshExploitTabState()
            }
            if newTab == 4 {
                // NFC tab selected — daemon observes ExploitManager automatically
            }
        }
        .onChange(of: hideArchivedWalletItems) { _ in
            normalizeSelectedCardsSection()
        }
        .sheet(item: $bundleEditorCard) { card in
            CardView(
                card: card,
                exploit: exploit,
                embeddedBundleEditor: true,
                onDismissBundleEditor: {
                    bundleEditorCard = nil
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
