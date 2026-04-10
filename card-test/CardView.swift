import SwiftUI
import UIKit
import PDFKit

enum CardKind {
    case paymentCard
    case walletPass
}

enum WalletDisplayCategory: String, CaseIterable, Identifiable {
    case paymentCards
    case membershipCards
    case storeCards
    case eventTickets
    case boardingPasses
    case otherPasses

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .paymentCards:
            return "Payment"
        case .membershipCards:
            return "Membership"
        case .storeCards:
            return "Store"
        case .eventTickets:
            return "Event"
        case .boardingPasses:
            return "Boarding"
        case .otherPasses:
            return "Other"
        }
    }

    var subtitle: String {
        switch self {
        case .paymentCards:
            return "Apple Pay and payment card designs."
        case .membershipCards:
            return "Membership, loyalty, rewards, and status passes."
        case .storeCards:
            return "Gift, retail, and store-issued passes."
        case .eventTickets:
            return "Concert, sports, cinema, and entry passes."
        case .boardingPasses:
            return "Travel and transit passes."
        case .otherPasses:
            return "Generic and coupon-style Wallet passes."
        }
    }

    var pageHeight: CGFloat {
        switch self {
        case .paymentCards:
            return 340
        case .membershipCards:
            return 480
        case .storeCards:
            return 430
        case .eventTickets:
            return 450
        case .boardingPasses:
            return 410
        case .otherPasses:
            return 460
        }
    }

    var previewCanvasHeight: CGFloat {
        switch self {
        case .paymentCards:
            return 200
        case .membershipCards:
            return 340
        case .storeCards:
            return 300
        case .eventTickets:
            return 312
        case .boardingPasses:
            return 268
        case .otherPasses:
            return 320
        }
    }
}

enum WalletPassStyle: String, CaseIterable {
    case storeCard
    case generic
    case coupon
    case eventTicket
    case boardingPass

    static func detect(in json: [String: Any]) -> WalletPassStyle? {
        for style in allCases where json[style.rawValue] as? [String: Any] != nil {
            return style
        }
        return nil
    }

    var label: String {
        switch self {
        case .storeCard:
            return "Store Card"
        case .generic:
            return "Generic Pass"
        case .coupon:
            return "Coupon"
        case .eventTicket:
            return "Event Ticket"
        case .boardingPass:
            return "Boarding Pass"
        }
    }

    var displayCategory: WalletDisplayCategory {
        switch self {
        case .storeCard:
            return .storeCards
        case .eventTicket:
            return .eventTickets
        case .boardingPass:
            return .boardingPasses
        case .generic, .coupon:
            return .otherPasses
        }
    }

    var previewCanvasHeight: CGFloat {
        switch self {
        case .storeCard:
            return 330
        case .eventTicket:
            return 312
        case .boardingPass:
            return 268
        case .generic, .coupon:
            return 320
        }
    }
}

struct Card: Identifiable {
    var imagePath: String
    var directoryPath: String
    var bundleName: String
    var backgroundFileName: String?
    var kind: CardKind
    var passStyle: WalletPassStyle?
    var displayCategory: WalletDisplayCategory
    var expirationDate: Date?
    var relevantDate: Date?
    var isVoided: Bool

    var id: String {
        directoryPath
    }

    var displayName: String {
        CardNicknameManager.shared.nickname(for: directoryPath) ?? bundleName
    }

    var preferredPageHeight: CGFloat {
        displayCategory.pageHeight
    }

    var previewCanvasHeight: CGFloat {
        displayCategory.previewCanvasHeight
    }

    var isArchivedLikeWallet: Bool {
        guard kind == .walletPass else {
            return false
        }

        if isVoided {
            return true
        }

        let referenceDate = expirationDate ?? relevantDate
        if let referenceDate {
            return referenceDate < Date()
        }

        return false
    }
}

// MARK: - Nickname Manager

final class CardNicknameManager {
    static let shared = CardNicknameManager()
    private let key = "cardio.card.nicknames"

    private var cache: [String: String]

    private init() {
        cache = (UserDefaults.standard.dictionary(forKey: key) as? [String: String]) ?? [:]
    }

    func nickname(for directoryPath: String) -> String? {
        cache[directoryPath]
    }

    func setNickname(_ name: String?, for directoryPath: String) {
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            cache[directoryPath] = name.trimmingCharacters(in: .whitespaces)
        } else {
            cache.removeValue(forKey: directoryPath)
        }
        UserDefaults.standard.set(cache, forKey: key)
    }
}

private struct CardMetadataFile: Identifiable, Hashable {
    enum Kind {
        case json
        case text
        case image
        case pdf
    }

    let path: String
    let relativePath: String
    let kind: Kind

    var id: String {
        path
    }
}

private extension CardMetadataFile.Kind {
    var label: String {
        switch self {
        case .json:
            return "JSON"
        case .text:
            return "Text"
        case .image:
            return "Image"
        case .pdf:
            return "PDF"
        }
    }

    var supportsTextEditing: Bool {
        switch self {
        case .json, .text:
            return true
        case .image, .pdf:
            return false
        }
    }

    var supportsAssetReplacement: Bool {
        switch self {
        case .image, .pdf:
            return true
        case .json, .text:
            return false
        }
    }
}

private struct DecodedCardMetadataText {
    let text: String
    let encoding: String.Encoding
}

struct ImportedBundleAsset {
    let data: Data
    let fileName: String
}

private struct WalletPassField: Identifiable {
    let id: String
    let label: String
    let value: String
}

private struct WalletPassPreviewData {
    let title: String
    let subtitle: String?
    let style: WalletPassStyle
    let backgroundColor: Color
    let foregroundColor: Color
    let labelColor: Color
    let backgroundImage: UIImage?
    let stripImage: UIImage?
    let thumbnailImage: UIImage?
    let logoImage: UIImage?
    let iconImage: UIImage?
    let headerFields: [WalletPassField]
    let primaryFields: [WalletPassField]
    let secondaryFields: [WalletPassField]
    let auxiliaryFields: [WalletPassField]
}

private enum WalletCacheArtifact: String, CaseIterable {
    case frontFace = "FrontFace"
    case preview = "Preview"
    case placeHolder = "PlaceHolder"
}

private struct PaymentCardCacheRenderData {
    let brandName: String
    let productName: String?
    let suffix: String?
    let foregroundColor: UIColor
    let labelColor: UIColor
    let backgroundColor: UIColor
}

private let helper = ObjcHelper()

struct CardView: View {
    let fm = FileManager.default
    let card: Card
    @ObservedObject var exploit: ExploitManager
    var embeddedBundleEditor = false
    var onOpenBundleEditor: ((Card) -> Void)? = nil
    var onDismissBundleEditor: (() -> Void)? = nil

    @State private var cardImage = UIImage()
    @State private var bundleAssetImage = UIImage()
    @State private var showSheet = false
    @State private var showDocPicker = false
    @State private var showBundleImagePicker = false
    @State private var showBundleAssetDocumentPicker = false
    @State private var showBundleAssetSourcePicker = false
    @State private var showSourcePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var imageVersion = 0          // bump to force re-render
    @State private var showSaved = false
    @State private var successMessage = ""
    @State private var showNicknameEditor = false
    @State private var nicknameInput = ""
    @State private var showCardNumberEditor = false
    @State private var cardNumberInput = ""
    @State private var currentCardNumber = ""
    @State private var metadataFiles: [CardMetadataFile] = []
    @State private var selectedMetadataPath = ""
    @State private var metadataEditorText = ""
    @State private var metadataEditorEncoding = String.Encoding.utf8
    @State private var metadataStatusMessage = ""
    @State private var pendingBundleAssetPath = ""
    @State private var paymentCardPreviewImage: UIImage?
    @State private var walletPassPreviewData: WalletPassPreviewData?

    private var cardDirectoryPath: String {
        return card.directoryPath
    }

    private var targetPath: String? {
        guard let backgroundFileName = card.backgroundFileName else {
            return nil
        }
        return cardDirectoryPath + "/" + backgroundFileName
    }

    private var backupPath: String? {
        guard let targetPath else {
            return nil
        }
        return targetPath + ".backup"
    }

