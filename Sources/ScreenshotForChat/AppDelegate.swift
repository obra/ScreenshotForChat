// ABOUTME: AppDelegate handles global hotkeys, menubar, and application lifecycle
// ABOUTME: Creates NSStatusItem menubar and manages keyboard shortcuts

import AppKit
import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

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
        
        // Show first-run launch at login prompt
        showFirstRunPromptIfNeeded()
        
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
            // Create composite icon with camera viewfinder and sparkles
            if let cameraImage = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenshot") {
                // Create a composite image with camera and sparkles
                let compositeImage = createCompositeIcon(cameraImage: cameraImage)
                button.image = compositeImage
            } else {
                // Fallback to text if system symbols aren't available
                button.title = "📷✨"
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
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 528),
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
    
    private func createCompositeIcon(cameraImage: NSImage) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let compositeImage = NSImage(size: size)
        
        compositeImage.lockFocus()
        
        // Set up graphics context for high quality rendering
        guard let context = NSGraphicsContext.current?.cgContext else {
            compositeImage.unlockFocus()
            return cameraImage
        }
        
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.interpolationQuality = .high
        
        // Draw the camera viewfinder as the base, slightly smaller to leave room for sparkles
        let cameraRect = NSRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2)
        cameraImage.draw(in: cameraRect)
        
        // Draw simple sparkle elements using Core Graphics for better control
        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(1.0)
        
        // Draw small sparkles manually for better visibility
        let sparkle1Center = CGPoint(x: size.width - 4, y: size.height - 4)
        let sparkle2Center = CGPoint(x: size.width - 8, y: size.height - 8)
        
        // First sparkle (larger)
        context.move(to: CGPoint(x: sparkle1Center.x, y: sparkle1Center.y - 2))
        context.addLine(to: CGPoint(x: sparkle1Center.x, y: sparkle1Center.y + 2))
        context.move(to: CGPoint(x: sparkle1Center.x - 2, y: sparkle1Center.y))
        context.addLine(to: CGPoint(x: sparkle1Center.x + 2, y: sparkle1Center.y))
        context.strokePath()
        
        // Second sparkle (smaller)
        context.move(to: CGPoint(x: sparkle2Center.x, y: sparkle2Center.y - 1.5))
        context.addLine(to: CGPoint(x: sparkle2Center.x, y: sparkle2Center.y + 1.5))
        context.move(to: CGPoint(x: sparkle2Center.x - 1.5, y: sparkle2Center.y))
        context.addLine(to: CGPoint(x: sparkle2Center.x + 1.5, y: sparkle2Center.y))
        context.strokePath()
        
        compositeImage.unlockFocus()
        
        // Make it template so it adapts to light/dark mode
        compositeImage.isTemplate = true
        
        return compositeImage
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
                alert.informativeText = "Screenshot for Chat is running from \(restrictedPath.components(separatedBy: "/").last ?? "a restricted folder"). For best performance and to avoid permission issues, the app should be moved to /Applications/."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Move to Applications")
                alert.addButton(withTitle: "Quit")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // Attempt to move the app to /Applications/
                    moveToApplications()
                } else {
                    NSApp.terminate(nil)
                }
                break
            }
        }
    }
    
    private func moveToApplications() {
        let bundlePath = Bundle.main.bundlePath
        let appName = (bundlePath as NSString).lastPathComponent
        let destinationPath = "/Applications/\(appName)"
        
        do {
            // First, remove any existing app at the destination
            if FileManager.default.fileExists(atPath: destinationPath) {
                try FileManager.default.removeItem(atPath: destinationPath)
            }
            
            // Copy the app to /Applications/
            try FileManager.default.copyItem(atPath: bundlePath, toPath: destinationPath)
            
            // Show success message and offer to relaunch
            let alert = NSAlert()
            alert.messageText = "App Moved Successfully"
            alert.informativeText = "Screenshot for Chat has been moved to /Applications/. The app will now quit. Please launch it from /Applications/ for the best experience."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            NSApp.terminate(nil)
        } catch {
            // Show error message
            let alert = NSAlert()
            alert.messageText = "Unable to Move App"
            alert.informativeText = "Could not move the app to /Applications/. Error: \(error.localizedDescription)\n\nPlease manually move the app to /Applications/ or another location outside your user folders."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            NSApp.terminate(nil)
        }
    }
    
    private func showFirstRunPromptIfNeeded() {
        let hasShownFirstRunPrompt = UserDefaults.standard.bool(forKey: "hasShownFirstRunPrompt")
        
        if !hasShownFirstRunPrompt {
            // Mark as shown so we don't show it again
            UserDefaults.standard.set(true, forKey: "hasShownFirstRunPrompt")
            
            // Show the prompt after a brief delay to let the app finish launching
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let alert = NSAlert()
                alert.messageText = "Welcome to Screenshot for Chat!"
                alert.informativeText = "Would you like Screenshot for Chat to launch automatically when you log in? You can change this later in Settings."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Launch at Login")
                alert.addButton(withTitle: "Not Now")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    LaunchAtLogin.isEnabled = true
                }
            }
        }
    }
}