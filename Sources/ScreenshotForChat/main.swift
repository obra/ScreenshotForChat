// ABOUTME: Entry point for the macOS menubar screenshot app
// ABOUTME: Sets up AppKit-based menubar app instead of SwiftUI for broader compatibility

import AppKit
import Carbon
import Foundation

// Override Bundle.module for KeyboardShortcuts to look in Contents/
extension Foundation.Bundle {
    static let module: Bundle = {
        // Try Contents/ first (where we actually put the bundle for signed apps)
        let contentsPath = Bundle.main.bundleURL.appendingPathComponent("Contents/KeyboardShortcuts_KeyboardShortcuts.bundle").path
        // Fallback to app root (where KeyboardShortcuts expects it)
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("KeyboardShortcuts_KeyboardShortcuts.bundle").path
        // Fallback to build path for development
        let buildPath = Bundle.main.bundleURL.appendingPathComponent("../../../.build/arm64-apple-macosx/release/KeyboardShortcuts_KeyboardShortcuts.bundle").path

        let preferredBundle = Bundle(path: contentsPath) ?? Bundle(path: mainPath) ?? Bundle(path: buildPath)

        guard let bundle = preferredBundle else {
            Swift.fatalError("could not load resource bundle: tried \(contentsPath), \(mainPath), and \(buildPath)")
        }

        return bundle
    }()
}

import KeyboardShortcuts

// Define keyboard shortcut names  
extension KeyboardShortcuts.Name {
    static let windowCapture = Self("windowCapture", default: .init(carbonKeyCode: kVK_ANSI_0, carbonModifiers: Int(cmdKey | shiftKey)))
    static let fullScreenCapture = Self("fullScreenCapture", default: .init(carbonKeyCode: kVK_ANSI_9, carbonModifiers: Int(cmdKey | shiftKey)))
    static let regionCapture = Self("regionCapture", default: .init(carbonKeyCode: kVK_ANSI_8, carbonModifiers: Int(cmdKey | shiftKey)))
}

func checkEarlyResourceAccess() -> Bool {
    // Very early check - can we access our own Info.plist?
    do {
        // Info.plist is in Contents/ not Resources/
        let infoPlistPath = Bundle.main.bundlePath + "/Contents/Info.plist"
        
        // Test if we can read our Info.plist
        _ = try String(contentsOfFile: infoPlistPath)
        return true
    } catch {
        // Show error using bare CoreFoundation since AppKit isn't available yet
        let alert = """
        Resource Access Error
        
        Screenshot for Chat cannot access its own resources.
        
        This usually happens when the app is running from Documents, Desktop, or Downloads without proper permissions.
        
        Please move the app to /Applications/ or grant folder access permissions.
        
        Error: \(error.localizedDescription)
        """
        
        print("❌ Early resource check failed: \(error)")
        print(alert)
        
        // Exit gracefully instead of crashing
        exit(1)
    }
}

func main() {
    // Check resource access before doing anything else
    if !checkEarlyResourceAccess() {
        return
    }
    
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    
    print("🚀 Starting screenshot app...")
    app.run()
}

main()