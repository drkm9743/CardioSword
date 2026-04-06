import SwiftUI
import UIKit

// MARK: - Saved Card Model

struct SavedCard: Identifiable, Codable {
    let id: String
    let name: String
    let bundleName: String
    let savedDate: Date
    let fileName: String

    var displayDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: savedDate)
    }
}

// MARK: - View Model

@MainActor
final class MyCardsViewModel: ObservableObject {
    @Published var savedCards: [SavedCard] = []
    @Published var statusMessage: String?
    @Published var isSubmitting = false

    private let manifestFile = "my_cards_manifest.json"

    init() {
        loadManifest()
    }

    private var backupDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("MyCards")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var manifestURL: URL {
        backupDir.appendingPathComponent(manifestFile)
    }

    private func loadManifest() {
        guard let data = try? Data(contentsOf: manifestURL),
              let cards = try? JSONDecoder().decode([SavedCard].self, from: data) else {
            savedCards = []
            return
        }
        // Only keep cards whose files still exist
        savedCards = cards.filter { FileManager.default.fileExists(atPath: backupDir.appendingPathComponent($0.fileName).path) }
    }

    private func saveManifest() {
        guard let data = try? JSONEncoder().encode(savedCards) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }

    func imageFor(_ card: SavedCard) -> UIImage? {
        let path = backupDir.appendingPathComponent(card.fileName).path
        return UIImage(contentsOfFile: path)
    }

    func saveCurrentCard(imagePath: String, bundleName: String) {
        let fm = FileManager.default

        // Read the card image data
        guard let data = fm.contents(atPath: imagePath) else {
            statusMessage = "Cannot read card image at \(imagePath)"
            return
        }

        let safeName = bundleName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(safeName)_\(timestamp).png"

        let destURL = backupDir.appendingPathComponent(fileName)

        do {
            // Convert to PNG for consistency
            if let image = UIImage(data: data), let pngData = image.pngData() {
                try pngData.write(to: destURL, options: .atomic)
            } else {
                try data.write(to: destURL, options: .atomic)
            }

            let card = SavedCard(
                id: UUID().uuidString,
                name: safeName,
                bundleName: bundleName,
                savedDate: Date(),
                fileName: fileName
            )

            savedCards.insert(card, at: 0)
            saveManifest()
            statusMessage = "Saved \(bundleName)"
        } catch {
            statusMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func deleteCard(_ card: SavedCard) {
        let path = backupDir.appendingPathComponent(card.fileName)
        try? FileManager.default.removeItem(at: path)
        savedCards.removeAll { $0.id == card.id }
        saveManifest()
    }

    func imageDataFor(_ card: SavedCard) -> Data? {
        let path = backupDir.appendingPathComponent(card.fileName)
        return try? Data(contentsOf: path)
    }

    func submitToGitHub(_ card: SavedCard) {
        guard !isSubmitting else { return }
        guard let data = imageDataFor(card),
              let image = UIImage(data: data) else {
            statusMessage = L("mycards_submit_read_error")
            return
        }

        isSubmitting = true
        Task {
            let result = await GitHubService.submitDumpedCard(
                name: card.name,
                bundleName: card.bundleName,
                date: card.displayDate,
                image: image
            )
            isSubmitting = false
            statusMessage = result.message
        }
    }
}

// MARK: - My Cards View

struct MyCardsView: View {
    @StateObject private var vm = MyCardsViewModel()
    @ObservedObject var exploit: ExploitManager
    let cards: [Card]

    @State private var showSaveSheet = false
    @State private var showAlert = false
    @State private var cardToDelete: SavedCard?

    private let helper = ObjcHelper()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("mycards_title")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)

                    Text("mycards_subtitle")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)

                    // Save current cards button
                    if !cards.isEmpty {
                        Button {
                            saveAllCurrentCards()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down.on.square")
                                Text("mycards_backup_all")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(10)
                            .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        Text("mycards_no_device_cards")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                    }

                    // Saved cards list
                    if vm.savedCards.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundColor(.gray)
                            Text("mycards_empty")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Text("mycards_empty_hint")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.savedCards) { saved in
                                SavedCardRow(
                                    card: saved,
                                    vm: vm,
                                    exploit: exploit,
                                    onApply: { applyCard(saved) },
                                    onDelete: { cardToDelete = saved },
                                    onSubmit: { vm.submitToGitHub(saved) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: vm.statusMessage) { msg in
            if msg != nil { showAlert = true }
        }
        .alert(L("mycards_title"), isPresented: $showAlert) {
            Button("card_ok") { vm.statusMessage = nil }
        } message: {
            Text(vm.statusMessage ?? "")
        }
        .alert(L("mycards_delete_title"), isPresented: .init(
            get: { cardToDelete != nil },
            set: { if !$0 { cardToDelete = nil } }
        )) {
            Button(L("mycards_delete"), role: .destructive) {
                if let card = cardToDelete {
                    vm.deleteCard(card)
                    cardToDelete = nil
                }
            }
            Button(L("card_cancel"), role: .cancel) {
                cardToDelete = nil
            }
        } message: {
            Text("mycards_delete_confirm")
        }
    }

    private func saveAllCurrentCards() {
        var count = 0
        for card in cards {
            vm.saveCurrentCard(imagePath: card.imagePath, bundleName: card.bundleName)
            count += 1
        }
        vm.statusMessage = "Backed up \(count) card(s)"
    }

    private func applyCard(_ saved: SavedCard) {
        guard exploit.canApplyCardChanges else {
            vm.statusMessage = exploit.blockedReason
            return
        }

        guard let data = vm.imageDataFor(saved) else {
            vm.statusMessage = "Cannot read saved card data"
            return
        }

        // Find matching device card by bundleName
        guard let deviceCard = cards.first(where: { $0.bundleName == saved.bundleName }) else {
            vm.statusMessage = "Original card slot '\(saved.bundleName)' not found on device. Apply manually from the Cards tab."
            return
        }

        let targetPath = deviceCard.directoryPath + "/" + deviceCard.backgroundFileName

        do {
            try exploit.overwriteWalletFile(targetPath: targetPath, data: data)
            // Remove cache
            let cachePath: String
            if deviceCard.directoryPath.lowercased().hasSuffix(".pkpass") {
                cachePath = deviceCard.directoryPath.replacingOccurrences(of: "pkpass", with: "cache")
            } else {
                cachePath = deviceCard.directoryPath + ".cache"
            }
            try? FileManager.default.removeItem(atPath: cachePath)
            helper.refreshWalletServices()
            vm.statusMessage = "Applied \(saved.name) to device"
        } catch {
            vm.statusMessage = "Apply failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Saved Card Row

struct SavedCardRow: View {
    let card: SavedCard
    @ObservedObject var vm: MyCardsViewModel
    let exploit: ExploitManager
    let onApply: () -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let image = vm.imageFor(card) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 63)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 63)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.bundleName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(card.displayDate)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))

                HStack(spacing: 8) {
                    Button {
                        onApply()
                    } label: {
                        Label("mycards_apply", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.cyan)

                    Button {
                        onSubmit()
                    } label: {
                        if vm.isSubmitting {
                            ProgressView()
                                .tint(.green)
                                .frame(height: 14)
                        } else {
                            Label("mycards_submit", systemImage: "arrow.up.circle")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(.green)
                    .disabled(vm.isSubmitting)

                    Button {
                        onDelete()
                    } label: {
                        Label("mycards_delete", systemImage: "trash")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.red.opacity(0.8))
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }
}