    private var cachePaths: [String] {
        var candidates = [cardDirectoryPath + ".cache"]

        let normalized = (cardDirectoryPath as NSString).deletingPathExtension + ".cache"
        if normalized != candidates[0] {
            candidates.append(normalized)
        }

        var unique: [String] = []
        for path in candidates where !unique.contains(path) {
            unique.append(path)
        }
        return unique
    }

    private var selectedMetadataFile: CardMetadataFile? {
        metadataFiles.first { $0.path == selectedMetadataPath }
    }

    private var presentedMetadataFile: CardMetadataFile? {
        selectedMetadataFile ?? metadataFiles.first
    }

    private var metadataPickerSelection: Binding<String> {
        Binding(
            get: {
                presentedMetadataFile?.path ?? ""
            },
            set: { newPath in
                if let file = metadataFiles.first(where: { $0.path == newPath }) {
                    selectMetadataFile(file)
                } else {
                    selectedMetadataPath = newPath
                }
            }
        )
    }

    private func relativeBundlePath(for path: String) -> String {
        metadataFiles.first(where: { $0.path == path })?.relativePath ?? URL(fileURLWithPath: path).lastPathComponent
    }

    private func backupPath(for path: String) -> String {
        path + ".backup"
    }

    private func isCacheFilePath(_ path: String) -> Bool {
        cachePaths.contains { cacheRoot in
            path == cacheRoot || path.hasPrefix(cacheRoot + "/")
        }
    }

    private func relativePathInPrimaryBundle(for absolutePath: String) -> String? {
        let prefix = cardDirectoryPath.hasSuffix("/") ? cardDirectoryPath : cardDirectoryPath + "/"
        guard absolutePath.hasPrefix(prefix) else {
            return nil
        }
        return String(absolutePath.dropFirst(prefix.count))
    }

    private func editableBundleRoots() -> [(path: String, prefix: String)] {
        var roots: [(path: String, prefix: String)] = [(cardDirectoryPath, "")]

        for cachePath in cachePaths where fileExists(atPath: cachePath) {
            roots.append((cachePath, ".cache/"))
        }

        return roots
    }

    private func matchingCacheCounterparts(for absolutePath: String) -> [String] {
        guard !isCacheFilePath(absolutePath),
              let relativePath = relativePathInPrimaryBundle(for: absolutePath) else {
            return []
        }

        var matches: [String] = []
        for cachePath in cachePaths {
            let candidate = joinPath(cachePath, relativePath)
            if fileExists(atPath: candidate), !matches.contains(candidate) {
                matches.append(candidate)
            }
        }
        return matches
    }

    private func writeBundleData(_ data: Data, to absolutePath: String, shouldInvalidateCache: Bool) throws {
        try exploit.overwriteWalletFile(targetPath: absolutePath, data: data)

        let cacheCounterparts = matchingCacheCounterparts(for: absolutePath)
        for cachePath in cacheCounterparts {
            try backupFileIfNeeded(at: cachePath, maxSize: max(Int64(data.count * 2), 512 * 1024))
            try exploit.overwriteWalletFile(targetPath: cachePath, data: data)
        }

        if shouldInvalidateCache && cacheCounterparts.isEmpty {
            removeCacheIfPresent()
        }
    }

    private var hasImageBackup: Bool {
        guard card.kind == .paymentCard, let backupPath else {
            return false
        }
        return fileExists(atPath: backupPath) || imageVersion > 0
    }

    private var baseDisplayName: String {
        switch card.kind {
        case .paymentCard:
            return card.bundleName
        case .walletPass:
            return walletPassPreviewData?.title ?? card.bundleName
        }
    }

    private var visibleDisplayName: String {
        CardNicknameManager.shared.nickname(for: card.directoryPath) ?? baseDisplayName
    }

    private var walletPreviewSize: CGSize {
        CGSize(width: 320, height: card.previewCanvasHeight)
    }

    private func removeCacheIfPresent() {
        for cachePath in cachePaths {
            for variant in pathVariants(for: cachePath) where fm.fileExists(atPath: variant) {
                try? fm.removeItem(atPath: variant)
            }
        }
    }

    private func backupFileIfNeeded(at path: String, maxSize: Int64 = 16 * 1024 * 1024) throws {
        guard exploit.directWriteReady || exploit.canApplyCardChanges else {
            return
        }

        let backupPath = backupPath(for: path)
        guard !fileExists(atPath: backupPath) else {
            return
        }

        guard let originalData = readFileData(at: path, maxSize: maxSize) else {
            throw NSError(
                domain: "CardioBundleEditor",
                code: 3201,
                userInfo: [NSLocalizedDescriptionKey: "Could not back up \(relativeBundlePath(for: path))."]
            )
        }

        try exploit.overwriteWalletFile(targetPath: backupPath, data: originalData)
    }

    private func backupCurrentIfNeeded() throws {
        guard let targetPath else {
            return
        }

        try backupFileIfNeeded(at: targetPath)
    }

    private func imageFromData(_ data: Data, path: String) -> UIImage? {
        let lower = path.lowercased()
        if lower.hasSuffix(".pdf") {
            if let doc = PDFDocument(data: data),
               let page = doc.page(at: 0) {
                return page.thumbnail(of: CGSize(width: 640, height: 400), for: .cropBox)
            }
            return nil
        }
        return UIImage(data: data)
    }

    private func loadImage(atPath path: String, maxSize: Int64 = 8 * 1024 * 1024) -> UIImage? {
        if let data = readFileData(at: path, maxSize: maxSize) {
            return imageFromData(data, path: path)
        }

        if path.lowercased().hasSuffix(".pdf"),
           let doc = PDFDocument(url: URL(fileURLWithPath: path)),
           let page = doc.page(at: 0) {
            return page.thumbnail(of: CGSize(width: 640, height: 400), for: .cropBox)
        }

        return UIImage(contentsOfFile: path)
    }

    private func loadPaymentCardPreviewImage() -> UIImage? {
        guard card.kind == .paymentCard else {
            return nil
        }
        return loadImage(atPath: card.imagePath)
    }

    private func uiColor(from value: Any?, fallback: UIColor) -> UIColor {
        if let value = value as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("#") {
                let hex = String(trimmed.dropFirst())
                if hex.count == 6, let number = UInt64(hex, radix: 16) {
                    return UIColor(
                        red: CGFloat((number >> 16) & 0xff) / 255.0,
                        green: CGFloat((number >> 8) & 0xff) / 255.0,
                        blue: CGFloat(number & 0xff) / 255.0,
                        alpha: 1.0
                    )
                }
            }

            let digitSet = CharacterSet(charactersIn: "0123456789., ")
            if trimmed.lowercased().hasPrefix("rgb"),
               let start = trimmed.firstIndex(of: "("),
               let end = trimmed.lastIndex(of: ")") {
                let componentsString = trimmed[trimmed.index(after: start)..<end]
                let sanitized = String(componentsString).components(separatedBy: digitSet.inverted).joined()
                let components = sanitized
                    .split(separator: ",")
                    .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

                if components.count >= 3 {
                    let alpha = components.count >= 4 ? components[3] : 1.0
                    return UIColor(
                        red: components[0] / 255.0,
                        green: components[1] / 255.0,
                        blue: components[2] / 255.0,
                        alpha: alpha > 1.0 ? alpha / 255.0 : alpha
                    )
                }
            }
        }

