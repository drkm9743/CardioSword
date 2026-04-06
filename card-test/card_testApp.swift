import SwiftUI

/// CardioDS entry point — initialises kernel offset cache on launch.
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
