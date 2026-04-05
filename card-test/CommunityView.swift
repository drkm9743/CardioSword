import SwiftUI

// MARK: - Data Model

struct CommunityCard: Identifiable, Codable {
    let id: String
    let name: String
    let issuer: String
    let category: String
    let imageURL: String
    let author: String?
}

struct CommunityCategory: Identifiable {
    let id: String
    let name: String
    let cards: [CommunityCard]
}

// MARK: - Built-in Catalog

private let builtInCards: [CommunityCard] = [
    // American Express
    CommunityCard(id: "amex-gold", name: "Gold Card", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexgold.png", author: nil),
    CommunityCard(id: "amex-platinum", name: "Platinum Card", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexplatinum.png", author: nil),
    CommunityCard(id: "amex-biz-gold", name: "Business Gold", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/cubelin/AMEXBizGold.png", author: nil),
    CommunityCard(id: "amex-biz-plat", name: "Business Platinum", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbizplat.png", author: nil),
    CommunityCard(id: "amex-blue-biz-plus", name: "Blue Business Plus", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbluebizplus.png", author: nil),
    CommunityCard(id: "amex-biz-green", name: "Business Green", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbusinessgreen.png", author: nil),
    CommunityCard(id: "amex-amazon-biz", name: "Amazon Business Prime", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexamazonbusinesspr.png", author: nil),
    CommunityCard(id: "amex-green", name: "Green Card", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexgreen.png", author: nil),
    CommunityCard(id: "amex-cobalt", name: "Cobalt Card", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexcobalt.png", author: nil),
    CommunityCard(id: "amex-centurion", name: "Centurion (Black)", issuer: "American Express", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexcenturion.png", author: nil),

    // Chase
    CommunityCard(id: "chase-sapphire-pref", name: "Sapphire Preferred", issuer: "Chase", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasesapphireprefer.png", author: nil),
    CommunityCard(id: "chase-sapphire-res", name: "Sapphire Reserve", issuer: "Chase", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasesapphirereserv.png", author: nil),
    CommunityCard(id: "chase-freedom-unl", name: "Freedom Unlimited", issuer: "Chase", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasefreedomultimat.png", author: nil),
    CommunityCard(id: "chase-amazon", name: "Amazon Prime Visa", issuer: "Chase", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseamazon.png", author: nil),
    CommunityCard(id: "chase-united-exp", name: "United Explorer", issuer: "Chase", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseunitedexplorer.png", author: nil),

    // Capital One
    CommunityCard(id: "cap1-venture-x", name: "Venture X", issuer: "Capital One", category: "Capital One", imageURL: "https://u.cubeupload.com/ccbackground/capitalonventurex.png", author: nil),
    CommunityCard(id: "cap1-venture", name: "Venture", issuer: "Capital One", category: "Capital One", imageURL: "https://u.cubeupload.com/ccbackground/capitalonventure.png", author: nil),
    CommunityCard(id: "cap1-savor", name: "SavorOne", issuer: "Capital One", category: "Capital One", imageURL: "https://u.cubeupload.com/ccbackground/capitalonsavorone.png", author: nil),
    CommunityCard(id: "cap1-quicksilver", name: "Quicksilver", issuer: "Capital One", category: "Capital One", imageURL: "https://u.cubeupload.com/ccbackground/capitalonquicksilve.png", author: nil),

    // Citi
    CommunityCard(id: "citi-custom-cash", name: "Custom Cash", issuer: "Citi", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citicustomcash.png", author: nil),
    CommunityCard(id: "citi-double-cash", name: "Double Cash", issuer: "Citi", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citidoublecash.png", author: nil),
    CommunityCard(id: "citi-premier", name: "Premier", issuer: "Citi", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citizpremier.png", author: nil),
    CommunityCard(id: "citi-strata-premier", name: "Strata Premier", issuer: "Citi", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citiStrataPremier.png", author: nil),

    // Discover
    CommunityCard(id: "discover-it", name: "Discover it", issuer: "Discover", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/discoverit.png", author: nil),

    // US Bank
    CommunityCard(id: "usbank-altitude-res", name: "Altitude Reserve", issuer: "US Bank", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/usbankaltitudereser.png", author: nil),

    // Wells Fargo
    CommunityCard(id: "wf-autograph", name: "Autograph", issuer: "Wells Fargo", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/wellsfargonautograp.png", author: nil),

    // Apple
    CommunityCard(id: "apple-card", name: "Apple Card", issuer: "Apple", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/applecard.png", author: nil),

    // Bilt
    CommunityCard(id: "bilt-mc", name: "Bilt Mastercard", issuer: "Bilt", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/bilt.png", author: nil),
]

// MARK: - View Model

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var cards: [CommunityCard] = builtInCards
    @Published var categories: [CommunityCategory] = []
    @Published var searchText = ""
    @Published var downloadingIDs: Set<String> = []
    @Published var downloadedMessage: String?

    init() {
        rebuildCategories()
    }

    var filteredCategories: [CommunityCategory] {
        if searchText.isEmpty { return categories }
        let q = searchText.lowercased()
        return categories.compactMap { cat in
            let filtered = cat.cards.filter {
                $0.name.lowercased().contains(q) ||
                $0.issuer.lowercased().contains(q) ||
                $0.category.lowercased().contains(q)
            }
            return filtered.isEmpty ? nil : CommunityCategory(id: cat.id, name: cat.name, cards: filtered)
        }
    }

    private func rebuildCategories() {
        var dict: [String: [CommunityCard]] = [:]
        for card in cards {
            dict[card.category, default: []].append(card)
        }
        let order = ["Amex", "Chase", "Capital One", "Citi", "Other US"]
        categories = order.compactMap { key in
            guard let list = dict[key] else { return nil }
            return CommunityCategory(id: key, name: key, cards: list)
        }
        // Any remaining categories not in the order
        for (key, list) in dict where !order.contains(key) {
            categories.append(CommunityCategory(id: key, name: key, cards: list))
        }
    }

    func downloadCard(_ card: CommunityCard) {
        guard !downloadingIDs.contains(card.id) else { return }
        downloadingIDs.insert(card.id)

        guard let url = URL(string: card.imageURL) else {
            downloadingIDs.remove(card.id)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.downloadingIDs.remove(card.id)
                guard let data = data, error == nil,
                      let httpResp = response as? HTTPURLResponse,
                      httpResp.statusCode == 200 else {
                    self?.downloadedMessage = "Download failed: \(error?.localizedDescription ?? "unknown error")"
                    return
                }

                // Save to Documents
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let safeName = "\(card.issuer)_\(card.name)"
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "/", with: "_")

                let ext = card.imageURL.lowercased().hasSuffix(".png") ? "png" : "png"
                let dest = docs.appendingPathComponent("\(safeName).\(ext)")

                do {
                    // Convert to PNG if needed
                    if let image = UIImage(data: data), let pngData = image.pngData() {
                        try pngData.write(to: dest, options: .atomic)
                    } else {
                        try data.write(to: dest, options: .atomic)
                    }
                    self?.downloadedMessage = "\(card.name) saved to Documents"
                } catch {
                    self?.downloadedMessage = "Save failed: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - Community View

struct CommunityView: View {
    @StateObject private var vm = CommunityViewModel()
    @State private var showAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Community Cards")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)

                    Text("Download card backgrounds and apply them from your photo library.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search cards...", text: $vm.searchText)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)

                    // Card grid by category
                    ForEach(vm.filteredCategories) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(category.cards) { card in
                                        CommunityCardCell(card: card, vm: vm)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // Attribution
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Card images from the community at")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                        Link("dynalist.io/d/ldKY6rbMR3LPnWz4fTvf_HCh",
                             destination: URL(string: "https://dynalist.io/d/ldKY6rbMR3LPnWz4fTvf_HCh")!)
                        .font(.system(size: 11))
                        .foregroundColor(.cyan.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .padding(.top, 12)
            }
        }
        .onChange(of: vm.downloadedMessage) { msg in
            if msg != nil { showAlert = true }
        }
        .alert("Download", isPresented: $showAlert) {
            Button("OK") { vm.downloadedMessage = nil }
        } message: {
            Text(vm.downloadedMessage ?? "")
        }
    }
}

// MARK: - Card Cell

struct CommunityCardCell: View {
    let card: CommunityCard
    @ObservedObject var vm: CommunityViewModel

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: card.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 126)
                        .clipped()
                        .cornerRadius(10)
                case .failure:
                    placeholder
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        )
                case .empty:
                    placeholder
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 200, height: 126)

            Text(card.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 200)

            Text(card.issuer)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))

            Button {
                vm.downloadCard(card)
            } label: {
                if vm.downloadingIDs.contains(card.id) {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 28)
                } else {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .medium))
                        .frame(height: 28)
                }
            }
            .frame(width: 180, height: 32)
            .background(Color.white.opacity(0.15))
            .cornerRadius(8)
            .foregroundColor(.cyan)
        }
        .padding(.vertical, 4)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.08))
            .frame(width: 200, height: 126)
    }
}
