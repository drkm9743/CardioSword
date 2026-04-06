import SwiftUI

// MARK: - Data Model

struct CommunityCard: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let issuer: String
    let country: String
    let category: String
    let imageURL: String
    let author: String?
}

struct CommunityCategory: Identifiable {
    let id: String
    let name: String
    let cards: [CommunityCard]
}

struct CommunityCountrySection: Identifiable {
    let id: String
    let name: String
    let flag: String
    let categories: [CommunityCategory]
}

// MARK: - Built-in Catalog

private let builtInCards: [CommunityCard] = [
    // ── US ── American Express ──
    CommunityCard(id: "american-expres-additional-card", name: "Additional Card", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexadditionaluserbi.png", author: nil),
    CommunityCard(id: "american-expres-amazon-business-prime", name: "Amazon Business Prime", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexamazonbusinesspr.png", author: nil),
    CommunityCard(id: "american-expres-blue-business-plus", name: "Blue Business Plus", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbluebizplus.png", author: nil),
    CommunityCard(id: "american-expres-blue-business-plus-alt-2", name: "Blue Business Plus (alt 2)", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/9/99eab8f209ed358e45631b4d61366eba2de9d2be.jpeg", author: nil),
    CommunityCard(id: "american-expres-blue-cash-everyday", name: "Blue Cash Everyday", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbluecash.png", author: nil),
    CommunityCard(id: "american-expres-blue-cash-preferred", name: "Blue Cash Preferred", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/aiggnhlnous/4.png", author: nil),
    CommunityCard(id: "american-expres-blue-sky", name: "Blue Sky", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbluesky.png", author: nil),
    CommunityCard(id: "american-expres-bunisess-platinum", name: "Bunisess Platinum", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/7/5/e/75e5cc4e3bfa07840c79f71d1784dda3d0a4e6cc_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-business-cash", name: "Business Cash", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/original/4X/d/3/1/d31147c285839141f5d119ce2cc69f454375701d.png", author: nil),
    CommunityCard(id: "american-expres-business-delta-platinum", name: "Business Delta Platinum", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/5/5/f/55f77686898ecffd66c56602c4880dade54aed25_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-business-delta-reserve-747", name: "Business Delta Reserve 747", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/5/1/51f0b27e1e731cd33240cbec7d2dbd4785d2bf3f_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-business-gold", name: "Business Gold", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/cubelin/AMEXBizGold.png", author: nil),
    CommunityCard(id: "american-expres-business-green", name: "Business Green", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbusinessgreen.png", author: nil),
    CommunityCard(id: "american-expres-business-marriot-bonvey", name: "Business Marriot Bonvey", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/2/b/5/2b525bf4eca66460788a494057371e974888b5c3_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-business-platinum", name: "Business Platinum", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexbizplat.png", author: nil),
    CommunityCard(id: "american-expres-business-platinum-alt-2", name: "Business Platinum (alt 2)", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/b/4/3b40b6db6124d30e4db689c2dd7f584afd4d1a95_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-centurion", name: "Centurion", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/973C68E833994E2784CD.jpeg", author: nil),
    CommunityCard(id: "american-expres-companion", name: "Companion", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/b/2/c/b2c52c2b0452fed70577dd8d913d3682bcb94139_2_1380x870.png", author: nil),
    CommunityCard(id: "american-expres-delta-blue", name: "Delta Blue", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/eleboson/aedeltablue.png", author: nil),
    CommunityCard(id: "american-expres-delta-gold", name: "Delta Gold", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/waleyz/4.png", author: nil),
    CommunityCard(id: "american-expres-delta-platinum", name: "Delta Platinum", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexdeltaskymilespla.png", author: nil),
    CommunityCard(id: "american-expres-every-day", name: "Every Day", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexeveryday.png", author: nil),
    CommunityCard(id: "american-expres-every-day-alt-2", name: "Every Day (alt 2)", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/original/4X/6/9/e/69ea319ff49ca0c7e47cee78d2d14c5d79f9114f.jpeg", author: nil),
    CommunityCard(id: "american-expres-every-day-preferred", name: "Every Day Preferred", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/eleboson/aeedp.png", author: nil),
    CommunityCard(id: "american-expres-gold", name: "Gold", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/amexgold.png", author: nil),
    CommunityCard(id: "american-expres-gold-jp", name: "Gold JP", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/7/8/3/7832c963be3c7d99919ea4cbb2cec7c9031e2f89_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-green", name: "Green", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexgreen.png", author: nil),
    CommunityCard(id: "american-expres-green-jp", name: "Green JP", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/2/d/1/2d1d6c916960f51f875c10a94936cd132bd64b64_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-hilton-honors", name: "Hilton Honors", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/9/2/929cd2195ff608e1ad1e02f7f26afcfb1687a957_2_1380x870.png", author: nil),
    CommunityCard(id: "american-expres-hilton-honors-aspire", name: "Hilton Honors Aspire", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/3/a/d3ae0aa6b019df4d82ddf3d10c5f8d917b4fe06a_2_1380x870.png", author: nil),
    CommunityCard(id: "american-expres-hilton-honors-aspire-old", name: "Hilton Honors Aspire old", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexhiltonhonors.png", author: nil),
    CommunityCard(id: "american-expres-hilton-honors-surpass", name: "Hilton Honors Surpass", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/olaf/amexhiltonsurpass.png", author: nil),
    CommunityCard(id: "american-expres-hilton-honors-surpass-old", name: "Hilton Honors Surpass old", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexhiltonsurpass.png", author: nil),
    CommunityCard(id: "american-expres-hilton-honors-old", name: "Hilton Honors old", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexhiltonnofee.png", author: nil),
    CommunityCard(id: "american-expres-marriott-bonvoy", name: "Marriott Bonvoy", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexmarriottbonvoy.png", author: nil),
    CommunityCard(id: "american-expres-marriott-bonvoy-brilliant", name: "Marriott Bonvoy Brilliant", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/original/4X/7/f/2/7f2595e40a739b2140aa8267cb228ba20d039da0.jpeg", author: nil),
    CommunityCard(id: "american-expres-marriott-bonvoy-brilliant-old", name: "Marriott Bonvoy Brilliant old", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexmarriottbonvoybr.png", author: nil),
    CommunityCard(id: "american-expres-platinum", name: "Platinum", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexplat.png", author: nil),
    CommunityCard(id: "american-expres-platinum-alt-2", name: "Platinum (alt 2)", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/original/4X/6/d/d/6dd144913ee8c8614ea33af570af2af097d3995f.jpeg", author: nil),
    CommunityCard(id: "american-expres-platinum-morgan-stanley", name: "Platinum Morgan Stanley", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/amexmsplatinum.png", author: nil),
    CommunityCard(id: "american-expres-platinum-pre", name: "Platinum Pre", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/d/d0527d9fe0be0dd1525b4f3fdb6deee4fbb69262.jpeg", author: nil),
    CommunityCard(id: "american-expres-platinum-schwab", name: "Platinum Schwab", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexplatschwab.png", author: nil),
    CommunityCard(id: "american-expres-platinum-x-kehinde-wiley", name: "Platinum x Kehinde Wiley", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/cubelin/AmexPlatKehindeWiley.png", author: nil),
    CommunityCard(id: "american-expres-plum", name: "Plum", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexplum.png", author: nil),
    CommunityCard(id: "american-expres-rose-gold", name: "Rose Gold", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/ccbackground/amexrosegold.png", author: nil),
    CommunityCard(id: "american-expres-schwab", name: "Schwab", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/1/d/0/1d0713d1778a0db469e7d7b8dd898a5c1a48e7c3_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "american-expres-white-gold", name: "White Gold", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://u.cubeupload.com/olympics/dd0cdd1ce91caa09893d.png", author: nil),
    CommunityCard(id: "american-expres-debit", name: "debit", issuer: "American Express", country: "US", category: "Amex", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/9/7/4/974570e103c9632b118f10b2cec8ecca52d21a14_2_1380x870.png", author: nil),

    // ── US ── Chase ──
    CommunityCard(id: "chase-amazon-not-prime", name: "Amazon (not prime)", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/5/2/f/52f8edc3f2c465c3b07babbdb0a0be97d8667232_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-amazon-prime", name: "Amazon Prime", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseamazonprime.png", author: nil),
    CommunityCard(id: "chase-debit-card", name: "Debit Card", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasedebit.png", author: nil),
    CommunityCard(id: "chase-disney", name: "Disney", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/original/2X/a/a82e789685981015a810b795aaecb8d232d15492.jpeg", author: nil),
    CommunityCard(id: "chase-disney-midnight", name: "Disney Midnight", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasedisneymidnightd.png", author: nil),
    CommunityCard(id: "chase-freedom", name: "Freedom", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasefreedom.png", author: nil),
    CommunityCard(id: "chase-freedom-flex", name: "Freedom Flex", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasefreedomflex.png", author: nil),
    CommunityCard(id: "chase-freedom-unlimited", name: "Freedom Unlimited", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasefreedomunlimite.png", author: nil),
    CommunityCard(id: "chase-frozen", name: "Frozen", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasedisneyfrozen.png", author: nil),
    CommunityCard(id: "chase-hyatt", name: "Hyatt", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/0/b/d0bce031fe61f6742737619ee522053324b4dfef_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-ihg-gold", name: "IHG Gold", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseihggold.png", author: nil),
    CommunityCard(id: "chase-ihg-one-rewards-premier", name: "IHG One Rewards Premier", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/waleyz/3.png", author: nil),
    CommunityCard(id: "chase-ihg-one-rewards-select-old", name: "IHG One Rewards Select (old)", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/2/0/20bb0ccbc2f3baf66bb04d8e4d99f387cece0b8c_2_1380x870.png", author: nil),
    CommunityCard(id: "chase-ink-cash", name: "Ink Cash", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/cubelin/ChaseInkCash.png", author: nil),
    CommunityCard(id: "chase-ink-cash-old", name: "Ink Cash old", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseinkcash.png", author: nil),
    CommunityCard(id: "chase-ink-preferred", name: "Ink Preferred", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseinkpreferred.png", author: nil),
    CommunityCard(id: "chase-ink-unlimited", name: "Ink Unlimited", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/cubelin/CIU.png", author: nil),
    CommunityCard(id: "chase-ink-unlimited-old", name: "Ink Unlimited old", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/7/74e69ad2cfef3fc4e1e4b7b5a49128dbc2a208c3.jpeg", author: nil),
    CommunityCard(id: "chase-j-p-morgan", name: "J.P.Morgan", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/f/9/8/f9891b27b13f1aa13cb5b93fb56a532864977af1_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-marriott-bonvoy-bold", name: "Marriott Bonvoy Bold", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasemarriottbonvoyb.png", author: nil),
    CommunityCard(id: "chase-marriott-bonvoy-boundless", name: "Marriott Bonvoy Boundless", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/waleyz/1.png", author: nil),
    CommunityCard(id: "chase-marriott-bonvoy-boundless-old", name: "Marriott Bonvoy Boundless old", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/599chasemarriottbonvoyb.png", author: nil),
    CommunityCard(id: "chase-platinum-business", name: "Platinum business", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/8/d/8d994e16c361393b148d3709e21e147abba5474a_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-private-client", name: "Private Client", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseprivateclient.png", author: nil),
    CommunityCard(id: "chase-ritz-carlton", name: "Ritz-Carlton", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseritzcarlton.png", author: nil),
    CommunityCard(id: "chase-sapphire-preferred", name: "Sapphire Preferred", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasesapphirepreferr.png", author: nil),
    CommunityCard(id: "chase-sapphire-preferred-alt-2", name: "Sapphire Preferred (alt 2)", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/738chasesapphirepreferr.png", author: nil),
    CommunityCard(id: "chase-sapphire-reserve", name: "Sapphire Reserve", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasesapphirereserve.png", author: nil),
    CommunityCard(id: "chase-sapphire-reserve-biz", name: "Sapphire Reserve Biz", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/f/d/b/fdb97530846c847633a332a8d428edb6a368ffa8_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-southwest-plus", name: "Southwest Plus", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/d35chasesouthwestrapidr.png", author: nil),
    CommunityCard(id: "chase-southwest-premier-business", name: "Southwest Premier Business", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasesouthwestpremie.png", author: nil),
    CommunityCard(id: "chase-southwest-priority", name: "Southwest Priority", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasesouthwestrapidr.png", author: nil),
    CommunityCard(id: "chase-star-wars", name: "Star Wars", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasestarwarsdebit.png", author: nil),
    CommunityCard(id: "chase-star-wars-alt-2", name: "Star Wars (alt 2)", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/4/b/6/4b64ecafd98f5fd74a86aa25cdf95ec79e4803df_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-united-mileage-plus", name: "United Mileage Plus", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasemileageplus.png", author: nil),
    CommunityCard(id: "chase-united-mileage-plus-club", name: "United Mileage Plus CLUB", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/f/0/f02801ad6d23f39b948e2fb6a2485113be44568e_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-united-mileage-plus-explorer", name: "United Mileage Plus Explorer", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chaseunitedexplorer.png", author: nil),
    CommunityCard(id: "chase-united-mileage-plus-gateway", name: "United Mileage Plus Gateway", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/eleboson/chaseuagateway.png", author: nil),
    CommunityCard(id: "chase-united-mileage-plus-gateway-al", name: "United Mileage Plus Gateway (alt 2)", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/9/a/8/9a8eb8f5d1ca12599fb596e575bf243e3370b3d9_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "chase-united-mileage-plus-quest", name: "United Mileage Plus Quest", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/5/7/d57ca8c91263ba95368c7c7babaf1899f6e62a4d_2_1034x652.jpeg", author: nil),
    CommunityCard(id: "chase-world-of-hyatt", name: "World of Hyatt", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://u.cubeupload.com/ccbackground/chasehyatt.png", author: nil),
    CommunityCard(id: "chase-ink-premier", name: "ink premier", issuer: "Chase", country: "US", category: "Chase", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/2/9/29d7117dfe8d3640c67cc79191cde0fafd0b0c3d_2_1380x870.jpeg", author: nil),

    // ── US ── Capital One ──
    CommunityCard(id: "capital-one-capital-one-quick-silver", name: "Capital One Quick Silver", issuer: "Capital One", country: "US", category: "Capital One", imageURL: "https://u.cubeupload.com/ccbackground/quicksilver.png", author: nil),
    CommunityCard(id: "capital-one-capital-one-venture-x", name: "Capital One Venture X", issuer: "Capital One", country: "US", category: "Capital One", imageURL: "https://u.cubeupload.com/cubelin/CapitalOneVentureX.png", author: nil),

    // ── US ── Citi ──
    CommunityCard(id: "citi-aadvantage-executive", name: "AAdvantage Executive", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/original/3X/d/3/d3fb3ed334c97a187b770c3a27afcbab1a492fe8.jpeg", author: nil),
    CommunityCard(id: "citi-aadvantage-mileup", name: "AAdvantage MileUp", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/eleboson/citiaamileup.png", author: nil),
    CommunityCard(id: "citi-aadvantage-platinum-select", name: "AAdvantage Platinum Select", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citiaadvantageplatin.jpg", author: nil),
    CommunityCard(id: "citi-coco", name: "COCO", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/2/2/d22b8878d4fcd27f4333321784a08cfa5052a1b4_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "citi-citibusiness-aadvantage", name: "CitiBusiness AAdvantage", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/f/9/e/f9e643c7c2b0d385577a471a00f8ab29b1d7672b_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "citi-citibusiness-aadvantage-platin", name: "CitiBusiness AAdvantage Platinum Select", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/karlsino/6.png", author: nil),
    CommunityCard(id: "citi-citigold-debit", name: "Citigold Debit", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citigold.png", author: nil),
    CommunityCard(id: "citi-citigold-private-client", name: "Citigold Private Client", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/0/8/08a9edad7f4a76356500b73955bdc2e8c59299ad_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "citi-costco-anywhere", name: "Costco Anywhere", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/eleboson/citicostco.png", author: nil),
    CommunityCard(id: "citi-debit", name: "Debit", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/2/23c79bcab8f3ca55434fc6f30fe04e772c886f27.jpeg", author: nil),
    CommunityCard(id: "citi-dividend", name: "Dividend", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citidividend.png", author: nil),
    CommunityCard(id: "citi-double-cash", name: "Double Cash", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/8/d/38ddd72df2477cef632bdd4e564575cf17b694bc_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "citi-double-cash-old", name: "Double Cash Old", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citidoublecash.png", author: nil),
    CommunityCard(id: "citi-premier", name: "Premier", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/d66citipremier.png", author: nil),
    CommunityCard(id: "citi-premier-pre", name: "Premier Pre", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citipremier.png", author: nil),
    CommunityCard(id: "citi-prestige", name: "Prestige", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/colderplay/cardBackgroundCombin.png", author: nil),
    CommunityCard(id: "citi-rewards", name: "Rewards+", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citirewardsplus.png", author: nil),
    CommunityCard(id: "citi-strata-elite", name: "Strata Elite", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/5/9/5/595ba32f93c34e279c604e9ab4a8c026bf595255_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "citi-strata-premier", name: "Strata Premier", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/f/5/9/f59e914661dee91a13b358cfa88d83617adb81c8_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "citi-strate", name: "Strate", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/6/9/0/690eb1424765b5e42e2e8951c587b5188733dd9d_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "citi-thank-you-preferred", name: "Thank You Preferred", issuer: "Citi", country: "US", category: "Citi", imageURL: "https://u.cubeupload.com/ccbackground/citithankyoupreferre.jpg", author: nil),

    // ── US ── Bank of America ──
    CommunityCard(id: "bank-of-america-alasak-atmos-ascent", name: "Alasak Atmos Ascent", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://asset-cdn.uscardforum.com/original/4X/8/3/1/831f5bf2cc999c235d286dc620f8c34eb5b27727.jpeg", author: nil),
    CommunityCard(id: "bank-of-america-alaska-airlines", name: "Alaska Airlines", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boaalaska.jpg", author: nil),
    CommunityCard(id: "bank-of-america-alaska-atmos-summit", name: "Alaska Atmos Summit", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/a/b/dabc3c8e22f88d250282383d6769dac095d0801a_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "bank-of-america-another-default", name: "Another Default", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boadebit.png", author: nil),
    CommunityCard(id: "bank-of-america-bank-of-america-cal-associatio", name: "Bank of America Cal Association", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://asset-cdn.uscardforum.com/original/3X/b/0/b002f2008eb6e7a6846872241ae91a73778273f3.png", author: nil),
    CommunityCard(id: "bank-of-america-bankamericard", name: "BankAmericard", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/bankamericard.png", author: nil),
    CommunityCard(id: "bank-of-america-better-balance-rewards", name: "Better Balance Rewards", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boabetterbalancerewa.png", author: nil),
    CommunityCard(id: "bank-of-america-boa-brandeis-alumni-associatio", name: "BoA Brandeis Alumni Association", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/eleboson/boadebitbrandeis.png", author: nil),
    CommunityCard(id: "bank-of-america-boa-university-of-michigan-alu", name: "BoA University of Michigan Alumni Debit", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boauniversityofmichi.png", author: nil),
    CommunityCard(id: "bank-of-america-cash-rewards", name: "Cash Rewards", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boacashrewards.png", author: nil),
    CommunityCard(id: "bank-of-america-cash-rewards-2020-mastercard", name: "Cash Rewards 2020 Mastercard", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boacashrewards2020.png", author: nil),
    CommunityCard(id: "bank-of-america-cash-rewards-2020-visa", name: "Cash Rewards 2020 Visa", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/efboacashrewards2020.png", author: nil),
    CommunityCard(id: "bank-of-america-cash-rewards-old", name: "Cash Rewards Old", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://asset-cdn.uscardforum.com/original/4X/d/4/e/d4e45dd7b5001676ba57fe761531f64021641a35.png", author: nil),
    CommunityCard(id: "bank-of-america-columbia", name: "Columbia", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/aiggnhlnous/2.png", author: nil),
    CommunityCard(id: "bank-of-america-custom-cash-rewards-mastercard", name: "Custom Cash Rewards (Mastercard)", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boacustomizedcashmc.png", author: nil),
    CommunityCard(id: "bank-of-america-custom-cash-rewards-visa", name: "Custom Cash Rewards (Visa)", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boacustomizedcashvis.png", author: nil),
    CommunityCard(id: "bank-of-america-default", name: "Default", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/4/41598cd3db51b7c701846744f9d6b18010d9517a.jpeg", author: nil),
    CommunityCard(id: "bank-of-america-mlb", name: "MLB", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boamlb.png", author: nil),
    CommunityCard(id: "bank-of-america-nwf-fox", name: "NWF Fox", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/0/0/a/00a692d8eef13872520f7fab09386574ba03c24d_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "bank-of-america-premium-rewards", name: "Premium Rewards", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boapremiumrewards.png", author: nil),
    CommunityCard(id: "bank-of-america-premium-rewards-alt-2", name: "Premium Rewards (alt 2)", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/7/7602d278ed04cd136fd5fa3405639ae05596a7ce.jpeg", author: nil),
    CommunityCard(id: "bank-of-america-premium-rewards-elite", name: "Premium Rewards Elite", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/7/2/727cb6b3cbfca0847f5b155619d8bb82f66c2405_2_1380x870.png", author: nil),
    CommunityCard(id: "bank-of-america-susan-g-komen", name: "Susan G Komen", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boa123susankomen.jpg", author: nil),
    CommunityCard(id: "bank-of-america-travel-rewards", name: "Travel Rewards", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boatravelrewardsdebi.png", author: nil),
    CommunityCard(id: "bank-of-america-uci", name: "UCI", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boauci.png", author: nil),
    CommunityCard(id: "bank-of-america-utam", name: "UTAM", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://asset-cdn.uscardforum.com/original/4X/3/5/5/3553f2ffd78ebc1aae37898b1f6a86eb0eb6f7b6.jpeg", author: nil),
    CommunityCard(id: "bank-of-america-university-of-michigan", name: "University of Michigan", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/waleyz/2.png", author: nil),
    CommunityCard(id: "bank-of-america-wwf", name: "WWF", issuer: "Bank of America", country: "US", category: "Bank of America", imageURL: "https://u.cubeupload.com/ccbackground/boa123wwf.jpg", author: nil),

    // ── US ── Barclays ──
    CommunityCard(id: "barclays-aadvantage-aviator", name: "AAdvantage Aviator", issuer: "Barclays", country: "US", category: "Barclays", imageURL: "https://u.cubeupload.com/ccbackground/barclaysaadvantageav.png", author: nil),
    CommunityCard(id: "barclays-arrival", name: "Arrival", issuer: "Barclays", country: "US", category: "Barclays", imageURL: "https://u.cubeupload.com/ccbackground/barclayarrival.png", author: nil),
    CommunityCard(id: "barclays-avios", name: "Avios", issuer: "Barclays", country: "US", category: "Barclays", imageURL: "https://asset-cdn.uscardforum.com/original/4X/b/0/d/b0d76a51056d579a3c50033e7f4024522e60478d.jpeg", author: nil),
    CommunityCard(id: "barclays-jetblue", name: "JetBlue", issuer: "Barclays", country: "US", category: "Barclays", imageURL: "https://u.cubeupload.com/aiggnhlnous/3.png", author: nil),
    CommunityCard(id: "barclays-rewards", name: "Rewards", issuer: "Barclays", country: "US", category: "Barclays", imageURL: "https://u.cubeupload.com/ccbackground/barclaysrewards.png", author: nil),
    CommunityCard(id: "barclays-uber", name: "Uber", issuer: "Barclays", country: "US", category: "Barclays", imageURL: "https://u.cubeupload.com/ccbackground/barclaysuber.png", author: nil),

    // ── US ── Discover ──
    CommunityCard(id: "discover-blue", name: "Blue", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/a/a58ffbd46ceaaa9901155bdd3dcf0df38f91536d.jpeg", author: nil),
    CommunityCard(id: "discover-cashback-debit", name: "Cashback Debit", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discovercashbackdebi.png", author: nil),
    CommunityCard(id: "discover-cat", name: "Cat", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/7/8/78b98b396ef105f47b5b330a6dc8aa00ac8bf242_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "discover-city", name: "City", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/17619F418F3F406E8D8A.jpg", author: nil),
    CommunityCard(id: "discover-garnet", name: "Garnet", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discoveritgarnet.png", author: nil),
    CommunityCard(id: "discover-green", name: "Green", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://asset-cdn.uscardforum.com/original/3X/9/c/9cf1c4c96640c78f35d31e54b3f18cb55dfe77dc.jpeg", author: nil),
    CommunityCard(id: "discover-husky", name: "Husky", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/e/8/e8f05f489ca6eedd4c2206f433dca9d371b9c235_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "discover-iridescent", name: "Iridescent", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discoveritiridescent.png", author: nil),
    CommunityCard(id: "discover-mountain", name: "Mountain", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discoveritmountain.png", author: nil),
    CommunityCard(id: "discover-new-york-skyline", name: "New York Skyline", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://asset-cdn.uscardforum.com/original/4X/c/3/f/c3fb7e16138cb25ff627c34f9137c4b6c5451343.png", author: nil),
    CommunityCard(id: "discover-ocean", name: "Ocean", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discoveritdefault.png", author: nil),
    CommunityCard(id: "discover-polar-bear", name: "Polar Bear", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://asset-cdn.uscardforum.com/original/3X/3/6/36853d9fed574f5db043c4ab756723531be49a94.jpeg", author: nil),
    CommunityCard(id: "discover-pride", name: "Pride", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discoverpride.png", author: nil),
    CommunityCard(id: "discover-rose-quartz", name: "Rose Quartz", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discoveritpink.png", author: nil),
    CommunityCard(id: "discover-tiger", name: "Tiger", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://asset-cdn.uscardforum.com/original/4X/0/0/a/00ae1ed17246cc17a62c613d8835cb65f710a78c.jpeg", author: nil),
    CommunityCard(id: "discover-mixtape", name: "mixtape", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discovermixtape.png", author: nil),
    CommunityCard(id: "discover-old", name: "old", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/e/8/2/e8271a7f9708167f16d8d60c5286bc9acb90f4b9_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "discover-wolf", name: "wolf", issuer: "Discover", country: "US", category: "Discover", imageURL: "https://u.cubeupload.com/ccbackground/discoverwolf.jpg", author: nil),

    // ── US ── US Bank ──
    CommunityCard(id: "us-bank-altitude-connect", name: "Altitude Connect", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/7/2/9/729f5bbe430bbf6d22ac53b1d7325909dc9a6b8a_2_1380x870.png", author: nil),
    CommunityCard(id: "us-bank-altitude-connect-biz", name: "Altitude Connect Biz", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/b/a/4/ba46452643287ce95c3d53aef4b27abe86fbca06_2_1380x870.png", author: nil),
    CommunityCard(id: "us-bank-attitude-reserve", name: "Attitude Reserve", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/6/7/6708e3bd2da3897cb79d3a0981c7af457ecfc571_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "us-bank-attitude-reserve-2021", name: "Attitude Reserve 2021/", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://u.cubeupload.com/ccbackground/usbankaltitudereserv.png", author: nil),
    CommunityCard(id: "us-bank-attitude-reserve-2020", name: "Attitude Reserve(2020)", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://u.cubeupload.com/ccbackground/350usbankaltitudereserv.png", author: nil),
    CommunityCard(id: "us-bank-business-triple-cash", name: "Business Triple Cash", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/c/2/5/c25d51470bed92b38c8ab50e5fed7840a9869174_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "us-bank-cash-plus", name: "Cash Plus", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/2/f/32f333393fe68faefccd61e13b52f5d3c3853f53_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "us-bank-cash-plus-alt-2", name: "Cash Plus (alt 2)", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/1/1ebc2ec95a73b2530a16320ea070d2db1678e454.jpeg", author: nil),
    CommunityCard(id: "us-bank-cash-plus-alt-3", name: "Cash Plus (alt 3)", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/usbankcashplus.png", author: nil),
    CommunityCard(id: "us-bank-go", name: "Go", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://u.cubeupload.com/ccbackground/usbankaltitudego.png", author: nil),
    CommunityCard(id: "us-bank-kroger", name: "Kroger", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/9/8/2/982104bc62701869e8ffe951a5cf1da4fb2f39d8_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "us-bank-leverage", name: "Leverage", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://u.cubeupload.com/ccbackground/usbankleverage.png", author: nil),
    CommunityCard(id: "us-bank-pride", name: "Pride", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/d/f/ddf97def9be13605f456a4f784ea835ba1536b9a_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "us-bank-ralphs", name: "Ralphs", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/d/e/dde1cfb57a0cddf8e609395aee9016003011bc80_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "us-bank-second-wave", name: "Second Wave", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/original/4X/3/b/c/3bc5ff48769dcd496bee211436662432620590e7.png", author: nil),
    CommunityCard(id: "us-bank-us-national-flag", name: "US National Flag", issuer: "US Bank", country: "US", category: "US Bank", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/8/c/8cf4b2acfaded373389e64b5ff7fc36ca6669f65_2_1380x870.jpeg", author: nil),

    // ── US ── Wells Fargo ──
    CommunityCard(id: "wells-fargo-wells-fargo-propel", name: "Wells Fargo Propel", issuer: "Wells Fargo", country: "US", category: "Wells Fargo", imageURL: "https://u.cubeupload.com/ccbackground/wellsfargopropel.png", author: nil),

    // ── US ── AB InBev ──
    CommunityCard(id: "ab-inbev-blackhawks-ab-inbev", name: "BlackHawks AB InBev", issuer: "AB InBev", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/6/2/9/629422f4a31ee6c45a05f9a6137c01e6ed674a1f_2_690x434.jpeg", author: nil),

    // ── US ── AOD FCU ──
    CommunityCard(id: "aod-fcu-aod-visa-signature", name: "AOD Visa Signature", issuer: "AOD FCU", country: "US", category: "Other US", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/4/4db7385f832aab11a5be406c66f31e70d098247c.png", author: nil),

    // ── US ── Acorns ──
    CommunityCard(id: "acorns-acorns", name: "Acorns", issuer: "Acorns", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/acornsdebit.png", author: nil),

    // ── US ── Albert ──
    CommunityCard(id: "albert-albert", name: "Albert", issuer: "Albert", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/albert.png", author: nil),

    // ── US ── Apple ──
    CommunityCard(id: "apple-apple-account", name: "Apple Account", issuer: "Apple", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/a/3/7/a37a2757bf52ccdd0070b14d71b3853f131a2203_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "apple-apple-account-alt-2", name: "Apple Account (alt 2)", issuer: "Apple", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/mr06cpp/appleaccount.png", author: nil),
    CommunityCard(id: "apple-apple-cash", name: "Apple Cash", issuer: "Apple", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/FrtHone/AppleCash.png", author: nil),

    // ── US ── Apple / Goldman Sachs ──
    CommunityCard(id: "apple---goldman-apple-card", name: "Apple Card", issuer: "Apple / Goldman Sachs", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/6/c/c/6ccda0da97f0d27763fc58f156fb7ec47e3826b6.jpeg", author: nil),
    CommunityCard(id: "apple---goldman-goldman-sachs-apple-card", name: "Goldman Sachs Apple Card", issuer: "Apple / Goldman Sachs", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/applecard.png", author: nil),

    // ── US ── Bank of Hawaii ──
    CommunityCard(id: "bank-of-hawaii-bank-of-hawaii", name: "Bank of Hawaii", issuer: "Bank of Hawaii", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/6/6/366aee1c73949d2c76deeaf7a825102526ffc680_2_1380x870.jpeg", author: nil),

    // ── US ── Bilt ──
    CommunityCard(id: "bilt-bilt", name: "Bilt", issuer: "Bilt", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/2/a/2/2a2f73f76a7dc28290294accb02cba3cc70d132e_2_1380x870.jpeg", author: nil),

    // ── US ── Brex ──
    CommunityCard(id: "brex-brex-card", name: "Brex Card", issuer: "Brex", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/brex.png", author: nil),
    CommunityCard(id: "brex-brex", name: "Brex金属卡", issuer: "Brex", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/cubelin/Brex.jpeg", author: nil),
    CommunityCard(id: "brex-brex", name: "Brex预算管理虚拟卡", issuer: "Brex", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/cubelin/Brex2.jpeg", author: nil),

    // ── US ── CB&T ──
    CommunityCard(id: "cbandt-cb-amp-t-amazing-cash-for-busi", name: "CB&amp;T AmaZing Cash for Business", issuer: "CB&T", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/6/5/3/653b919bb84a488dc147e532418b584ca8e78d8a.jpeg", author: nil),

    // ── US ── Cardless ──
    CommunityCard(id: "cardless-boston-celtic", name: "Boston Celtic", issuer: "Cardless", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/cardlessbostonceltic.png", author: nil),
    CommunityCard(id: "cardless-cleveland-cavaliers", name: "Cleveland Cavaliers", issuer: "Cardless", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/cardlesscavaliers.png", author: nil),
    CommunityCard(id: "cardless-manchester-united", name: "Manchester United", issuer: "Cardless", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/cardlessmanchesterun.png", author: nil),

    // ── US ── DCU ──
    CommunityCard(id: "dcu-digital-credit-union", name: "Digital Credit Union", issuer: "DCU", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/a41dcudebit.png", author: nil),

    // ── US ── Deserve ──
    CommunityCard(id: "deserve-deserve-edu", name: "Deserve Edu", issuer: "Deserve", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/deserve.png", author: nil),

    // ── US ── E*Trade ──
    CommunityCard(id: "e*trade-etrade", name: "ETrade", issuer: "E*Trade", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/eleboson/oetdebit.png", author: nil),
    CommunityCard(id: "e*trade-etrade-checking", name: "Etrade Checking", issuer: "E*Trade", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/f/5/3/f53aa26d21c2c129fc96db03dd419ce0e4df2671_2_1380x870.jpeg", author: nil),

    // ── US ── Fairwinds ──
    CommunityCard(id: "fairwinds-fairwinds", name: "Fairwinds", issuer: "Fairwinds", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/fairwindsdebit.png", author: nil),

    // ── US ── Fidelity ──
    CommunityCard(id: "fidelity-fidelity", name: "Fidelity", issuer: "Fidelity", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/2/9/3/29362b17b1e104784f65a20358cfaafbbc366412_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "fidelity-fidelity-bloom", name: "Fidelity Bloom", issuer: "Fidelity", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/a/5/a53144eb13aafdbf42f64aedcc1b79ca279cf283_2_1380x870.png", author: nil),
    CommunityCard(id: "fidelity-fidelity-hsa", name: "Fidelity HSA", issuer: "Fidelity", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/aiggnhlnous/1.png", author: nil),

    // ── US ── First Bankcard ──
    CommunityCard(id: "first-bankcard-ducks-unlimited-credit-card", name: "Ducks Unlimited credit card", issuer: "First Bankcard", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/firstbankcarddebit.png", author: nil),

    // ── US ── Fiz ──
    CommunityCard(id: "fiz-fiz", name: "Fiz", issuer: "Fiz", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/0/3/034f4880bc33e3ae28f40147e9a1794739a9cade_2_1380x870.png", author: nil),

    // ── US ── Genisys CU ──
    CommunityCard(id: "genisys-cu-genisys-credit-union", name: "Genisys credit union", issuer: "Genisys CU", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/genisyscreditunion.png", author: nil),

    // ── US ── Gesa CU ──
    CommunityCard(id: "gesa-cu-gesa", name: "Gesa", issuer: "Gesa CU", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/gesadebit.png", author: nil),
    CommunityCard(id: "gesa-cu-gesa-alt-2", name: "Gesa (alt 2)", issuer: "Gesa CU", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/9/d/2/9d2344f9433a74529d66be27fc759c38fd30d174_2_1380x870.png", author: nil),

    // ── US ── HMBradley ──
    CommunityCard(id: "hmbradley-green", name: "Green", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/592hmbradleygreen.png", author: nil),
    CommunityCard(id: "hmbradley-green-vertical", name: "Green vertical", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hmbradleygreen.png", author: nil),
    CommunityCard(id: "hmbradley-hmbradley", name: "HMBradley", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hmbradley.png", author: nil),
    CommunityCard(id: "hmbradley-pink", name: "Pink", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hmbradleypink1.png", author: nil),
    CommunityCard(id: "hmbradley-pink-vertical", name: "Pink vertical", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hmbradleypink2.png", author: nil),
    CommunityCard(id: "hmbradley-teal", name: "Teal", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/6eahmbradleyteal.png", author: nil),
    CommunityCard(id: "hmbradley-teal-vertical", name: "Teal vertical", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hmbradleyteal.png", author: nil),
    CommunityCard(id: "hmbradley-zebra", name: "Zebra", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hmbradleycredit.png", author: nil),
    CommunityCard(id: "hmbradley-zebra-vertical", name: "Zebra vertical", issuer: "HMBradley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hmbradleyzebravertic.png", author: nil),

    // ── US ── HSBC ──
    CommunityCard(id: "hsbc-elite", name: "Elite", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/7/b/7b5b886575ddc3d085ec8c18622621dae279260b_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "hsbc-hsbc-elite", name: "HSBC Elite", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/c/a/1/ca15633a4e885d0f154d5058dfb8323ba63a69d3_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "hsbc-jade-world-elite", name: "Jade World Elite", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/0/04c38416f3b395952fa3a5ef5c186649992f69c5.jpeg", author: nil),
    CommunityCard(id: "hsbc-premier-credit", name: "Premier Credit", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/d/b/5/db5cd1f68c11b28b12f470ef95466de13f19f896_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "hsbc-premier-credit-alt-2", name: "Premier Credit (alt 2)", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/8/6/7/867681d227da752cc1a42f30e683f8fed66f9dd4.jpeg", author: nil),
    CommunityCard(id: "hsbc-premier-debit", name: "Premier Debit", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hsbcpremierdebit.png", author: nil),
    CommunityCard(id: "hsbc-premier-everyday-global-debit", name: "Premier Everyday Global Debit", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/hsbcsg.png", author: nil),
    CommunityCard(id: "hsbc-premier-world", name: "Premier World", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/hsbcpremierworld.png", author: nil),
    CommunityCard(id: "hsbc-premier-world-elite", name: "Premier World Elite", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/6/63ea0bcce734126ad50a5d5402f14003a5d5ae26.jpeg", author: nil),
    CommunityCard(id: "hsbc-red", name: "Red", issuer: "HSBC", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/7/c/4/7c498b201a3b6e87fe86c8609729a3f463d36254.jpeg", author: nil),

    // ── US ── Hyatt ──
    CommunityCard(id: "hyatt-hyatt-digital-key", name: "Hyatt Digital Key", issuer: "Hyatt", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/c/6/5/c6518e35638d84b4c3ccee4f34acd095446db3fe_2_1380x870.png", author: nil),
    CommunityCard(id: "hyatt-hyatt-digital-key-alt-2", name: "Hyatt Digital Key (alt 2)", issuer: "Hyatt", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/mr06cpp/hyattreconstructed.png", author: nil),

    // ── US ── Lili ──
    CommunityCard(id: "lili-lili", name: "Lili", issuer: "Lili", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/lilidebit.png", author: nil),

    // ── US ── Mastercard Gift ──
    CommunityCard(id: "mastercard-gift-emgc", name: "eMGC", issuer: "Mastercard Gift", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/7/b/7b676ffe08995d10791899afaa70d3c734b94dd0_2_1380x870.jpeg", author: nil),

    // ── US ── Mercury ──
    CommunityCard(id: "mercury-mercury-business", name: "Mercury Business", issuer: "Mercury", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/8/3/83a4fefe3256a71e73d4ae11b80390e07189f513_2_1380x870.jpeg", author: nil),

    // ── US ── MetaMask ──
    CommunityCard(id: "metamask-meta-mask", name: "Meta Mask", issuer: "MetaMask", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/9/2/7/92700ba9c657aea4c00822c66e50147100dd1e48_2_1380x870.png", author: nil),

    // ── US ── Monifi ──
    CommunityCard(id: "monifi-monifi", name: "Monifi", issuer: "Monifi", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/monifidebit.png", author: nil),

    // ── US ── Morgan Stanley ──
    CommunityCard(id: "morgan-stanley-morgan-stanley", name: "Morgan Stanley", issuer: "Morgan Stanley", country: "US", category: "Other US", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/5/5fca06b000e38ad14ae3ffc9d78c630b0918e0d7.jpeg", author: nil),
    CommunityCard(id: "morgan-stanley-morgan-stanley-alt-2", name: "Morgan Stanley (alt 2)", issuer: "Morgan Stanley", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/amexmorganstanley.png", author: nil),

    // ── US ── N26 ──
    CommunityCard(id: "n26-n26", name: "N26", issuer: "N26", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/n26debit.png", author: nil),

    // ── US ── Navy Federal ──
    CommunityCard(id: "navy-federal-nfcu-flagship-travel-rewards-c", name: "NFCU Flagship Travel Rewards Credit Card", issuer: "Navy Federal", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/6/b/2/6b239c82775fc06635a076f16cb2c56203d57111.jpeg", author: nil),
    CommunityCard(id: "navy-federal-nfcu-more-rewards-american-exp", name: "NFCU More Rewards American Express® Card", issuer: "Navy Federal", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/e/5/9/e597803cc1f5df2978f354c34715602b0285fdb3.jpeg", author: nil),

    // ── US ── Netspend ──
    CommunityCard(id: "netspend-netspend", name: "Netspend", issuer: "Netspend", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/netspend.png", author: nil),

    // ── US ── OCCU ──
    CommunityCard(id: "occu-occu-the-duck-card", name: "OCCU The Duck Card", issuer: "OCCU", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/occuduckcard.png", author: nil),

    // ── US ── One ──
    CommunityCard(id: "one-one-card", name: "One Card", issuer: "One", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/f/c/3fc586ec35d325e32950738e568a0a297a2ab6b9_2_1380x870.jpeg", author: nil),

    // ── US ── Onjuno ──
    CommunityCard(id: "onjuno-onjuno", name: "Onjuno", issuer: "Onjuno", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/Onjunodebit.png", author: nil),

    // ── US ── PNC ──
    CommunityCard(id: "pnc-pnc-lgbt", name: "PNC LGBT+", issuer: "PNC", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/pnclgbtdebit.png", author: nil),
    CommunityCard(id: "pnc-pnc-university-of-michigan-deb", name: "PNC University of Michigan Debit", issuer: "PNC", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/pncuniversityofmichi.png", author: nil),
    CommunityCard(id: "pnc-pnc-virtual-wallet-debit", name: "PNC Virtual Wallet Debit", issuer: "PNC", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/c/2/f/c2f94d3394f19791500c1217caea85194a476359_2_1380x870.jpeg", author: nil),

    // ── US ── Passbook ──
    CommunityCard(id: "passbook-passbook", name: "Passbook", issuer: "Passbook", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/Passbook.png", author: nil),

    // ── US ── PayPal ──
    CommunityCard(id: "paypal-paypal", name: "Paypal", issuer: "PayPal", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/4/a/4/4a49bea5a2df3916a6f1b25e871923e5efb34b64_2_1380x870.png", author: nil),
    CommunityCard(id: "paypal-the-bancorp-bank-paypal-debit-", name: "The Bancorp Bank: PayPal Debit Mastercard", issuer: "PayPal", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/FrtHone/PayPalDebitMastercar.png", author: nil),

    // ── US ── PenFed ──
    CommunityCard(id: "penfed-penfed-debit", name: "Penfed Debit", issuer: "PenFed", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/penfeddebit.png", author: nil),
    CommunityCard(id: "penfed-penfed-pathfinder", name: "Penfed Pathfinder", issuer: "PenFed", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/penfedpathfinder.png", author: nil),
    CommunityCard(id: "penfed-penfed-power-cash", name: "Penfed Power Cash", issuer: "PenFed", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/penfedpowercash.png", author: nil),

    // ── US ── RBC ──
    CommunityCard(id: "rbc-rbc-avion-vi", name: "RBC Avion VI", issuer: "RBC", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/4/8/48b85055bd2d46a25a70f8fe9b7db0fff57b5cbc_2_1380x870.jpeg", author: nil),

    // ── US ── Revolut ──
    CommunityCard(id: "revolut-revolut", name: "Revolut", issuer: "Revolut", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/revolut.png", author: nil),
    CommunityCard(id: "revolut-revolut-virtual", name: "Revolut Virtual", issuer: "Revolut", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/revolutvirtual.png", author: nil),

    // ── US ── Robinhood ──
    CommunityCard(id: "robinhood-robinhood", name: "Robinhood", issuer: "Robinhood", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/robinhooddebit.png", author: nil),

    // ── US ── Sable ──
    CommunityCard(id: "sable-sable", name: "Sable", issuer: "Sable", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/sable.png", author: nil),

    // ── US ── Santander ──
    CommunityCard(id: "santander-santander", name: "Santander", issuer: "Santander", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/santanderdebit.png", author: nil),

    // ── US ── SecurityPlus FCU ──
    CommunityCard(id: "securityplus-fc-securityplus-federal-credit-un", name: "Securityplus Federal Credit Union", issuer: "SecurityPlus FCU", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/b/8/3/b832a165338aa36d8a5dd5ec04403db47d634015_2_1380x870.jpeg", author: nil),

    // ── US ── SoFi ──
    CommunityCard(id: "sofi-sofi", name: "Sofi", issuer: "SoFi", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/Sofidebit.png", author: nil),

    // ── US ── Spiral ──
    CommunityCard(id: "spiral-spiral", name: "Spiral", issuer: "Spiral", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/spiral.png", author: nil),

    // ── US ── State ID ──
    CommunityCard(id: "state-id-arizona", name: "Arizona", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/0/0/300ebf56d4c24b19e82f3525c1e1f895939921e3_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "state-id-california", name: "California", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/e/a/8/ea8033c10a596a4e14367b0d1c5f1bbd6d89b104_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "state-id-georgia", name: "Georgia", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/4/8/8/488383888284bd14b5d548de6d967972e699151b_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "state-id-hawaii", name: "Hawaii", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/4/8/348c70a1cd7b381d60ac6bcf363acf04425ebcfe_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "state-id-iowa", name: "Iowa", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/2/c/d/2cd99e2053fbbbfb7fc6ebeece49cb84eee62dcf.jpeg", author: nil),
    CommunityCard(id: "state-id-maryland", name: "Maryland", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/7/d/6/7d60474cc323e7aaeeffb5ef8fd654b532fc294f_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "state-id-new-mexico", name: "New Mexico", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/1/f/7/1f7a12b636262ea9b28df9eccaf12c20791b6eb5.jpeg", author: nil),
    CommunityCard(id: "state-id-ohio", name: "Ohio", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/b/e/3be0da9320876456e89fbea5cae5ac9e67c8f15f_2_1380x870.jpeg", author: nil),
    CommunityCard(id: "state-id-puerto-rico", name: "Puerto Rico", issuer: "State ID", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/4/e/5/4e53d683d60fe3728b65968ef658bbce95bc0a14_2_1380x870.jpeg", author: nil),

    // ── US ── Sunflower Bank ──
    CommunityCard(id: "sunflower-bank-sunflower-bank", name: "Sunflower Bank", issuer: "Sunflower Bank", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/sunflowerbank.png", author: nil),

    // ── US ── Sutton Bank ──
    CommunityCard(id: "sutton-bank-sutton-bank-mgc", name: "Sutton Bank MGC", issuer: "Sutton Bank", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/8/7/6/876a4643108a31cd83c6f3b4ca3a9e911ddf9be6_2_1380x870.jpeg", author: nil),

    // ── US ── Synchrony ──
    CommunityCard(id: "synchrony-banana-republic", name: "Banana Republic", issuer: "Synchrony", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/synchonybananarepubl.png", author: nil),
    CommunityCard(id: "synchrony-verizon", name: "Verizon", issuer: "Synchrony", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/synchronyverizon.png", author: nil),

    // ── US ── T-Mobile ──
    CommunityCard(id: "t-mobile-t-mobile-k-amp-s-emgc", name: "T-Mobile K&amp;S eMGC", issuer: "T-Mobile", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/mr06cpp/2.png", author: nil),

    // ── US ── TD ──
    CommunityCard(id: "td-td-aeroplane", name: "TD Aeroplane", issuer: "TD", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/2/3/b/23bda57fbabdb340c5a6b6a264c17da2f7236a70.jpeg", author: nil),
    CommunityCard(id: "td-td-first-class-travel", name: "TD First Class Travel", issuer: "TD", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/4X/5/d/e/5de91ddb924b5f7749ff0aea5b53986e780e59a6.jpeg", author: nil),

    // ── US ── TD Bank ──
    CommunityCard(id: "td-bank-td-bank", name: "TD Bank", issuer: "TD Bank", country: "US", category: "Other US", imageURL: "https://forum.uscreditcardguide.com/uploads/default/original/2X/1/117630ebb572287bc68b578426128ff91d21901c.png", author: nil),
    CommunityCard(id: "td-bank-td-bank-alt-2", name: "TD Bank (alt 2)", issuer: "TD Bank", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/tdbankdebit.png", author: nil),

    // ── US ── Treecard ──
    CommunityCard(id: "treecard-treecard", name: "Treecard", issuer: "Treecard", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/treecard.jpeg", author: nil),

    // ── US ── Upgrade ──
    CommunityCard(id: "upgrade-upgrade", name: "Upgrade", issuer: "Upgrade", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/uscreditcardstrategy/upgrade.png", author: nil),

    // ── US ── Varo ──
    CommunityCard(id: "varo-varo", name: "Varo", issuer: "Varo", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/varo.png", author: nil),

    // ── US ── Venmo ──
    CommunityCard(id: "venmo-venmo", name: "Venmo", issuer: "Venmo", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/eleboson/ovenmodebit.png", author: nil),
    CommunityCard(id: "venmo-venmo-2", name: "Venmo 2", issuer: "Venmo", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/a/d/ad56f8ebb54aff618944c72698937223479f403c_2_1380x870.png", author: nil),

    // ── US ── Verity CU ──
    CommunityCard(id: "verity-cu-verity", name: "Verity", issuer: "Verity CU", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/veritydebit.png", author: nil),

    // ── US ── Wealthsimple ──
    CommunityCard(id: "wealthsimple-wealthsimple", name: "Wealthsimple", issuer: "Wealthsimple", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/9/0/3907bddb75914e2d5355ac411a6eef0cace6aa01_2_1380x870.jpeg", author: nil),

    // ── US ── Workers CU ──
    CommunityCard(id: "workers-cu-workers-credit-union", name: "Workers Credit Union", issuer: "Workers CU", country: "US", category: "Other US", imageURL: "https://u.cubeupload.com/ccbackground/workerscudebit.png", author: nil),

    // ── US ── World Elite ──
    CommunityCard(id: "world-elite-world-elite-business", name: "World Elite Business", issuer: "World Elite", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/3/6/a/36ad342ba14c31b8aea7e5d6ab0197c1d2793cca_2_1380x870.jpeg", author: nil),

    // ── US ── Zelle ──
    CommunityCard(id: "zelle-send", name: "Send", issuer: "Zelle", country: "US", category: "Other US", imageURL: "https://asset-cdn.uscardforum.com/original/3X/8/c/8c3a085c4b84eb1439637fec34b866fc49d48af5.png", author: nil),

    // ── UK ── American Express ──
    CommunityCard(id: "american-expres-amex-british-airways", name: "Amex British Airways", issuer: "American Express", country: "UK", category: "Other UK", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/8/2/826634db56f70764ca7921046068ac5195a71ba1_2_1380x870.jpeg", author: nil),

    // ── UK ── Chase ──
    CommunityCard(id: "chase-chase-uk-debit", name: "Chase UK Debit", issuer: "Chase", country: "UK", category: "Other UK", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/8/b/8b22580df9a5dc391403a02a854c24cc1f025c67_2_1380x870.jpeg", author: nil),

    // ── UK ── Curve ──
    CommunityCard(id: "curve-curve", name: "Curve", issuer: "Curve", country: "UK", category: "Other UK", imageURL: "https://u.cubeupload.com/ccbackground/curve.png", author: nil),

    // ── UK ── Monzo ──
    CommunityCard(id: "monzo-monzo-debit", name: "Monzo Debit", issuer: "Monzo", country: "UK", category: "Other UK", imageURL: "https://u.cubeupload.com/ccbackground/ukmonzo.png", author: nil),

    // ── UK ── Starling Bank ──
    CommunityCard(id: "starling-bank-starling-bank", name: "Starling Bank", issuer: "Starling Bank", country: "UK", category: "Other UK", imageURL: "https://asset-cdn.uscardforum.com/optimized/3X/9/f/9f38f56ca59c43b938cfdf5d20e91c2b8425c008_2_1380x870.png", author: nil),

    // ── EU ── American Express ──
    CommunityCard(id: "american-expres-amex-flying-blue", name: "Amex Flying Blue", issuer: "American Express", country: "EU", category: "Other EU", imageURL: "https://asset-cdn.uscardforum.com/optimized/4X/1/5/4/154522e2a65c974476faa1dbe90f2fa1d2420173_2_1380x870.jpeg", author: nil),
]



// MARK: - View Model

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var cards: [CommunityCard] = builtInCards
    @Published var countrySections: [CommunityCountrySection] = []
    @Published var searchText = ""
    @Published var isLoading = true
    @Published var isSubmitting = false
    @Published var downloadingIDs: Set<String> = []
    @Published var downloadedMessage: String?
    @Published var pendingSaveCard: CommunityCard?
    @Published var pendingSaveData: Data?

    private static let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CommunityCards", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let countryOrder: [(code: String, name: String, flag: String)] = [
        ("US", "United States", "🇺🇸"),
        ("CA", "Canada", "🇨🇦"),
        ("UK", "United Kingdom", "🇬🇧"),
        ("JP", "Japan", "🇯🇵"),
        ("CN", "China", "🇨🇳"),
        ("KR", "South Korea", "🇰🇷"),
        ("AU", "Australia", "🇦🇺"),
        ("HK", "Hong Kong", "🇭🇰"),
        ("SG", "Singapore", "🇸🇬"),
        ("TW", "Taiwan", "🇹🇼"),
        ("EU", "Europe", "🇪🇺"),
    ]

    private let categoryOrder = ["Amex", "Chase", "Capital One", "Citi", "Bank of America", "Barclays", "Discover", "US Bank", "Wells Fargo", "Other US", "Other UK", "Other EU"]

    init() {
        Task { await buildSectionsAsync() }
    }

    private func buildSectionsAsync() async {
        let allCards = cards
        let order = countryOrder
        let catOrder = categoryOrder

        let sections = await Task.detached(priority: .userInitiated) {
            Self.buildSectionsOffMain(cards: allCards, countryOrder: order, categoryOrder: catOrder)
        }.value

        countrySections = sections
        isLoading = false
    }

    private static func buildSectionsOffMain(
        cards: [CommunityCard],
        countryOrder: [(code: String, name: String, flag: String)],
        categoryOrder: [String]
    ) -> [CommunityCountrySection] {
        var byCountry: [String: [CommunityCard]] = [:]
        for card in cards {
            byCountry[card.country, default: []].append(card)
        }

        var sections: [CommunityCountrySection] = []

        for entry in countryOrder {
            guard let countryCards = byCountry.removeValue(forKey: entry.code), !countryCards.isEmpty else { continue }
            let cats = buildCategoriesStatic(from: countryCards, order: categoryOrder)
            sections.append(CommunityCountrySection(id: entry.code, name: entry.name, flag: entry.flag, categories: cats))
        }

        for (code, countryCards) in byCountry.sorted(by: { $0.key < $1.key }) {
            let cats = buildCategoriesStatic(from: countryCards, order: categoryOrder)
            sections.append(CommunityCountrySection(id: code, name: code, flag: "🌐", categories: cats))
        }

        return sections
    }

    private static func buildCategoriesStatic(from cards: [CommunityCard], order: [String]) -> [CommunityCategory] {
        var dict: [String: [CommunityCard]] = [:]
        for card in cards {
            dict[card.category, default: []].append(card)
        }
        var cats: [CommunityCategory] = []
        for key in order {
            if let list = dict.removeValue(forKey: key) {
                cats.append(CommunityCategory(id: key, name: key, cards: list))
            }
        }
        for (key, list) in dict.sorted(by: { $0.key < $1.key }) {
            cats.append(CommunityCategory(id: key, name: key, cards: list))
        }
        return cats
    }

    // MARK: - Submit Custom Card to GitHub

    func submitCustomCard(name: String, image: UIImage) {
        isSubmitting = true
        Task {
            let result = await GitHubService.submitCustomCard(name: name, image: image)
            isSubmitting = false
            downloadedMessage = result.message
        }
    }

    var filteredSections: [CommunityCountrySection] {
        if searchText.isEmpty { return countrySections }
        let q = searchText.lowercased()
        return countrySections.compactMap { section in
            let filteredCats = section.categories.compactMap { cat in
                let filtered = cat.cards.filter {
                    $0.name.lowercased().contains(q) ||
                    $0.issuer.lowercased().contains(q) ||
                    $0.category.lowercased().contains(q)
                }
                return filtered.isEmpty ? nil : CommunityCategory(id: cat.id, name: cat.name, cards: filtered)
            }
            return filteredCats.isEmpty ? nil : CommunityCountrySection(id: section.id, name: section.name, flag: section.flag, categories: filteredCats)
        }
    }

    private func rebuildSections() {
        Task { await buildSectionsAsync() }
    }

    private func buildCategories(from cards: [CommunityCard]) -> [CommunityCategory] {
        Self.buildCategoriesStatic(from: cards, order: categoryOrder)
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
                      httpResp.statusCode == 200,
                      let image = UIImage(data: data),
                      let pngData = image.pngData() else {
                    self?.downloadedMessage = "Download failed: \(error?.localizedDescription ?? "unknown error")"
                    return
                }

                // Cache to disk
                Self.cacheImageData(pngData, for: card.id)

                // Ask user where to save
                self?.pendingSaveData = pngData
                self?.pendingSaveCard = card
            }
        }.resume()
    }

    func saveToGallery() {
        guard let data = pendingSaveData, let image = UIImage(data: data) else { return }
        let card = pendingSaveCard
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        downloadedMessage = "\(card?.name ?? "Card") saved to Gallery"
        clearPending()
    }

    func saveToDocuments() {
        guard let data = pendingSaveData, let card = pendingSaveCard else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let safeName = "\(card.issuer)_\(card.name)"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        let dest = docs.appendingPathComponent("\(safeName).png")
        do {
            try data.write(to: dest, options: .atomic)
            downloadedMessage = "\(card.name) saved to Documents"
        } catch {
            downloadedMessage = "Save failed: \(error.localizedDescription)"
        }
        clearPending()
    }

    func clearPending() {
        pendingSaveCard = nil
        pendingSaveData = nil
    }

    // MARK: - Disk Cache

    static func cacheKey(for cardID: String) -> URL {
        cacheDir.appendingPathComponent("\(cardID).png")
    }

    static func cachedImage(for cardID: String) -> UIImage? {
        let path = cacheKey(for: cardID)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    static func cacheImageData(_ data: Data, for cardID: String) {
        let path = cacheKey(for: cardID)
        try? data.write(to: path, options: .atomic)
    }
}

// MARK: - Community View

struct CommunityView: View {
    @StateObject private var vm = CommunityViewModel()
    @State private var showAlert = false
    @State private var showSaveChoice = false
    @State private var showImagePicker = false
    @State private var pickedImage = UIImage()
    @State private var showNamePrompt = false
    @State private var customCardName = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                    Text("community_title")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("community_title")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)

                    Text("community_subtitle")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField(L("community_search"), text: $vm.searchText)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)

                    // Submit custom card button
                    Button {
                        showImagePicker = true
                    } label: {
                        HStack(spacing: 8) {
                            if vm.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.rectangle.on.folder")
                                    .font(.system(size: 15))
                            }
                            Text(L(vm.isSubmitting ? "custom_submitting" : "custom_submit_button"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.6), Color.cyan.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                    .disabled(vm.isSubmitting)
                    .padding(.horizontal, 16)

                    Text(L("custom_submit_hint"))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 16)

                    // Card grid by country → category
                    ForEach(vm.filteredSections) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(section.flag) \(section.name)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            ForEach(section.categories) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(category.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
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
                        }
                        .padding(.bottom, 8)
                    }

                    // Attribution
                    VStack(alignment: .leading, spacing: 4) {
                        Text("community_attribution")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                        Link("dynalist.io/d/ldKY6rbMR3LPnWz4fTvf_HCh",
                             destination: URL(string: "https://dynalist.io/d/ldKY6rbMR3LPnWz4fTvf_HCh")!)
                        .font(.system(size: 11))
                        .foregroundColor(.cyan.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Ko-fi
                    Link(destination: URL(string: "https://ko-fi.com/argz97")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 13))
                            Text("support_kofi")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(red: 1.0, green: 0.36, blue: 0.36))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // Discord
                    Link(destination: URL(string: "https://discord.com/invite/77FT6fNmBc")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 13))
                            Text("join_discord")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.35, green: 0.39, blue: 0.95))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .padding(.top, 12)
            }
            } // else
        }
        .onChange(of: vm.downloadedMessage) { msg in
            if msg != nil { showAlert = true }
        }
        .onChange(of: vm.pendingSaveCard) { card in
            if card != nil { showSaveChoice = true }
        }
        .alert("Download", isPresented: $showAlert) {
            Button("OK") { vm.downloadedMessage = nil }
        } message: {
            Text(vm.downloadedMessage ?? "")
        }
        .confirmationDialog(
            L("community_save_where"),
            isPresented: $showSaveChoice,
            titleVisibility: .visible
        ) {
            Button(L("community_save_gallery")) {
                vm.saveToGallery()
            }
            Button(L("community_save_documents")) {
                vm.saveToDocuments()
            }
            Button(L("card_cancel"), role: .cancel) {
                vm.clearPending()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $pickedImage)
        }
        .onChange(of: pickedImage) { img in
            if img.size != .zero {
                customCardName = ""
                showNamePrompt = true
            }
        }
        .alert(L("custom_name_title"), isPresented: $showNamePrompt) {
            TextField(L("custom_name_placeholder"), text: $customCardName)
            Button(L("custom_submit_send")) {
                let name = customCardName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                guard !vm.isSubmitting else { return }
                vm.submitCustomCard(name: name, image: pickedImage)
                pickedImage = UIImage()
            }
            Button(L("card_cancel"), role: .cancel) {
                pickedImage = UIImage()
            }
        } message: {
            Text(L("custom_name_message"))
        }
    }
}

// MARK: - Image Loader (replaces AsyncImage for reliability)

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var failed = false
    @Published var loading = false

    private var url: URL?
    private var cardID: String?
    private var retryCount = 0
    private static let maxRetries = 2

    func load(from urlString: String, cardID: String) {
        guard let url = URL(string: urlString) else {
            failed = true
            return
        }
        self.url = url
        self.cardID = cardID
        retryCount = 0

        // Try disk cache first
        if let cached = CommunityViewModel.cachedImage(for: cardID) {
            image = cached
            return
        }

        fetchImage()
    }

    func retry() {
        failed = false
        retryCount = 0
        fetchImage()
    }

    private func fetchImage() {
        guard let url else { return }
        loading = true

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .returnCacheDataElseLoad

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loading = false

                if let data, error == nil,
                   let httpResp = response as? HTTPURLResponse,
                   httpResp.statusCode == 200,
                   let img = UIImage(data: data) {
                    self.image = img
                    // Cache to disk
                    if let id = self.cardID, let pngData = img.pngData() {
                        CommunityViewModel.cacheImageData(pngData, for: id)
                    }
                } else if self.retryCount < Self.maxRetries {
                    self.retryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.retryCount) * 0.5) {
                        self.fetchImage()
                    }
                } else {
                    self.failed = true
                }
            }
        }.resume()
    }
}

// MARK: - Card Cell

struct CommunityCardCell: View {
    let card: CommunityCard
    @ObservedObject var vm: CommunityViewModel
    @StateObject private var loader = RemoteImageLoader()

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let image = loader.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 126)
                        .clipped()
                        .cornerRadius(10)
                } else if loader.failed {
                    placeholder
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.orange)
                                Text("community_tap_retry")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                            }
                        )
                        .onTapGesture {
                            loader.retry()
                        }
                } else {
                    placeholder
                        .overlay(ProgressView().tint(.white))
                }
            }
            .frame(width: 200, height: 126)
            .onAppear {
                if loader.image == nil && !loader.loading {
                    loader.load(from: card.imageURL, cardID: card.id)
                }
            }

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
                    Label("community_download", systemImage: "square.and.arrow.down")
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
