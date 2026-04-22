import Foundation
import Combine

// MARK: - NFCDaemonManager
//
// Manages the lifecycle of the custom nfcd daemon for NFC card emulation.
// Hooks into CardioDS's existing ExploitManager — no separate exploit needed.
//
// Requires:
//   1. ExploitManager.shared.darkswordReady == true (kernel r/w acquired)
//   2. ExploitManager.shared.sandboxEscaped == true (full filesystem access)
//   3. "nfcd_a3" binary bundled in the app (Resources folder in Xcode)
//
// The "nfcd_a3" binary is a custom nfcd replacement that:
//   - Accepts commands on /var/run/a3nfcd.socket
//   - Responds to NFC readers with the loaded card's UID + APDU data

@MainActor
final class NFCDaemonManager: ObservableObject {

    static let shared = NFCDaemonManager()

    @Published private(set) var status: DaemonStatus = .exploitRequired
    @Published private(set) var activeCardID: UUID?
    @Published private(set) var statusMessage = "Run exploit first."

    private var cancelBag = Set<AnyCancellable>()
    private let helper = ObjcHelper()

    // MARK: - Status

    enum DaemonStatus: Equatable {
        case exploitRequired        // kernel r/w not yet acquired
        case nfcdBinaryMissing      // nfcd_a3 not bundled
        case ready                  // daemon up, waiting for card
        case emulating(String)      // actively emulating a card
        case error(String)
    }

    var canEmulate: Bool {
        if case .ready = status     { return true  }
        if case .emulating = status { return true  }
        return false
    }

    private init() {
        observeExploit()
    }

    // MARK: - Observe ExploitManager

    private func observeExploit() {
        let exploit = ExploitManager.shared
        // React whenever darksword + sandbox state change
        Publishers.CombineLatest(
            exploit.$darkswordReady,
            exploit.$sandboxEscaped
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] darkswordReady, sandboxEscaped in
            guard let self else { return }
            if darkswordReady && sandboxEscaped {
                Task { await self.setup() }
            } else if case .ready = self.status {
                // Exploit lost (reboot etc.) — reset state
                self.status = .exploitRequired
                self.statusMessage = "Exploit state lost. Run exploit again."
            }
        }
        .store(in: &cancelBag)
    }

    // MARK: - Setup (install + start custom nfcd)

    private func setup() async {
        guard ExploitManager.shared.darkswordReady,
              ExploitManager.shared.sandboxEscaped else {
            status = .exploitRequired
            statusMessage = "Exploit not ready."
            return
        }

        guard let bundledPath = Bundle.main.path(forResource: "nfcd_a3", ofType: nil) else {
            status = .nfcdBinaryMissing
            statusMessage = "nfcd_a3 not found in app bundle. Build and embed it first."
            print("[NFCDaemonManager] nfcd_a3 binary missing from bundle")
            return
        }

        print("[NFCDaemonManager] Setting up custom nfcd…")
        statusMessage = "Stopping system nfcd…"

        // Stop system nfcd (uses killall from ObjcHelper)
        helper.stopNFCDaemon()
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        statusMessage = "Installing custom nfcd…"
        let installed = await runOnBackground {
            self.helper.startNFCDaemon(atPath: bundledPath)
        }

        if installed {
            status = .ready
            statusMessage = "NFC daemon ready. Tap a card below to emulate."
            print("[NFCDaemonManager] Custom nfcd started successfully")
        } else {
            status = .error("Failed to start nfcd_a3. Check exploit status.")
            statusMessage = "Failed to start custom nfcd."
            print("[NFCDaemonManager] nfcd_a3 start failed")
        }
    }

    // MARK: - Card Emulation

    /// Begin emulating `card`. Returns true on success.
    func activate(_ card: NFCCard) async -> Bool {
        guard canEmulate else {
            statusMessage = "Daemon not ready."
            return false
        }

        print("[NFCDaemonManager] Loading card: \(card.displayName) (\(card.uidHex))")

        let ok = await runOnBackground {
            self.helper.nfcdLoadCard(
                uid: card.uid,
                ats: card.ats ?? Data(),
                apduResponses: card.apduResponses
            )
        }

        if ok {
            activeCardID = card.id
            status = .emulating(card.displayName)
            statusMessage = "Emulating: \(card.displayName)"
        } else {
            statusMessage = "Failed to load card into daemon."
        }
        return ok
    }

    /// Stop emulating the current card.
    func deactivate() {
        helper.nfcdClearCard()
        activeCardID = nil
        status = .ready
        statusMessage = "NFC daemon ready. No card active."
        print("[NFCDaemonManager] Card emulation stopped")
    }

    // MARK: - Helpers

    private func runOnBackground<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                cont.resume(returning: work())
            }
        }
    }
}
