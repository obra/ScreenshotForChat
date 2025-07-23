// ABOUTME: Entry point for the macOS menubar screenshot app
// ABOUTME: Sets up AppKit-based menubar app instead of SwiftUI for broader compatibility

import AppKit
import KeyboardShortcuts
import Carbon

// Define keyboard shortcut names  
extension KeyboardShortcuts.Name {
    static let windowCapture = Self("windowCapture", default: .init(carbonKeyCode: kVK_ANSI_0, carbonModifiers: Int(cmdKey | shiftKey)))
    static let fullScreenCapture = Self("fullScreenCapture", default: .init(carbonKeyCode: kVK_ANSI_9, carbonModifiers: Int(cmdKey | shiftKey)))
}

func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    
    print("🚀 Starting screenshot app...")
    app.run()
}

main()