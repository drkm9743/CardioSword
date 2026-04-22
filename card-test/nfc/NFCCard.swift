import Foundation

// MARK: - NFCCardType

enum NFCCardType: String, Codable, CaseIterable {
    case desfire       = "DESFire"
    case isoDep        = "ISO-DEP"
    case mifarePlus    = "MIFARE Plus"
    case ntag          = "NTAG"
    case felica        = "FeliCa"
    case iso15693      = "ISO 15693"
    case unknown       = "Unknown"

    var systemImage: String {
        switch self {
        case .desfire:    return "creditcard.fill"
        case .isoDep:     return "wave.3.right"
        case .mifarePlus: return "shield.lefthalf.filled"
        case .ntag:       return "tag.fill"
        case .felica:     return "dot.radiowaves.left.and.right"
        case .iso15693:   return "barcode"
        case .unknown:    return "questionmark.circle"
        }
    }
}

// MARK: - NFCCard

struct NFCCard: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: NFCCardType
    /// Raw UID / identifier bytes
    var uid: Data
    /// ATS bytes for ISO 14443-4
    var ats: Data?
    /// ISO 7816 APDU responses: key = SELECT APDU hex, value = response hex
    var apduResponses: [String: Data]
    /// DESFire applications
    var desfireApps: [DesfireApplication]
    /// Human-readable summary
    var techDetails: String
    var dateAdded: Date
    /// Optional nickname
    var nickname: String?

    init(
        id: UUID = UUID(),
        name: String,
        type: NFCCardType,
        uid: Data,
        ats: Data? = nil,
        apduResponses: [String: Data] = [:],
        desfireApps: [DesfireApplication] = [],
        techDetails: String = "",
        dateAdded: Date = Date(),
        nickname: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.uid = uid
        self.ats = ats
        self.apduResponses = apduResponses
        self.desfireApps = desfireApps
        self.techDetails = techDetails
        self.dateAdded = dateAdded
        self.nickname = nickname
    }

    var displayName: String { nickname ?? name }
    var uidHex: String { uid.map { String(format: "%02X", $0) }.joined(separator: ":") }
    var uidHexFlat: String { uid.map { String(format: "%02X", $0) }.joined() }
}

// MARK: - DESFire data types

struct DesfireApplication: Codable, Identifiable {
    var id: UUID
    var appID: Data
    var files: [DesfireFile]
    var appIDHex: String { appID.map { String(format: "%02X", $0) }.joined() }
}

struct DesfireFile: Codable, Identifiable {
    var id: UUID
    var fileNumber: UInt8
    var fileType: UInt8
    var data: Data
}

// MARK: - NFCCardStore

final class NFCCardStore: ObservableObject {

    static let shared = NFCCardStore()

    @Published private(set) var cards: [NFCCard] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("nfc_cards.json")
    }()

    private init() { load() }

    func add(_ card: NFCCard) {
        cards.append(card)
        save()
    }

    func update(_ card: NFCCard) {
        if let i = cards.firstIndex(where: { $0.id == card.id }) {
            cards[i] = card
            save()
        }
    }

    func delete(_ card: NFCCard) {
        cards.removeAll { $0.id == card.id }
        save()
    }

    func rename(_ card: NFCCard, to name: String) {
        var c = card
        c.nickname = name.isEmpty ? nil : name
        update(c)
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(cards)
            try data.write(to: fileURL, options: .atomicWrite)
        } catch {
            print("[NFCCardStore] save error: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            cards = try JSONDecoder().decode([NFCCard].self, from: data)
        } catch {
            print("[NFCCardStore] load error: \(error)")
        }
    }
}
