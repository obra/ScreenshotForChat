// ABOUTME: AppDelegate handles global hotkeys, menubar, and application lifecycle
// ABOUTME: Creates NSStatusItem menubar and manages keyboard shortcuts

import AppKit
import SwiftUI
import KeyboardShortcuts

class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up any references when window closes
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.settingsWindowController = nil
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let captureManager: CaptureManager = {
        if #available(macOS 14.0, *) {
            return CaptureManager()
        } else {
            fatalError("ScreenCaptureKit requires macOS 14.0 or later")
        }
    }()
    private var statusItem: NSStatusItem!
    var settingsWindowController: NSWindowController?
    private var settingsWindowDelegate: SettingsWindowDelegate?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Screenshot for Chat starting...")
        
        // Check if we can safely access our own resources
        if !checkResourceAccess() {
            showResourceAccessError()
            return
        }
        
        // Check if we're running from a restricted location
        checkForRestrictedLocation()
        
        // Run as agent (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Create menubar item
        setupMenuBar()
        
        // Set up keyboard shortcut handlers
        setupKeyboardShortcuts()
        
        print("✅ App setup complete")
    }
    
    @MainActor
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenshot") {
                button.image = image
            } else {
                button.title = "✨"
            }
        }
        
        let menu = NSMenu()
        
        // Get current shortcuts for display
        let windowShortcut = KeyboardShortcuts.getShortcut(for: .windowCapture)
        let fullScreenShortcut = KeyboardShortcuts.getShortcut(for: .fullScreenCapture)
        
        let windowItem = NSMenuItem(title: "Capture Window", action: #selector(captureWindow), keyEquivalent: "")
        if let shortcut = windowShortcut {
            windowItem.title = "Capture Window"
            windowItem.keyEquivalent = shortcut.nsMenuItemKeyEquivalent ?? ""
            windowItem.keyEquivalentModifierMask = shortcut.modifiers
        }
        menu.addItem(windowItem)
        
        let fullScreenItem = NSMenuItem(title: "Capture Full Screen", action: #selector(captureFullScreen), keyEquivalent: "")
        if let shortcut = fullScreenShortcut {
            fullScreenItem.title = "Capture Full Screen"
            fullScreenItem.keyEquivalent = shortcut.nsMenuItemKeyEquivalent ?? ""
            fullScreenItem.keyEquivalentModifierMask = shortcut.modifiers
        }
        menu.addItem(fullScreenItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))
        
        statusItem.menu = menu
        print("📋 Menubar created")
    }
    
    @objc private func captureWindow() {
        captureManager.startWindowPicker()
    }
    
    @objc private func captureFullScreen() {
        captureManager.captureFullScreen()
    }
    
    @objc private func showSettings() {
        // Always create a fresh settings window to avoid state issues
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentViewController = hostingController
        window.center()
        
        // Set up window delegate to clean up when closed
        settingsWindowDelegate = SettingsWindowDelegate()
        window.delegate = settingsWindowDelegate
        
        let windowController = NSWindowController(window: window)
        settingsWindowController = windowController
        
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    private func setupKeyboardShortcuts() {
        // Window capture shortcut
        KeyboardShortcuts.onKeyUp(for: .windowCapture) { [weak self] in
            print("🎯 Window capture triggered")
            self?.captureManager.startWindowPicker()
        }
        
        // Full screen capture shortcut
        KeyboardShortcuts.onKeyUp(for: .fullScreenCapture) { [weak self] in
            print("📸 Full screen capture triggered")
            self?.captureManager.captureFullScreen()
        }
        
        print("⌨️ Keyboard shortcuts registered")
    }
    
    private func checkResourceAccess() -> Bool {
        // Test 1: Can we access our own Info.plist?
        let infoPlistPath = Bundle.main.bundlePath + "/Contents/Info.plist"
        guard FileManager.default.fileExists(atPath: infoPlistPath) else {
            print("❌ Info.plist does not exist at \(infoPlistPath)")
            return false
        }
        
        // Test 2: Can we read from our Info.plist?
        do {
            _ = try String(contentsOfFile: infoPlistPath)
            print("✅ Info.plist accessible")
        } catch {
            print("❌ Cannot read Info.plist: \(error)")
            return false
        }
        
        // Test 3: Can we access the KeyboardShortcuts bundle?
        let keyboardShortcutsBundle = Bundle.main.bundlePath + "/Contents/KeyboardShortcuts_KeyboardShortcuts.bundle"
        if !FileManager.default.fileExists(atPath: keyboardShortcutsBundle) {
            print("❌ Cannot access KeyboardShortcuts bundle at \(keyboardShortcutsBundle)")
            return false
        }
        
        // Test 4: Can we create the KeyboardShortcuts bundle object?
        guard Bundle(path: keyboardShortcutsBundle) != nil else {
            print("❌ Cannot create Bundle from KeyboardShortcuts path")
            return false
        }
        
        print("✅ All resource access checks passed")
        return true
    }
    
    private func showResourceAccessError() {
        let alert = NSAlert()
        alert.messageText = "Resource Access Error"
        alert.informativeText = "Screenshot for Chat cannot access its own resources. This usually happens when:\n\n• The app is running from Documents, Desktop, or Downloads without proper permissions\n• The app bundle is incomplete or corrupted\n\nPlease move the app to /Applications/ or grant folder access permissions."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        
        alert.runModal()
        NSApp.terminate(nil)
    }
    
    private func checkForRestrictedLocation() {
        let bundlePath = Bundle.main.bundlePath
        let homeDir = NSHomeDirectory()
        
        let restrictedPaths = [
            "\(homeDir)/Documents",
            "\(homeDir)/Desktop", 
            "\(homeDir)/Downloads"
        ]
        
        for restrictedPath in restrictedPaths {
            if bundlePath.hasPrefix(restrictedPath) {
                let alert = NSAlert()
                alert.messageText = "App Location Warning"
                alert.informativeText = "Screenshot for Chat is running from \(restrictedPath.components(separatedBy: "/").last ?? "a restricted folder"). For best performance and to avoid permission issues, please move the app to /Applications/ or another location outside your user folders."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Continue Anyway")
                alert.addButton(withTitle: "Quit")
                
                let response = alert.runModal()
                if response == .alertSecondButtonReturn {
                    NSApp.terminate(nil)
                }
                break
            }
        }
    }
}