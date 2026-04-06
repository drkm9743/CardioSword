import SwiftUI

@main
struct card_testApp: App {
    init() {
        // Try to resolve offsets from cached kernelcache first
        if haskernproc_offset() == 0 {
            _ = dlkerncache()
        }
        init_offsets()
        _ = ExploitManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
