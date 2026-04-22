import Foundation
import CoreNFC

// MARK: - NFCCardReader
//
// Reads physical NFC cards via CoreNFC.
// Supports ISO 14443-4 / DESFire, NTAG/MiFare, FeliCa, ISO 15693.
// IMPORTANT: Add "com.apple.developer.nfc.readersession.formats" entitlement
//            and NFCReaderUsageDescription to Info.plist before using this.

@MainActor
final class NFCCardReader: NSObject, ObservableObject {

    static let shared = NFCCardReader()

    @Published var isScanning = false
    @Published var lastError: String?

    private var session: NFCTagReaderSession?
    private var onComplete: ((Result<NFCCard, Error>) -> Void)?

    private override init() { super.init() }

    // MARK: - Public

    func scan(completion: @escaping (Result<NFCCard, Error>) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            completion(.failure(ReaderError.nfcUnavailable))
            return
        }
        guard !isScanning else { return }
        onComplete = completion
        isScanning = true
        lastError = nil
        session = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693, .iso18092],
            delegate: self,
            queue: .global(qos: .userInitiated)
        )
        session?.alertMessage = "Hold your card near the top of your iPhone."
        session?.begin()
    }

    // MARK: - Errors

    enum ReaderError: LocalizedError {
        case nfcUnavailable, unsupportedTag, readFailed(String)
        var errorDescription: String? {
            switch self {
            case .nfcUnavailable:    return "NFC is not available on this device."
            case .unsupportedTag:    return "This tag type is not yet supported."
            case .readFailed(let m): return "Read failed: \(m)"
            }
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCCardReader: NFCTagReaderSessionDelegate {

    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession,
                                       didInvalidateWithError error: Error) {
        Task { @MainActor in
            isScanning = false
            let e = error as NSError
            if e.code != 200 {     // 200 = user cancelled
                lastError = error.localizedDescription
                onComplete?(.failure(error))
            }
            onComplete = nil
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession,
                                       didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if let error {
                session.invalidate(errorMessage: "Connection failed.")
                Task { @MainActor in
                    self.onComplete?(.failure(error))
                    self.onComplete = nil
                }
                return
            }
            Task { await self.processTag(tag, session: session) }
        }
    }

    // MARK: - Tag processing

    private func processTag(_ tag: NFCTag, session: NFCTagReaderSession) async {
        do {
            let card: NFCCard
            switch tag {
            case .iso7816(let t):  card = try await readISO7816(t)
            case .feliCa(let t):   card = try await readFeliCa(t)
            case .miFare(let t):   card = try await readMiFare(t)
            case .iso15693(let t): card = try await readISO15693(t)
            @unknown default:      throw ReaderError.unsupportedTag
            }
            session.alertMessage = "Card read successfully!"
            session.invalidate()
            await MainActor.run {
                isScanning = false
                onComplete?(.success(card))
                onComplete = nil
            }
        } catch {
            session.invalidate(errorMessage: "Could not read card.")
            await MainActor.run {
                isScanning = false
                lastError = error.localizedDescription
                onComplete?(.failure(error))
                onComplete = nil
            }
        }
    }

    // MARK: - ISO 7816 / ISO-DEP / DESFire

    private func readISO7816(_ tag: NFCISO7816Tag) async throws -> NFCCard {
        let uid  = tag.identifier
        let ats  = tag.historicalBytes ?? Data()
        var apduResponses: [String: Data] = [:]
        var desfireApps: [DesfireApplication] = []
        var cardType: NFCCardType = .isoDep

        // --- Try DESFire GetVersion (0x90 60) ---
        let getVersion = NFCISO7816APDU(
            instructionClass: 0x90, instructionCode: 0x60,
            p1Parameter: 0x00, p2Parameter: 0x00,
            data: Data(), expectedResponseLength: 256)

        if let (_, sw1, _) = try? await tag.sendAPDU(getVersion), sw1 == 0x91 {
            cardType = .desfire
            desfireApps = (try? await readDesfireApps(tag)) ?? []
        } else {
            // Generic ISO-DEP: probe well-known access control AIDs
            let probeAIDs: [Data] = [
                Data([0xD2, 0x76, 0x00, 0x00, 0x85, 0x01, 0x00]),  // NFC Forum / DESFire
                Data([0xA0, 0x00, 0x00, 0x03, 0x96]),               // LEGIC
                Data([0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10]),   // Visa Proximity
            ]
            for aid in probeAIDs {
                let apdu = NFCISO7816APDU(
                    instructionClass: 0x00, instructionCode: 0xA4,
                    p1Parameter: 0x04, p2Parameter: 0x00,
                    data: aid, expectedResponseLength: 256)
                if let (data, sw1, sw2) = try? await tag.sendAPDU(apdu) {
                    let key = "00A40400\(String(format: "%02X", aid.count))\(aid.hexFlat)"
                    apduResponses[key] = data + Data([sw1, sw2])
                }
            }
        }

        let details = "UID: \(uid.hexColon)  ATS: \(ats.hexFlat)  Type: \(cardType.rawValue)"
        return NFCCard(name: "Card \(uid.hexFlat.prefix(8))",
                       type: cardType, uid: uid, ats: ats,
                       apduResponses: apduResponses, desfireApps: desfireApps,
                       techDetails: details)
    }

    // MARK: DESFire full read

    private func readDesfireApps(_ tag: NFCISO7816Tag) async throws -> [DesfireApplication] {
        let getAppIDs = NFCISO7816APDU(instructionClass: 0x90, instructionCode: 0x6A,
                                        p1Parameter: 0x00, p2Parameter: 0x00,
                                        data: Data(), expectedResponseLength: 256)
        guard let (rawIDs, _, _) = try? await tag.sendAPDU(getAppIDs) else { return [] }

        var apps: [DesfireApplication] = []
        let count = rawIDs.count / 3
        for i in 0..<count {
            let appID = rawIDs.subdata(in: (i*3)..<(i*3+3))
            var files: [DesfireFile] = []

            let selectApp = NFCISO7816APDU(instructionClass: 0x90, instructionCode: 0x5A,
                                            p1Parameter: 0x00, p2Parameter: 0x00,
                                            data: appID, expectedResponseLength: 256)
            _ = try? await tag.sendAPDU(selectApp)

            let getFiles = NFCISO7816APDU(instructionClass: 0x90, instructionCode: 0x6F,
                                           p1Parameter: 0x00, p2Parameter: 0x00,
                                           data: Data(), expectedResponseLength: 256)
            if let (fileIDs, _, _) = try? await tag.sendAPDU(getFiles) {
                for fNum in fileIDs {
                    let readPayload = Data([fNum, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00])
                    let readData = NFCISO7816APDU(instructionClass: 0x90, instructionCode: 0xBD,
                                                   p1Parameter: 0x00, p2Parameter: 0x00,
                                                   data: readPayload, expectedResponseLength: 256)
                    if let (data, _, _) = try? await tag.sendAPDU(readData) {
                        files.append(DesfireFile(id: UUID(), fileNumber: fNum, fileType: 0x01, data: data))
                    }
                }
            }
            apps.append(DesfireApplication(id: UUID(), appID: appID, files: files))
        }
        return apps
    }

    // MARK: FeliCa

    private func readFeliCa(_ tag: NFCFeliCaTag) async throws -> NFCCard {
        let idm = tag.currentIDm
        let sc  = tag.currentSystemCode
        return NFCCard(name: "FeliCa \(idm.hexFlat.prefix(8))",
                       type: .felica, uid: idm,
                       techDetails: "IDm: \(idm.hexColon)  SystemCode: \(sc.hexFlat)")
    }

    // MARK: MiFare / NTAG

    private func readMiFare(_ tag: NFCMiFareTag) async throws -> NFCCard {
        let uid = tag.identifier
        let type: NFCCardType = (tag.mifareFamily == .ultralight || tag.mifareFamily == .plus) ? .ntag : .mifarePlus
        return NFCCard(name: "\(type.rawValue) \(uid.hexFlat.prefix(8))",
                       type: type, uid: uid,
                       techDetails: "UID: \(uid.hexColon)  Family: \(tag.mifareFamily.rawValue)")
    }

    // MARK: ISO 15693

    private func readISO15693(_ tag: NFCISO15693Tag) async throws -> NFCCard {
        let uid = tag.identifier
        return NFCCard(name: "ISO15693 \(uid.hexFlat.prefix(8))",
                       type: .iso15693, uid: uid,
                       techDetails: "UID: \(uid.hexColon)  IC Mfr: \(tag.icManufacturerCode)")
    }
}

// MARK: - Helpers

private extension Data {
    var hexFlat: String   { map { String(format: "%02X", $0) }.joined() }
    var hexColon: String  { map { String(format: "%02X", $0) }.joined(separator: ":") }
}

private extension NFCISO7816Tag {
    func sendAPDU(_ apdu: NFCISO7816APDU) async throws -> (Data, UInt8, UInt8) {
        try await withCheckedThrowingContinuation { cont in
            sendCommand(apdu: apdu) { data, sw1, sw2, err in
                if let err { cont.resume(throwing: err) }
                else { cont.resume(returning: (data, sw1, sw2)) }
            }
        }
    }
}
