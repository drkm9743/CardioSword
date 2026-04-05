import SwiftUI
import PDFKit

struct Card: Identifiable {
    var imagePath: String
    var directoryPath: String
    var bundleName: String
    var backgroundFileName: String

    var id: String {
        directoryPath
    }
}

private let helper = ObjcHelper()

struct CardView: View {
    let fm = FileManager.default
    let card: Card
    @ObservedObject var exploit: ExploitManager

    @State private var cardImage = UIImage()
    @State private var showSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var imageVersion = 0          // bump to force re-render
    @State private var showSaved = false

    private var cardDirectoryPath: String {
        return card.directoryPath
    }

    private var targetPath: String {
        return cardDirectoryPath + "/" + card.backgroundFileName
    }

    private var backupPath: String {
        return targetPath + ".backup"
    }

    private var cachePath: String {
        if cardDirectoryPath.lowercased().hasSuffix(".pkpass") {
            return cardDirectoryPath.replacingOccurrences(of: "pkpass", with: "cache")
        }
        return cardDirectoryPath + ".cache"
    }

    private func removeCacheIfPresent() {
        if fm.fileExists(atPath: cachePath) {
            try? fm.removeItem(atPath: cachePath)
        }
    }

    private func backupCurrentIfNeeded() throws {
        guard exploit.directWriteReady else {
            return
        }

        if fm.fileExists(atPath: targetPath) && !fm.fileExists(atPath: backupPath) {
            try fm.moveItem(atPath: targetPath, toPath: backupPath)
        }
    }

    private func previewImage() -> UIImage? {
        let lower = card.backgroundFileName.lowercased()

        // Try direct filesystem access first
        if lower.hasSuffix(".pdf") {
            if let doc = PDFDocument(url: URL(fileURLWithPath: card.imagePath)),
               let page = doc.page(at: 0) {
                return page.thumbnail(of: CGSize(width: 640, height: 400), for: .cropBox)
            }
        } else {
            if let img = UIImage(contentsOfFile: card.imagePath) {
                return img
            }
        }

        // Direct access failed (sandbox) — try reading via KFS kernel read
        if let data = helper.kfsReadFile(card.imagePath, maxSize: 8 * 1024 * 1024) {
            if lower.hasSuffix(".pdf") {
                if let doc = PDFDocument(data: data),
                   let page = doc.page(at: 0) {
                    return page.thumbnail(of: CGSize(width: 640, height: 400), for: .cropBox)
                }
            } else {
                return UIImage(data: data)
            }
        }

        // Can't read image data — return nil (UI will show placeholder)
        return nil
    }

    private func guardWriteAccessOrShowError() -> Bool {
        if exploit.canApplyCardChanges {
            return true
        }

        errorMessage = exploit.blockedReason
        showError = true
        return false
    }

    private func applyReplacementData(_ data: Data) {
        if !guardWriteAccessOrShowError() {
            return
        }

        do {
            try backupCurrentIfNeeded()
            try exploit.overwriteWalletFile(targetPath: targetPath, data: data)
            removeCacheIfPresent()
            imageVersion += 1
            helper.refreshWalletServices()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func resetImage() {
        if !guardWriteAccessOrShowError() {
            return
        }

        guard fm.fileExists(atPath: backupPath) else {
            errorMessage = "No backup found for this card"
            showError = true
            return
        }

        do {
            if exploit.directWriteReady {
                if fm.fileExists(atPath: targetPath) {
                    try fm.removeItem(atPath: targetPath)
                }
                try fm.moveItem(atPath: backupPath, toPath: targetPath)
            } else {
                try exploit.overwriteWalletFile(targetPath: targetPath, sourcePath: backupPath)
            }

            removeCacheIfPresent()
            imageVersion += 1
            helper.refreshWalletServices()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func saveToDocuments() {
        guard let image = previewImage() else {
            errorMessage = "Cannot read card image"
            showError = true
            return
        }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let safeName = card.bundleName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let dest = docs.appendingPathComponent("\(safeName).png")

        do {
            if let data = image.pngData() {
                try data.write(to: dest, options: .atomic)
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

    private func setImage(image: UIImage) {
        let lower = card.backgroundFileName.lowercased()

        if lower.hasSuffix(".png") {
            guard let data = image.pngData() else {
                errorMessage = "Could not encode PNG"
                showError = true
                return
            }
            applyReplacementData(data)

        } else if lower.hasSuffix(".pdf") {
            let pdfDocument = PDFDocument()
            guard let page = PDFPage(image: image) else {
                errorMessage = "Unable to create PDF page"
                showError = true
                return
            }
            pdfDocument.insert(page, at: 0)

            guard let data = pdfDocument.dataRepresentation() else {
                errorMessage = "Unable to encode PDF"
                showError = true
                return
            }
            applyReplacementData(data)

        } else {
            errorMessage = "Unknown format"
            showError = true
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Card image (tappable to replace)
            Group {
                if let preview = previewImage() {
                    Image(uiImage: preview)
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
            }
            .id(imageVersion)   // force re-render when bumped
            .onTapGesture {
                if exploit.canApplyCardChanges {
                    showSheet = true
                } else {
                    errorMessage = exploit.blockedReason
                    showError = true
                }
            }
            .sheet(isPresented: $showSheet) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: self.$cardImage)
            }
            .onChange(of: self.cardImage) { newImage in
                setImage(image: newImage)
            }

            Text(card.bundleName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)

            // Action buttons
            HStack(spacing: 16) {
                if fm.fileExists(atPath: backupPath) || imageVersion > 0 {
                    Button {
                        resetImage()
                    } label: {
                        Label("Restore", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.red)
                }

                Button {
                    saveToDocuments()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.system(size: 13))
                }
                .foregroundColor(.cyan)
            }
            .padding(.top, 4)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Saved", isPresented: $showSaved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Card image saved to Documents folder. You can access it in the Files app.")
        }
        }
    }
}
