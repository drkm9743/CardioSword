import SwiftUI
import CoreNFC

// MARK: - NFCEmulationView
//
// Tab 4 — NFC card reader + emulator.
// Reading works on any sideload build.
// Emulation requires darkswordReady + sandboxEscaped + nfcd_a3 binary in bundle.

struct NFCEmulationView: View {

    @ObservedObject private var store   = NFCCardStore.shared
    @ObservedObject private var reader  = NFCCardReader.shared
    @ObservedObject private var daemon  = NFCDaemonManager.shared
    @ObservedObject private var exploit = ExploitManager.shared

    @State private var showingRenameAlert = false
    @State private var renameTarget: NFCCard?
    @State private var renameText = ""
    @State private var showingDetail: NFCCard?
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // --- Header ---
                headerBar

                // --- Daemon status banner ---
                daemonStatusBanner

                // --- Card list ---
                if store.cards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
        }
        .alert("Rename Card", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let card = renameTarget {
                    store.rename(card, to: renameText)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .sheet(item: $showingDetail) { card in
            NFCCardDetailView(card: card)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("NFC Cards")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("\(store.cards.count) card\(store.cards.count == 1 ? "" : "s") saved")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: startScan) {
                Label("Scan", systemImage: "wave.3.right.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(reader.isScanning ? Color.gray : Color.cyan)
                    .clipShape(Capsule())
            }
            .disabled(reader.isScanning)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Daemon status banner

    @ViewBuilder
    private var daemonStatusBanner: some View {
        let (icon, color, msg) = bannerInfo
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(msg)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            if case .ready = daemon.status {
                // nothing extra
            } else if case .exploitRequired = daemon.status {
                Button("Go to Exploit") {
                    // Post to ExploitManager's tab selection if possible
                    NotificationCenter.default.post(name: .cardioSelectTab, object: 3)
                }
                .font(.caption.bold())
                .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
    }

    private var bannerInfo: (icon: String, color: Color, msg: String) {
        switch daemon.status {
        case .exploitRequired:
            return ("lock.fill", .orange, "Emulation requires exploit. Reading works now.")
        case .nfcdBinaryMissing:
            return ("exclamationmark.triangle.fill", .red, "nfcd_a3 binary missing from bundle.")
        case .ready:
            return ("checkmark.circle.fill", .green, daemon.statusMessage)
        case .emulating(let name):
            return ("wave.3.right.circle.fill", .cyan, "Emulating: \(name)")
        case .error(let msg):
            return ("xmark.circle.fill", .red, msg)
        }
    }

    // MARK: - Card list

    private var cardList: some View {
        List {
            ForEach(store.cards) { card in
                NFCCardRow(
                    card: card,
                    isActive: daemon.activeCardID == card.id,
                    canEmulate: daemon.canEmulate
                ) { action in
                    handleAction(action, card: card)
                }
                .listRowBackground(Color.white.opacity(0.04))
                .listRowSeparatorTint(.white.opacity(0.08))
            }
            .onDelete { offsets in
                offsets.forEach { store.delete(store.cards[$0]) }
            }
        }
        .listStyle(.plain)
        .background(Color.black)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wave.3.right.circle")
                .font(.system(size: 56))
                .foregroundColor(.cyan.opacity(0.4))
            Text("No NFC Cards")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Tap **Scan** to read a physical card.\nISO 14443 (DESFire, ISO-DEP), FeliCa,\nMiFare, and ISO 15693 are supported.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Actions

    private func startScan() {
        reader.scan { result in
            Task { @MainActor in
                switch result {
                case .success(let card):
                    store.add(card)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func handleAction(_ action: NFCCardRowAction, card: NFCCard) {
        switch action {
        case .emulate:
            Task {
                if daemon.activeCardID == card.id {
                    daemon.deactivate()
                } else {
                    _ = await daemon.activate(card)
                }
            }
        case .rename:
            renameTarget = card
            renameText = card.displayName
            showingRenameAlert = true
        case .detail:
            showingDetail = card
        case .delete:
            if daemon.activeCardID == card.id {
                daemon.deactivate()
            }
            store.delete(card)
        }
    }
}

// MARK: - NFCCardRow

enum NFCCardRowAction { case emulate, rename, detail, delete }

struct NFCCardRow: View {
    let card: NFCCard
    let isActive: Bool
    let canEmulate: Bool
    let onAction: (NFCCardRowAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(isActive ? Color.cyan.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: card.type.systemImage)
                    .foregroundColor(isActive ? .cyan : .white.opacity(0.7))
                    .font(.system(size: 18))
            }

            // Card info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(card.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    if isActive {
                        Text("ACTIVE")
                            .font(.caption2.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                    }
                }
                Text(card.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(card.uidHex)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Emulate / stop button
            Button {
                onAction(.emulate)
            } label: {
                Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isActive ? .red : (canEmulate ? .cyan : .gray))
            }
            .disabled(!canEmulate && !isActive)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Button { onAction(.detail) } label: {
                Label("Details", systemImage: "info.circle")
            }
            Button { onAction(.rename) } label: {
                Label("Rename", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) { onAction(.delete) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onTapGesture { onAction(.detail) }
    }
}

// MARK: - NFCCardDetailView

struct NFCCardDetailView: View {
    let card: NFCCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    // Basic info
                    Section("Card Info") {
                        detailRow("Name", card.displayName)
                        detailRow("Type", card.type.rawValue)
                        detailRow("UID", card.uidHex)
                        detailRow("Added", card.dateAdded.formatted(date: .abbreviated, time: .shortened))
                        if let ats = card.ats, !ats.isEmpty {
                            detailRow("ATS", ats.hexFlat)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    // APDU responses
                    if !card.apduResponses.isEmpty {
                        Section("APDU Responses (\(card.apduResponses.count))") {
                            ForEach(card.apduResponses.sorted(by: { $0.key < $1.key }), id: \.key) { key, val in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(key)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text(val.hexFlat)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.cyan)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }

                    // DESFire apps
                    if !card.desfireApps.isEmpty {
                        Section("DESFire Apps (\(card.desfireApps.count))") {
                            ForEach(card.desfireApps) { app in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("AppID: \(app.appIDHex)")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.white)
                                    Text("\(app.files.count) file(s)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }

                    // Tech details
                    Section("Technical") {
                        Text(card.techDetails)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle(card.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let cardioSelectTab = Notification.Name("CardioSelectTab")
}

// MARK: - Data hex helpers

private extension Data {
    var hexFlat: String { map { String(format: "%02X", $0) }.joined() }
}