        return fallback
    }

    private func loadPaymentCardCacheRenderData() -> PaymentCardCacheRenderData {
        let json = readPassJson().flatMap { data in
            try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } ?? [:]

        let brandName = ((json["logoText"] as? String)
            ?? (json["organizationName"] as? String)
            ?? card.bundleName)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let rawProductName = (json["description"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let productName = rawProductName?.localizedCaseInsensitiveCompare(brandName) == .orderedSame ? nil : rawProductName

        return PaymentCardCacheRenderData(
            brandName: brandName,
            productName: productName,
            suffix: (json["primaryAccountSuffix"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
            foregroundColor: uiColor(from: json["foregroundColor"], fallback: .white),
            labelColor: uiColor(from: json["labelColor"], fallback: .white),
            backgroundColor: uiColor(from: json["backgroundColor"], fallback: UIColor(white: 0.12, alpha: 1))
        )
    }

    private func paymentCardCacheRenderSize(for baseImage: UIImage?) -> CGSize {
        if let cgImage = baseImage?.cgImage {
            return CGSize(width: cgImage.width, height: cgImage.height)
        }

        if let targetPath, targetPath.lowercased().contains("@3x") {
            return CGSize(width: 2304, height: 1452)
        }

        return CGSize(width: 1536, height: 969)
    }

    private func drawPaymentCardText(
        _ text: String,
        in rect: CGRect,
        color: UIColor,
        font: UIFont,
        alignment: NSTextAlignment,
        context: CGContext
    ) {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = max(4, rect.height * 0.08)
        shadow.shadowOffset = CGSize(width: 0, height: max(2, rect.height * 0.02))
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.35)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .shadow: shadow
        ]

        context.saveGState()
        NSAttributedString(string: text, attributes: attributes).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
        context.restoreGState()
    }

    private func renderedPaymentCardCacheImage() -> UIImage? {
        guard card.kind == .paymentCard else {
            return nil
        }

        let baseImage = paymentCardPreviewImage ?? loadPaymentCardPreviewImage()
        let renderData = loadPaymentCardCacheRenderData()
        let renderSize = paymentCardCacheRenderSize(for: baseImage)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            let bounds = CGRect(origin: .zero, size: renderSize)

            context.setFillColor(renderData.backgroundColor.cgColor)
            context.fill(bounds)

            if let baseImage {
                baseImage.draw(in: bounds)
            }

            if let topGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.black.withAlphaComponent(0.18).cgColor,
                    UIColor.clear.cgColor
                ] as CFArray,
                locations: [0, 1]
            ) {
                context.drawLinearGradient(
                    topGradient,
                    start: CGPoint(x: bounds.midX, y: 0),
                    end: CGPoint(x: bounds.midX, y: bounds.height * 0.2),
                    options: []
                )
            }

            if let bottomGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.clear.cgColor,
                    UIColor.black.withAlphaComponent(0.28).cgColor
                ] as CFArray,
                locations: [0, 1]
            ) {
                context.drawLinearGradient(
                    bottomGradient,
                    start: CGPoint(x: bounds.midX, y: bounds.height * 0.72),
                    end: CGPoint(x: bounds.midX, y: bounds.height),
                    options: []
                )
            }

            let leftInset = bounds.width * 0.065
            let rightInset = bounds.width * 0.065

            let brandRect = CGRect(
                x: leftInset,
                y: bounds.height * 0.07,
                width: bounds.width - leftInset - rightInset,
                height: bounds.height * 0.14
            )
            drawPaymentCardText(
                renderData.brandName.uppercased(),
                in: brandRect,
                color: renderData.foregroundColor,
                font: .systemFont(ofSize: bounds.height * 0.082, weight: .bold),
                alignment: .left,
                context: context
            )

            if let productName = renderData.productName, !productName.isEmpty {
                let productRect = CGRect(
                    x: leftInset,
                    y: brandRect.maxY + bounds.height * 0.01,
                    width: bounds.width * 0.58,
                    height: bounds.height * 0.1
                )
                drawPaymentCardText(
                    productName,
                    in: productRect,
                    color: renderData.labelColor.withAlphaComponent(0.94),
                    font: .systemFont(ofSize: bounds.height * 0.046, weight: .semibold),
                    alignment: .left,
                    context: context
                )
            }

            if let suffix = renderData.suffix, !suffix.isEmpty {
                let labelRect = CGRect(
                    x: leftInset,
                    y: bounds.height * 0.82,
                    width: bounds.width * 0.22,
                    height: bounds.height * 0.05
                )
                drawPaymentCardText(
                    "CARD",
                    in: labelRect,
                    color: renderData.labelColor.withAlphaComponent(0.88),
                    font: .systemFont(ofSize: bounds.height * 0.032, weight: .semibold),
                    alignment: .left,
                    context: context
                )

                let suffixRect = CGRect(
                    x: leftInset,
                    y: labelRect.maxY + bounds.height * 0.006,
                    width: bounds.width * 0.3,
                    height: bounds.height * 0.08
                )
                drawPaymentCardText(
                    "•••• \(suffix)",
                    in: suffixRect,
                    color: renderData.labelColor,
                    font: .monospacedDigitSystemFont(ofSize: bounds.height * 0.055, weight: .bold),
                    alignment: .left,
                    context: context
                )
            }
        }
    }

    private func assetCandidateNames(for baseName: String) -> [String] {
        let fileManager = FileManager.default
        let exactCandidates = [
            "\(baseName)@3x.png",
            "\(baseName)@2x.png",
            "\(baseName).png",
            "\(baseName)@3x.jpg",
            "\(baseName)@2x.jpg",
            "\(baseName).jpg",
            "\(baseName)@3x.jpeg",
            "\(baseName)@2x.jpeg",
            "\(baseName).jpeg",
            "\(baseName).pdf"
        ]

        let entries = (try? fileManager.contentsOfDirectory(atPath: cardDirectoryPath)) ?? listDirectory(cardDirectoryPath)
        let baseLower = baseName.lowercased()
        let discovered = entries
            .filter { entry in
                let lower = entry.lowercased()
                return lower.hasPrefix(baseLower)
                    && (lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".pdf"))
            }
            .sorted {
                let lhs = $0.lowercased()
                let rhs = $1.lowercased()
                func rank(_ name: String) -> Int {
                    if name.contains("@3x") { return 0 }
                    if name.contains("@2x") { return 1 }
                    if name.hasSuffix(".png") { return 2 }
                    if name.hasSuffix(".jpg") || name.hasSuffix(".jpeg") { return 3 }
                    return 4
                }
                let lhsRank = rank(lhs)
                let rhsRank = rank(rhs)
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }
                return lhs < rhs
            }

        var combined: [String] = []
        for name in exactCandidates + discovered where !combined.contains(name) {
            combined.append(name)
        }
        return combined
    }

    private func loadPassAssetImage(named baseName: String) -> UIImage? {
        for candidate in assetCandidateNames(for: baseName) {
            let path = joinPath(cardDirectoryPath, candidate)
            if let image = loadImage(atPath: path) {
                return image
            }
        }
        return nil
    }

    private func reloadPreviewContent() {
        switch card.kind {
        case .paymentCard:
            paymentCardPreviewImage = loadPaymentCardPreviewImage()
            walletPassPreviewData = nil
        case .walletPass:
            walletPassPreviewData = loadWalletPassPreviewData()
            paymentCardPreviewImage = nil
        }
    }

    private func guardWriteAccessOrShowError() -> Bool {
        if exploit.canApplyCardChanges {
            return true
        }

        errorMessage = exploit.blockedReason
        showError = true
        return false
    }

    private func joinPath(_ parent: String, _ child: String) -> String {
        if parent.hasSuffix("/") {
            return parent + child
        }
        return parent + "/" + child
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
        for variant in pathVariants(for: path) {
            if let direct = try? fm.contentsOfDirectory(atPath: variant) {
                return direct
            }
        }

        for variant in pathVariants(for: path) {
            _ = access(variant, F_OK)
        }

        for variant in pathVariants(for: path) {
            let entries = helper.directListDirectory(variant)
            if !entries.isEmpty {
                return entries
            }
        }

        for variant in pathVariants(for: path) {
            let entries = helper.kfsListDirectory(variant)
            if !entries.isEmpty {
                return entries
            }
        }

        return []
    }

    private func fileExists(atPath path: String) -> Bool {
        for variant in pathVariants(for: path) {
            if fm.fileExists(atPath: variant) {
                return true
            }
        }

        for variant in pathVariants(for: path) {
            if access(variant, F_OK) == 0 {
                return true
            }
        }

        for variant in pathVariants(for: path) {
            if helper.kfsFileSizeNC(variant) >= 0 {
                return true
            }
        }

        return false
    }

    private func readFileData(at path: String, maxSize: Int64 = 1024 * 1024) -> Data? {
        for variant in pathVariants(for: path) {
            if let data = fm.contents(atPath: variant) {
                return data
            }
        }

        for variant in pathVariants(for: path) {
            _ = access(variant, R_OK)
        }

        for variant in pathVariants(for: path) {
            if let data = helper.directReadFile(variant, maxSize: maxSize) {
                return data
            }
        }

        for variant in pathVariants(for: path) {
            if let data = helper.kfsReadFile(variant, maxSize: maxSize) {
                return data
            }
        }

        return nil
    }

    private func unescapeStringTableToken(_ token: String) -> String {
        token
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    private func parseStringTable(_ data: Data) -> [String: String] {
        if let dictionary = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] {
            return dictionary
        }

        guard let text = decodeText(data)?.text else {
            return [:]
        }

        let pattern = #""((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [:]
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var table: [String: String] = [:]

        for match in regex.matches(in: text, range: range) where match.numberOfRanges == 3 {
            guard let keyRange = Range(match.range(at: 1), in: text),
                  let valueRange = Range(match.range(at: 2), in: text) else {
                continue
            }

            let key = unescapeStringTableToken(String(text[keyRange]))
            let value = unescapeStringTableToken(String(text[valueRange]))
            table[key] = value
        }

        return table
    }

    private func preferredPassStringsPaths() -> [String] {
        let entries = listDirectory(cardDirectoryPath)
        var paths: [String] = []

        let rootStrings = joinPath(cardDirectoryPath, "pass.strings")
        if fileExists(atPath: rootStrings) {
            paths.append(rootStrings)
        }

        let localizationDirectories = entries.filter { $0.lowercased().hasSuffix(".lproj") }
        guard !localizationDirectories.isEmpty else {
            return paths
        }

        let preferredIdentifiers = Locale.preferredLanguages + [Locale.current.identifier]
        var orderedLocalizations: [String] = []

        for identifier in preferredIdentifiers {
            let normalized = identifier.replacingOccurrences(of: "-", with: "_")
            let exact = normalized + ".lproj"
            let languageCode = normalized.split(separator: "_").first.map(String.init)

            if localizationDirectories.contains(exact), !orderedLocalizations.contains(exact) {
                orderedLocalizations.append(exact)
            }

            if let languageCode {
                let languageDirectory = languageCode + ".lproj"
                if localizationDirectories.contains(languageDirectory), !orderedLocalizations.contains(languageDirectory) {
                    orderedLocalizations.append(languageDirectory)
                }
            }
        }

        for fallback in ["Base.lproj", "en.lproj"] where localizationDirectories.contains(fallback) && !orderedLocalizations.contains(fallback) {
            orderedLocalizations.append(fallback)
        }

        for directory in orderedLocalizations {
            let path = joinPath(joinPath(cardDirectoryPath, directory), "pass.strings")
            if fileExists(atPath: path) {
                paths.append(path)
            }
        }

        return paths
    }

    private func loadPassStringsTable() -> [String: String] {
        var table: [String: String] = [:]

        for path in preferredPassStringsPaths() {
            guard let data = readFileData(at: path, maxSize: 256 * 1024) else {
                continue
            }

            for (key, value) in parseStringTable(data) {
                table[key] = value
            }
        }

        return table
    }

    private func localizedPassString(_ rawValue: Any?, stringsTable: [String: String]) -> String? {
        guard let rawString = rawValue as? String else {
            return nil
        }

        let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return stringsTable[trimmed] ?? trimmed
    }

    private func stringifiedPassValue(_ rawValue: Any?, stringsTable: [String: String]) -> String? {
        if let localized = localizedPassString(rawValue, stringsTable: stringsTable) {
            return localized
        }

        if let number = rawValue as? NSNumber {
            return number.stringValue
        }

        if let values = rawValue as? [Any] {
            let joined = values.compactMap { stringifiedPassValue($0, stringsTable: stringsTable) }.joined(separator: " • ")
            return joined.isEmpty ? nil : joined
        }

        if let dictionary = rawValue as? [String: Any] {
            if let summary = localizedPassString(dictionary["message"], stringsTable: stringsTable) {
                return summary
            }
            if let summary = localizedPassString(dictionary["description"], stringsTable: stringsTable) {
                return summary
            }
            if let summary = dictionary["value"] {
                return stringifiedPassValue(summary, stringsTable: stringsTable)
            }
        }

        return nil
    }

    private func passStylePayload(from json: [String: Any]) -> (WalletPassStyle, [String: Any])? {
        if let style = WalletPassStyle.detect(in: json),
           let payload = json[style.rawValue] as? [String: Any] {
            return (style, payload)
        }
        return nil
    }

    private func parsePassFields(_ rawFields: Any?, stringsTable: [String: String]) -> [WalletPassField] {
        guard let fields = rawFields as? [[String: Any]] else {
            return []
        }

        return fields.enumerated().compactMap { index, rawField in
            let key = localizedPassString(rawField["key"], stringsTable: stringsTable) ?? "field-\(index)"
            let label = localizedPassString(rawField["label"], stringsTable: stringsTable) ?? key
            guard let value = stringifiedPassValue(rawField["value"], stringsTable: stringsTable),
                  !value.isEmpty else {
                return nil
            }

            return WalletPassField(
                id: "\(key)-\(index)",
                label: label,
                value: value
            )
        }
    }

    private func color(from rawValue: Any?, fallback: Color) -> Color {
        guard let rawString = localizedPassString(rawValue, stringsTable: [:]) else {
            return fallback
        }

        let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercase = trimmed.lowercased()

        if lowercase.hasPrefix("#") {
            let hex = String(lowercase.dropFirst())
            let scanner = Scanner(string: hex)
            var value: UInt64 = 0
            guard scanner.scanHexInt64(&value) else {
                return fallback
            }

            let red, green, blue, alpha: Double
            switch hex.count {
            case 6:
                red = Double((value & 0xFF0000) >> 16) / 255.0
                green = Double((value & 0x00FF00) >> 8) / 255.0
                blue = Double(value & 0x0000FF) / 255.0
                alpha = 1.0
            case 8:
                red = Double((value & 0xFF000000) >> 24) / 255.0
                green = Double((value & 0x00FF0000) >> 16) / 255.0
                blue = Double((value & 0x0000FF00) >> 8) / 255.0
                alpha = Double(value & 0x000000FF) / 255.0
            default:
                return fallback
            }

            return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        }

        if lowercase.hasPrefix("rgb") {
            let characters = CharacterSet(charactersIn: "0123456789.,").inverted
            let components = trimmed
                .components(separatedBy: characters)
                .joined()
                .split(separator: ",")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

            if components.count >= 3 {
                let alpha = components.count >= 4 ? components[3] : 1.0
                return Color(
                    .sRGB,
                    red: components[0] / 255.0,
                    green: components[1] / 255.0,
                    blue: components[2] / 255.0,
                    opacity: alpha > 1.0 ? alpha / 255.0 : alpha
                )
            }
        }

        return fallback
    }

    private func loadWalletPassPreviewData() -> WalletPassPreviewData? {
        guard let data = readFileData(at: passJsonPath, maxSize: 512 * 1024),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let (style, stylePayload) = passStylePayload(from: json) else {
            return nil
        }

        let stringsTable = loadPassStringsTable()
        let title = localizedPassString(json["logoText"], stringsTable: stringsTable)
            ?? localizedPassString(json["organizationName"], stringsTable: stringsTable)
            ?? localizedPassString(json["description"], stringsTable: stringsTable)
            ?? card.bundleName
        let subtitle = localizedPassString(json["description"], stringsTable: stringsTable)
        let backgroundColor = color(from: json["backgroundColor"], fallback: Color(red: 0.14, green: 0.15, blue: 0.18))
        let foregroundColor = color(from: json["foregroundColor"], fallback: .white)
        let labelColor = color(from: json["labelColor"], fallback: foregroundColor.opacity(0.74))

        return WalletPassPreviewData(
            title: title,
            subtitle: subtitle == title ? nil : subtitle,
            style: style,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            labelColor: labelColor,
            backgroundImage: loadPassAssetImage(named: "background"),
            stripImage: loadPassAssetImage(named: "strip"),
            thumbnailImage: loadPassAssetImage(named: "thumbnail"),
            logoImage: loadPassAssetImage(named: "logo"),
            iconImage: loadPassAssetImage(named: "icon"),
            headerFields: parsePassFields(stylePayload["headerFields"], stringsTable: stringsTable),
            primaryFields: parsePassFields(stylePayload["primaryFields"], stringsTable: stringsTable),
            secondaryFields: parsePassFields(stylePayload["secondaryFields"], stringsTable: stringsTable),
            auxiliaryFields: parsePassFields(stylePayload["auxiliaryFields"], stringsTable: stringsTable)
        )
    }

    private func decodeText(_ data: Data) -> DecodedCardMetadataText? {
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .unicode,
            .ascii
        ]

        for encoding in encodings {
            if let text = String(data: data, encoding: encoding) {
                return DecodedCardMetadataText(text: text, encoding: encoding)
            }
        }

        return nil
    }

    private func metadataBackupPath(for file: CardMetadataFile) -> String {
        backupPath(for: file.path)
    }

    private func discoverMetadataFiles() -> [CardMetadataFile] {
        var files: [CardMetadataFile] = []
        var seen: Set<String> = []

        func appendFile(path: String, relativePath: String) {
            let lower = relativePath.lowercased()
            guard !lower.hasSuffix(".backup") else { return }

            let kind: CardMetadataFile.Kind?
            if lower.hasSuffix(".json") {
                kind = .json
            } else if lower.hasSuffix(".strings") {
                kind = .text
            } else if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") {
                kind = .image
            } else if lower.hasSuffix(".pdf") {
                kind = .pdf
            } else {
                kind = nil
            }

            guard let kind, fileExists(atPath: path), seen.insert(path).inserted else {
                return
            }

            files.append(CardMetadataFile(path: path, relativePath: relativePath, kind: kind))
        }

        for root in editableBundleRoots() {
            for entry in listDirectory(root.path) where entry != "." && entry != ".." {
                let childPath = joinPath(root.path, entry)
                appendFile(path: childPath, relativePath: root.prefix + entry)

                let nestedEntries = listDirectory(childPath)
                for nested in nestedEntries where nested != "." && nested != ".." {
                    appendFile(path: joinPath(childPath, nested), relativePath: root.prefix + "\(entry)/\(nested)")
                }
            }
        }

        return files.sorted { lhs, rhs in
            func rank(_ file: CardMetadataFile) -> Int {
                if file.relativePath == "pass.json" {
                    return 0
                }
                if file.relativePath.hasSuffix("/pass.strings") {
                    return 1
                }
                if file.relativePath.hasPrefix(".cache/") {
                    return 10
                }
                if file.kind == .json {
                    return 2
                }
                if file.kind == .text {
                    return 3
                }
                let lower = file.relativePath.lowercased()
                if lower.contains("cardbackgroundcombined") || lower.contains("background") {
                    return 4
                }
                if lower.contains("strip") {
                    return 5
                }
                if lower.contains("thumbnail") {
                    return 6
                }
                if lower.contains("logo") {
                    return 7
                }
                if lower.contains("icon") {
                    return 8
                }
                return 9
            }

            let lhsRank = rank(lhs)
            let rhsRank = rank(rhs)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.relativePath.localizedCaseInsensitiveCompare(rhs.relativePath) == .orderedAscending
        }
    }

    private func selectMetadataFile(_ file: CardMetadataFile) {
        selectedMetadataPath = file.path
        metadataStatusMessage = ""

        guard file.kind.supportsTextEditing else {
            return
        }

        if loadMetadataEditorText(for: file) {
            return
        }

        // Some protected bundle files only become readable a tick later after the initial directory walk.
        DispatchQueue.main.async {
            guard self.embeddedBundleEditor,
                  self.selectedMetadataPath == file.path else {
                return
            }

            if !self.loadMetadataEditorText(for: file) {
                self.errorMessage = "Could not read \(file.relativePath)."
                self.showError = true
            }
        }
    }

    private func loadMetadataEditorText(for file: CardMetadataFile) -> Bool {
        guard let data = readFileData(at: file.path),
              let decoded = decodeText(data) else {
            return false
        }

        metadataEditorText = decoded.text
        metadataEditorEncoding = decoded.encoding
        return true
    }

    private func ensureMetadataSelection() {
        guard selectedMetadataFile == nil, let fallback = metadataFiles.first else {
            return
        }
        selectMetadataFile(fallback)
    }

    private func warmMetadataEditorAccess() {
        for root in editableBundleRoots() {
            for variant in pathVariants(for: root.path) {
                _ = access(variant, F_OK)
                _ = helper.directListDirectory(variant)
                _ = helper.kfsListDirectory(variant)

                let passJsonCandidate = joinPath(variant, "pass.json")
                _ = helper.directReadFile(passJsonCandidate, maxSize: 8 * 1024)
                _ = helper.kfsReadFile(passJsonCandidate, maxSize: 8 * 1024)
            }
        }
    }

    private func prepareMetadataEditorState(using discoveredFiles: [CardMetadataFile]) {
        metadataFiles = discoveredFiles
        let preferredFile = discoveredFiles.first { $0.relativePath == "pass.json" } ?? discoveredFiles[0]
        selectMetadataFile(preferredFile)
    }

    private func prepareMetadataEditor(attempt: Int = 0) {
        let discoveredFiles = discoverMetadataFiles()
        if !discoveredFiles.isEmpty {
            prepareMetadataEditorState(using: discoveredFiles)
            return
        }

        guard attempt < 2 else {
            errorMessage = "No editable bundle files were found for this card."
            showError = true
            return
        }

        warmMetadataEditorAccess()
        DispatchQueue.main.async {
            self.prepareMetadataEditor(attempt: attempt + 1)
        }
    }

    private func validateMetadataEditorText(for file: CardMetadataFile) throws {
        guard file.kind == .json else {
            return
        }

        do {
            _ = try JSONSerialization.jsonObject(with: Data(metadataEditorText.utf8))
        } catch {
            throw NSError(
                domain: "CardioMetadataEditor",
                code: 3101,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON in \(file.relativePath)."]
            )
        }
    }

    private func saveMetadataEditor() {
        guard let file = selectedMetadataFile else {
            return
        }

        guard file.kind.supportsTextEditing else {
            return
        }

        do {
            try validateMetadataEditorText(for: file)
            try backupFileIfNeeded(at: file.path, maxSize: 512 * 1024)

            let updatedData = metadataEditorText.data(using: metadataEditorEncoding)
                ?? metadataEditorText.data(using: .utf8)
                ?? Data(metadataEditorText.utf8)

            try writeBundleData(updatedData, to: file.path, shouldInvalidateCache: !isCacheFilePath(file.path))
            helper.refreshWalletServices()
            reloadPreviewContent()

            if file.path == passJsonPath {
                currentCardNumber = readCardNumber() ?? ""
            }

            metadataStatusMessage = "Saved \(file.relativePath)"
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restoreMetadataEditor() {
        guard let file = selectedMetadataFile else {
            return
        }

        let backupPath = metadataBackupPath(for: file)
        let maxSize: Int64 = file.kind.supportsTextEditing ? 512 * 1024 : 16 * 1024 * 1024
        guard let backupData = readFileData(at: backupPath, maxSize: maxSize) else {
            errorMessage = "No backup found for \(file.relativePath)."
            showError = true
            return
        }

        do {
            try writeBundleData(backupData, to: file.path, shouldInvalidateCache: !isCacheFilePath(file.path))
            helper.refreshWalletServices()
            reloadPreviewContent()

            if file.kind.supportsTextEditing,
               let decoded = decodeText(backupData) {
                metadataEditorText = decoded.text
                metadataEditorEncoding = decoded.encoding
            }
            if file.path == passJsonPath {
                currentCardNumber = readCardNumber() ?? ""
            }

            metadataStatusMessage = "Restored \(file.relativePath)"
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - pass.json card number editing

    private var passJsonPath: String {
        cardDirectoryPath + "/pass.json"
    }

    private var passJsonBackupPath: String {
        cardDirectoryPath + "/pass.json.backup"
    }

    private func readPassJson() -> Data? {
        readFileData(at: passJsonPath, maxSize: 512 * 1024)
    }

    private func readCardNumber() -> String? {
        guard let data = readPassJson(),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let suffix = json["primaryAccountSuffix"] as? String else {
            return nil
        }
        return suffix
    }

    private func backupPassJsonIfNeeded() throws {
        guard exploit.directWriteReady || exploit.canApplyCardChanges else { return }
        if !fileExists(atPath: passJsonBackupPath), let data = readPassJson() {
            try exploit.overwriteWalletFile(targetPath: passJsonBackupPath, data: data)
        }
    }

    private func applyCardNumber(_ newSuffix: String) {
        if !guardWriteAccessOrShowError() { return }

        guard let data = readPassJson(),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            errorMessage = L("card_number_read_error")
            showError = true
            return
        }

        do {
            try backupPassJsonIfNeeded()

            let trimmed = newSuffix.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                json.removeValue(forKey: "primaryAccountSuffix")
            } else {
                json["primaryAccountSuffix"] = trimmed
            }

            let newData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            try writeBundleData(newData, to: passJsonPath, shouldInvalidateCache: true)
            currentCardNumber = trimmed
            helper.refreshWalletServices()
            reloadPreviewContent()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restorePassJson() {
        if !guardWriteAccessOrShowError() { return }

        guard let backupData = readFileData(at: passJsonBackupPath, maxSize: 512 * 1024) else {
            errorMessage = L("card_number_no_backup")
            showError = true
            return
        }

        do {
            try writeBundleData(backupData, to: passJsonPath, shouldInvalidateCache: true)
            currentCardNumber = readCardNumber() ?? ""
            helper.refreshWalletServices()
            reloadPreviewContent()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func applyReplacementData(_ data: Data) {
        if !guardWriteAccessOrShowError() {
            return
        }

        guard let targetPath else {
            errorMessage = "This pass does not have a single replaceable artwork file."
            showError = true
            return
        }

        applyReplacementData(data, to: targetPath)
    }

    private func applyReplacementData(_ data: Data, to targetPath: String) {
        do {
            try backupFileIfNeeded(at: targetPath)
            try writeBundleData(data, to: targetPath, shouldInvalidateCache: !isCacheFilePath(targetPath))
            imageVersion += 1
            helper.refreshWalletServices()
            reloadPreviewContent()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func resetImage() {
        if !guardWriteAccessOrShowError() {
            return
        }

        guard let targetPath else {
            errorMessage = "This pass does not have a single replaceable artwork file."
            showError = true
            return
        }

        let backupPath = backupPath(for: targetPath)
        guard fileExists(atPath: backupPath),
              let backupData = readFileData(at: backupPath, maxSize: 16 * 1024 * 1024) else {
            errorMessage = "No backup found for this card"
            showError = true
            return
        }

        do {
            try writeBundleData(backupData, to: targetPath, shouldInvalidateCache: !isCacheFilePath(targetPath))
            imageVersion += 1
            helper.refreshWalletServices()
            reloadPreviewContent()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func ensureWritableCacheRoot() throws -> String {
        if let existing = cachePaths.first(where: { fileExists(atPath: $0) }) {
            return existing
        }

        guard exploit.directWriteReady else {
            throw NSError(
                domain: "CardioCacheRenderer",
                code: 3201,
                userInfo: [NSLocalizedDescriptionKey: "Open the card in Wallet once so its cache bundle exists, then try Render Cache again."]
            )
        }

        for cachePath in cachePaths {
            do {
                try fm.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
                return cachePath
            } catch {
                continue
            }
        }

        throw NSError(
            domain: "CardioCacheRenderer",
            code: 3202,
            userInfo: [NSLocalizedDescriptionKey: "Could not create a writable Wallet cache bundle for this card."]
        )
    }

    private func renderedCachePreviewImage() -> UIImage? {
        switch card.kind {
        case .paymentCard:
            return renderedPaymentCardCacheImage()
        case .walletPass:
            return renderedWalletPassPreviewImage()
        }
    }

    private func shouldRewriteCacheArtifact(named fileName: String) -> Bool {
        let lower = fileName.lowercased()
        guard fileName != ".", fileName != "..", !lower.hasSuffix(".backup") else {
            return false
        }

        if WalletCacheArtifact.allCases.contains(where: { $0.rawValue.lowercased() == lower }) {
            return true
        }

        let ext = (fileName as NSString).pathExtension.lowercased()
        if ext == "json" || ext == "strings" || ext == "plist" {
            return false
        }

        if lower.contains("frontface")
            || lower.contains("preview")
            || lower.contains("placeholder")
            || lower.contains("background")
            || lower.contains("thumbnail")
            || lower.contains("strip") {
            return true
        }

        return ext.isEmpty || ext == "png" || ext == "jpg" || ext == "jpeg"
    }

    private func cacheFileVariants(for fileName: String) -> [String] {
        let fileURL = URL(fileURLWithPath: fileName)
        let ext = fileURL.pathExtension
        let stem = fileURL.deletingPathExtension().lastPathComponent
        let baseStem = stem
            .replacingOccurrences(of: "@2x", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "@3x", with: "", options: .caseInsensitive)

        let suffixes = ["", "@2x", "@3x"]
        var variants: [String] = []
        for suffix in suffixes {
            let name = ext.isEmpty ? "\(baseStem)\(suffix)" : "\(baseStem)\(suffix).\(ext)"
            if !variants.contains(name) {
                variants.append(name)
            }
        }
        return variants
    }

    private func candidateCacheFileNames() -> [String] {
        var fileNames: [String] = []

        if let backgroundFileName = card.backgroundFileName {
            fileNames.append(contentsOf: cacheFileVariants(for: backgroundFileName))
        }

        if card.kind == .walletPass {
            for assetName in ["strip.png", "background.png", "thumbnail.png"] {
                fileNames.append(contentsOf: cacheFileVariants(for: assetName))
            }
        }

        if card.kind == .paymentCard {
            fileNames.append(contentsOf: WalletCacheArtifact.allCases.map(\.rawValue))
        }

        var unique: [String] = []
        for fileName in fileNames where !unique.contains(fileName) {
            unique.append(fileName)
        }
        return unique
    }

    private func appendUniquePath(_ path: String, to paths: inout [String]) {
        if !paths.contains(path) {
            paths.append(path)
        }
    }

    private func isDirectory(at path: String) -> Bool {
        var isDirectoryFlag = ObjCBool(false)
        let exists = fm.fileExists(atPath: path, isDirectory: &isDirectoryFlag)
        return exists && isDirectoryFlag.boolValue
    }

    private func cacheArtifactPaths(in cacheRoot: String) -> [String] {
        var paths: [String] = []

        for entry in listDirectory(cacheRoot) where shouldRewriteCacheArtifact(named: entry) {
            let artifactPath = joinPath(cacheRoot, entry)
            if !isDirectory(at: artifactPath) {
                appendUniquePath(artifactPath, to: &paths)
            }
        }

        for fileName in candidateCacheFileNames() {
            appendUniquePath(joinPath(cacheRoot, fileName), to: &paths)
        }

        if paths.isEmpty {
            for artifact in WalletCacheArtifact.allCases {
                appendUniquePath(joinPath(cacheRoot, artifact.rawValue), to: &paths)
            }
        }

        return paths
    }

    private func applyRenderedCache() {
        guard guardWriteAccessOrShowError() else {
            return
        }

        guard let renderedImage = renderedCachePreviewImage(),
              let renderedData = renderedImage.pngData() else {
            errorMessage = "Could not render cache artwork for this pass."
            showError = true
            return
        }

        do {
            let cacheRoot = try ensureWritableCacheRoot()
            let artifactPaths = cacheArtifactPaths(in: cacheRoot)

            for artifactPath in artifactPaths {
                if fileExists(atPath: artifactPath) {
                    try backupFileIfNeeded(at: artifactPath, maxSize: max(Int64(renderedData.count * 2), 512 * 1024))
                }
                try exploit.overwriteWalletFile(targetPath: artifactPath, data: renderedData)
            }

            helper.refreshWalletServices()
            reloadPreviewContent()
            successMessage = "Applied \(artifactPaths.count) cache artifact(s). Reopen Wallet to compare the cached render."
            showSaved = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func saveToDocuments() {
        let previewImage: UIImage?
        switch card.kind {
        case .paymentCard:
            previewImage = paymentCardPreviewImage ?? loadPaymentCardPreviewImage()
        case .walletPass:
            previewImage = renderedWalletPassPreviewImage()
        }

        guard let image = previewImage else {
            errorMessage = "Cannot read card image"
            showError = true
            return
        }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let safeName = visibleDisplayName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let dest = docs.appendingPathComponent("\(safeName).png")

        do {
            if let data = image.pngData() {
                try data.write(to: dest, options: .atomic)
                successMessage = ""
                showSaved = true
            } else {
                errorMessage = "Could not encode image"
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func encodedImageData(for image: UIImage, targetPath: String) -> Data? {
        let lower = targetPath.lowercased()
        if lower.hasSuffix(".png") {
            return image.pngData()
        }

        if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") {
            return image.jpegData(compressionQuality: 0.98)
        }

        if lower.hasSuffix(".pdf") {
            let pdfDocument = PDFDocument()
            guard let page = PDFPage(image: image) else { return nil }
            pdfDocument.insert(page, at: 0)
            return pdfDocument.dataRepresentation()
        }

        return nil
    }

    private func replaceImageAsset(at targetPath: String, image: UIImage) {
        guard let data = encodedImageData(for: image, targetPath: targetPath) else {
            errorMessage = targetPath.lowercased().hasSuffix(".pdf")
                ? "Unable to encode PDF"
                : "Could not encode image"
            showError = true
            return
        }

        applyReplacementData(data, to: targetPath)
        metadataStatusMessage = "Replaced \(relativeBundlePath(for: targetPath))"
    }

    private func replaceImportedBundleAsset(_ asset: ImportedBundleAsset, targetPath: String) {
        let importedLower = asset.fileName.lowercased()
        let targetLower = targetPath.lowercased()

        if importedLower.hasSuffix(".pdf"), targetLower.hasSuffix(".pdf") {
            applyReplacementData(asset.data, to: targetPath)
            metadataStatusMessage = "Replaced \(relativeBundlePath(for: targetPath))"
            return
        }

        guard let image = imageFromData(asset.data, path: asset.fileName) else {
            errorMessage = "Could not read the selected asset."
            showError = true
            return
        }

        replaceImageAsset(at: targetPath, image: image)
    }

    private func presentCardAssetPicker(useFiles: Bool) {
        showSourcePicker = false
        showSheet = false
        showDocPicker = false

        DispatchQueue.main.async {
            if useFiles {
                showDocPicker = true
            } else {
                cardImage = UIImage()
                showSheet = true
            }
        }
    }

    private func presentBundleAssetPicker(useFiles: Bool) {
        showBundleAssetSourcePicker = false
        showBundleImagePicker = false
        showBundleAssetDocumentPicker = false

        DispatchQueue.main.async {
            if useFiles {
                showBundleAssetDocumentPicker = true
            } else {
                bundleAssetImage = UIImage()
                showBundleImagePicker = true
            }
        }
    }

    private func setImage(image: UIImage) {
        guard card.kind == .paymentCard,
              let targetPath else {
            errorMessage = "Wallet passes use the bundle editor instead of a single image slot."
            showError = true
            return
        }

        metadataStatusMessage = ""
        replaceImageAsset(at: targetPath, image: image)
    }

    private func openBundleAssetReplacement(for file: CardMetadataFile) {
        guard file.kind.supportsAssetReplacement else {
            return
        }

        if !guardWriteAccessOrShowError() {
            return
        }

        pendingBundleAssetPath = file.path
        showBundleAssetSourcePicker = true
    }

    private func renderedWalletPassPreviewImage() -> UIImage? {
        guard let preview = walletPassPreviewData else {
            return nil
        }

        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: walletPassFront(preview))
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }

        return renderWalletPassPreviewFallback(preview)
    }

    private func renderWalletPassPreviewFallback(_ preview: WalletPassPreviewData) -> UIImage? {
        let controller = UIHostingController(rootView: walletPassFront(preview))
        let targetRect = CGRect(origin: .zero, size: walletPreviewSize)
        let view = controller.view

        view?.bounds = targetRect
        view?.frame = targetRect
        view?.backgroundColor = .clear
        view?.setNeedsLayout()
        view?.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: walletPreviewSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: targetRect, afterScreenUpdates: true)
        }
    }

    private func selectedBundlePreviewImage(for file: CardMetadataFile) -> UIImage? {
        guard file.kind.supportsAssetReplacement else {
            return nil
        }

        return loadImage(atPath: file.path, maxSize: 16 * 1024 * 1024)
    }

    private func walletFieldColumns(for fieldCount: Int) -> [GridItem] {
        let columnCount = max(1, min(fieldCount, 2))
        return Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .leading), count: columnCount)
    }

    @ViewBuilder
    private func walletFieldBlock(
        _ field: WalletPassField,
        valueFont: CGFloat,
        labelFont: CGFloat,
        labelColor: Color,
        valueColor: Color,
        isTrailing: Bool = false
    ) -> some View {
        VStack(alignment: isTrailing ? .trailing : .leading, spacing: 2) {
            Text(field.label.uppercased())
                .font(.system(size: labelFont, weight: .semibold))
                .foregroundColor(labelColor)
                .lineLimit(1)

            Text(field.value)
                .font(.system(size: valueFont, weight: .semibold))
                .foregroundColor(valueColor)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading)
    }

    @ViewBuilder
    private func walletFieldGrid(
        _ fields: [WalletPassField],
        valueFont: CGFloat,
        labelFont: CGFloat,
        labelColor: Color,
        valueColor: Color
    ) -> some View {
        LazyVGrid(columns: walletFieldColumns(for: fields.count), alignment: .leading, spacing: 10) {
            ForEach(fields) { field in
                walletFieldBlock(
                    field,
                    valueFont: valueFont,
                    labelFont: labelFont,
                    labelColor: labelColor,
                    valueColor: valueColor
                )
            }
        }
    }

    @ViewBuilder
    private func walletPassFront(_ preview: WalletPassPreviewData) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(preview.backgroundImage == nil ? preview.backgroundColor : Color.black)

            if let backgroundImage = preview.backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: walletPreviewSize.width, height: walletPreviewSize.height)
                    .blur(radius: 22)
                    .scaleEffect(1.12)
                    .opacity(0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.black.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    HStack(spacing: 10) {
                        if let logo = preview.logoImage ?? preview.iconImage {
                            Image(uiImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 34, height: 34)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(preview.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(preview.foregroundColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            if let subtitle = preview.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(preview.labelColor)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    if !preview.headerFields.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            ForEach(Array(preview.headerFields.prefix(2))) { field in
                                walletFieldBlock(
                                    field,
                                    valueFont: 13,
                                    labelFont: 8,
                                    labelColor: preview.labelColor,
                                    valueColor: preview.foregroundColor,
                                    isTrailing: true
                                )
                                .frame(maxWidth: 88, alignment: .trailing)
                            }
                        }
                    }
                }

                if let stripImage = preview.stripImage {
                    Image(uiImage: stripImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 86)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        if !preview.primaryFields.isEmpty {
                            walletFieldGrid(
                                Array(preview.primaryFields.prefix(2)),
                                valueFont: preview.primaryFields.count > 1 ? 16 : 20,
                                labelFont: 9,
                                labelColor: preview.labelColor,
                                valueColor: preview.foregroundColor
                            )
                        }

                        if !preview.secondaryFields.isEmpty {
                            walletFieldGrid(
                                Array(preview.secondaryFields.prefix(4)),
                                valueFont: 14,
                                labelFont: 8,
                                labelColor: preview.labelColor,
                                valueColor: preview.foregroundColor
                            )
                        }
                    }

                    if preview.stripImage == nil, let thumbnailImage = preview.thumbnailImage {
                        Image(uiImage: thumbnailImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 76, height: 76)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                }

                if !preview.auxiliaryFields.isEmpty {
                    walletFieldGrid(
                        Array(preview.auxiliaryFields.prefix(4)),
                        valueFont: 13,
                        labelFont: 8,
                        labelColor: preview.labelColor,
                        valueColor: preview.foregroundColor
                    )
                }

                Spacer(minLength: 0)

                if preview.primaryFields.isEmpty && preview.secondaryFields.isEmpty && preview.auxiliaryFields.isEmpty {
                    Text(preview.style.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(preview.labelColor)
                }
            }
            .padding(16)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .frame(width: walletPreviewSize.width, height: walletPreviewSize.height)
        .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
    }

    @ViewBuilder
    private func previewCardView() -> some View {
        switch card.kind {
        case .paymentCard:
            if let previewImage = paymentCardPreviewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 320)
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 320, height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.8))
                            Text(card.bundleName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    )
            }
        case .walletPass:
            if let preview = walletPassPreviewData {
                walletPassFront(preview)
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.35), Color.black.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: walletPreviewSize.width, height: walletPreviewSize.height)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.white.opacity(0.82))

                            Text(card.bundleName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("Preview unavailable until the pass metadata can be read.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.66))
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                    )
            }
        }
    }

    @ViewBuilder
    private var metadataEditorSheetContent: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Browse and edit the card bundle directly.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Pick any JSON, strings, or artwork file from the pass bundle. If Wallet has generated a sibling cache bundle, those files appear under `.cache/...` too. Text files open in the editor, and image/PDF assets open in a viewer with replace and restore actions.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))

                Picker("File", selection: metadataPickerSelection) {
                    ForEach(metadataFiles) { file in
                        Text(file.relativePath).tag(file.path)
                    }
                }
                .pickerStyle(.menu)
                .tint(.cyan)

                if let file = presentedMetadataFile {
                    HStack {
                        Text(file.kind.label)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))

                        Spacer()

                        if fileExists(atPath: metadataBackupPath(for: file)) {
                            Text("Backup ready")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green.opacity(0.9))
                        }
                    }

                    if file.kind.supportsTextEditing {
                        TextEditor(text: $metadataEditorText)
                            .font(.system(size: 13, design: .monospaced))
                            .padding(8)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                if let previewImage = selectedBundlePreviewImage(for: file) {
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(minHeight: 180, maxHeight: 320)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(maxWidth: .infinity, minHeight: 220)
                                        .overlay(
                                            VStack(spacing: 10) {
                                                Image(systemName: file.kind == .pdf ? "doc.richtext.fill" : "photo.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white.opacity(0.7))

                                                Text("Preview unavailable for \(file.relativePath).")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .multilineTextAlignment(.center)
                                            }
                                            .padding(20)
                                        )
                                }

                                Text("Use Replace to swap this artwork with a photo or a file. The original asset is backed up the first time you overwrite it.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }
                    }
                }

                if !metadataStatusMessage.isEmpty {
                    Text(metadataStatusMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green.opacity(0.9))
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Bundle Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("card_cancel") {
                        onDismissBundleEditor?()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if let file = presentedMetadataFile {
                        if file.kind.supportsTextEditing {
                            Button("card_rename_save") {
                                saveMetadataEditor()
                            }
                        } else if file.kind.supportsAssetReplacement {
                            Button("Replace") {
                                openBundleAssetReplacement(for: file)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if let file = presentedMetadataFile,
                       fileExists(atPath: metadataBackupPath(for: file)) {
                        Button("card_number_restore_original", role: .destructive) {
                            restoreMetadataEditor()
                        }
                    }
                }
            }
            .onAppear {
                prepareMetadataEditor()
            }
            .onChange(of: metadataFiles) { _ in
                ensureMetadataSelection()
            }
            .confirmationDialog("Replace Asset", isPresented: $showBundleAssetSourcePicker, titleVisibility: .visible) {
                Button("card_source_gallery") {
                    presentBundleAssetPicker(useFiles: false)
                }
                Button("card_source_files") {
                    presentBundleAssetPicker(useFiles: true)
                }
                Button("card_cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showBundleImagePicker) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: self.$bundleAssetImage)
            }
            .sheet(isPresented: $showBundleAssetDocumentPicker) {
                AssetDocumentPicker { importedAsset in
                    if !pendingBundleAssetPath.isEmpty {
                        replaceImportedBundleAsset(importedAsset, targetPath: pendingBundleAssetPath)
                    }
                }
            }
        }
    }

    private var cardTileContent: some View {
        VStack(spacing: 8) {
            previewCardView()
                .id(imageVersion)
                .onTapGesture {
                    guard card.kind == .paymentCard else {
                        return
                    }
                    if exploit.canApplyCardChanges {
                        showSourcePicker = true
                    } else {
                        errorMessage = exploit.blockedReason
                        showError = true
                    }
                }

            Text(visibleDisplayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)

            if visibleDisplayName != baseDisplayName {
                Text(baseDisplayName)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .lineLimit(1)
            }

            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Button {
                        nicknameInput = CardNicknameManager.shared.nickname(for: card.directoryPath) ?? ""
                        showNicknameEditor = true
                    } label: {
                        Label("card_rename", systemImage: "pencil")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white.opacity(0.7))

                    Button {
                        onOpenBundleEditor?(card)
                    } label: {
                        Label("Bundle", systemImage: "folder")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white.opacity(0.7))

                    if card.kind == .paymentCard {
                        Button {
                            currentCardNumber = readCardNumber() ?? ""
                            cardNumberInput = currentCardNumber
                            showCardNumberEditor = true
                        } label: {
                            Label("card_number_edit", systemImage: "number")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }

                HStack(spacing: 16) {
                    if card.kind == .paymentCard, hasImageBackup {
                        Button {
                            resetImage()
                        } label: {
                            Label("card_restore", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.red)
                    }

                    Button {
                        applyRenderedCache()
                    } label: {
                        Label("Apply Cache", systemImage: "sparkles")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.orange.opacity(0.9))

                    Button {
                        saveToDocuments()
                    } label: {
                        Label("card_save", systemImage: "square.and.arrow.down")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.cyan)
                }
            }
            .padding(.top, 4)
        }
    }

    var body: some View {
        Group {
            if embeddedBundleEditor {
                metadataEditorSheetContent
            } else {
                cardTileContent
                    .confirmationDialog("card_pick_source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                        Button("card_source_gallery") {
                            presentCardAssetPicker(useFiles: false)
                        }
                        Button("card_source_files") {
                            presentCardAssetPicker(useFiles: true)
                        }
                        Button("card_cancel", role: .cancel) {}
                    }
                    .sheet(isPresented: $showSheet) {
                        ImagePicker(sourceType: .photoLibrary, selectedImage: self.$cardImage)
                    }
                    .sheet(isPresented: $showDocPicker) {
                        DocumentPicker(selectedImage: self.$cardImage)
                    }
                    .alert("card_rename_title", isPresented: $showNicknameEditor) {
                        TextField(L("card_nickname_placeholder"), text: $nicknameInput)
                        Button("card_rename_save") {
                            CardNicknameManager.shared.setNickname(nicknameInput.isEmpty ? nil : nicknameInput, for: card.directoryPath)
                        }
                        Button("card_clear_name", role: .destructive) {
                            CardNicknameManager.shared.setNickname(nil, for: card.directoryPath)
                            nicknameInput = ""
                        }
                        Button("card_cancel", role: .cancel) {}
                    } message: {
                        Text("card_rename_message")
                    }
                    .alert("card_number_title", isPresented: $showCardNumberEditor) {
                        TextField(L("card_number_placeholder"), text: $cardNumberInput)
                        Button("card_rename_save") {
                            applyCardNumber(cardNumberInput)
                        }
                        if fileExists(atPath: passJsonBackupPath) {
                            Button("card_number_restore_original", role: .destructive) {
                                restorePassJson()
                            }
                        }
                        Button("card_cancel", role: .cancel) {}
                    } message: {
                        Text(currentCardNumber.isEmpty
                             ? L("card_number_message_empty")
                             : String(format: L("card_number_message"), currentCardNumber))
                    }
            }
        }
        .onChange(of: self.cardImage) { newImage in
            setImage(image: newImage)
        }
        .onChange(of: bundleAssetImage) { newImage in
            guard !pendingBundleAssetPath.isEmpty else {
                return
            }
            replaceImageAsset(at: pendingBundleAssetPath, image: newImage)
        }
        .onAppear {
            reloadPreviewContent()
            currentCardNumber = readCardNumber() ?? ""
        }
        .onChange(of: imageVersion) { _ in
            reloadPreviewContent()
        }
        .alert("card_error", isPresented: $showError) {
            Button("card_ok", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("card_saved", isPresented: $showSaved) {
            Button("card_ok", role: .cancel) {}
        } message: {
            if successMessage.isEmpty {
                Text("card_saved_message")
            } else {
                Text(successMessage)
            }
        }
    }
}
