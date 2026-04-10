import SwiftUI
import UIKit

private final class CardioAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        false
    }

    func application(_ application: UIApplication,
                     shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        false
    }
}

private enum LaunchStateCleanup {
    static func removeIfPresent(at path: String) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            return
        }

        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            NSLog("CardioDS: failed to remove stale launch state at %@: %@", path, error.localizedDescription)
        }
    }

    static func purgeStaleUIState() {
        guard let libraryDirectory = NSSearchPathForDirectoriesInDomains(
            .libraryDirectory,
            .userDomainMask,
            true
        ).first else {
            return
        }

        let stalePaths = [
            (libraryDirectory as NSString).appendingPathComponent("Saved Application State"),
            (libraryDirectory as NSString).appendingPathComponent("SplashBoard")
        ]

        stalePaths.forEach(removeIfPresent)
    }
}

/// CardioDS entry point.
@main
struct card_testApp: App {
    @UIApplicationDelegateAdaptor(CardioAppDelegate.self) private var appDelegate

    init() {
        LaunchStateCleanup.purgeStaleUIState()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
