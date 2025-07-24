// ABOUTME: AppDelegate handles global hotkeys, menubar, and application lifecycle
// ABOUTME: Creates NSStatusItem menubar and manages keyboard shortcuts

import AppKit
import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin
import ScreenCaptureKit

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
        let isInRestrictedLocation = checkForRestrictedLocation()
        
        // Show first-run launch at login prompt (this will handle permission setup too)
        // Skip if we're in a restricted location since we'll be moving to Applications
        let isFirstRun = !UserDefaults.standard.bool(forKey: "hasShownFirstRunPrompt")
        if !isInRestrictedLocation {
            showFirstRunPromptIfNeeded()
        }
        
        // Check if we need to do permission setup (only for Applications relaunches)
        // This won't run on first run since we detected it above
        if !isFirstRun {
            checkIfPermissionSetupNeeded()
        }
        
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
            // Use the custom menubar icon
            if let menubarImage = loadMenubarIcon() {
                button.image = menubarImage
            } else {
                // Fallback to system symbol if custom icon not found
                if let cameraImage = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenshot") {
                    button.image = cameraImage
                } else {
                    button.title = "📷"
                }
            }
        }
        
        let menu = NSMenu()
        
        // Get current shortcuts for display
        let windowShortcut = KeyboardShortcuts.getShortcut(for: .windowCapture)
        let fullScreenShortcut = KeyboardShortcuts.getShortcut(for: .fullScreenCapture)
        let regionShortcut = KeyboardShortcuts.getShortcut(for: .regionCapture)
        
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
        
        let regionItem = NSMenuItem(title: "Capture Region", action: #selector(captureRegion), keyEquivalent: "")
        if let shortcut = regionShortcut {
            regionItem.title = "Capture Region"
            regionItem.keyEquivalent = shortcut.nsMenuItemKeyEquivalent ?? ""
            regionItem.keyEquivalentModifierMask = shortcut.modifiers
        }
        menu.addItem(regionItem)
        
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
    
    @objc private func captureRegion() {
        captureManager.captureRegion()
    }
    
    @objc private func showSettings() {
        // Always create a fresh settings window to avoid state issues
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 548),
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
        
        // Region capture shortcut
        KeyboardShortcuts.onKeyUp(for: .regionCapture) { [weak self] in
            print("📱 Region capture triggered")
            self?.captureManager.captureRegion()
        }
        
        print("⌨️ Keyboard shortcuts registered")
    }
    
    private func loadMenubarIcon() -> NSImage? {
        // Try to load the custom menubar icon from the app bundle
        guard let resourcePath = Bundle.main.resourcePath else {
            print("⚠️ Could not find app bundle resource path")
            return nil
        }
        
        // Load the appropriate size for the current display
        let iconPath = "\(resourcePath)/menubar_16x16.png"
        
        if let image = NSImage(contentsOfFile: iconPath) {
            // Make it a template image so it adapts to light/dark mode
            image.isTemplate = true
            print("✅ Loaded custom menubar icon from \(iconPath)")
            return image
        } else {
            print("⚠️ Could not load menubar icon from \(iconPath)")
            return nil
        }
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
    
    private func checkForRestrictedLocation() -> Bool {
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
                return true
            }
        }
        return false
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
            
            // Launch the Applications version and quit this one (no success dialog needed)
            launchApplicationsVersionAndQuit(destinationPath: destinationPath)
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
    
    private func launchApplicationsVersionAndQuit(destinationPath: String) {
        // Use Process to launch the Applications version more reliably
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [destinationPath]
        
        do {
            try process.run()
            print("✅ Successfully launched Applications version")
            
            // Quit this instance after a brief delay to ensure the new app starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApp.terminate(nil)
            }
        } catch {
            print("❌ Failed to launch Applications version: \(error)")
            
            // If launch fails, just quit - user can manually launch from Applications
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
        }
    }
    
    private func showFirstRunPromptIfNeeded() {
        let hasShownFirstRunPrompt = UserDefaults.standard.bool(forKey: "hasShownFirstRunPrompt")
        
        if !hasShownFirstRunPrompt {
            // Mark as shown so we don't show it again
            UserDefaults.standard.set(true, forKey: "hasShownFirstRunPrompt")
            
            // Show the welcome flow after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showFirstRunWelcomeAndPermissions()
            }
        }
    }
    
    private func showFirstRunWelcomeAndPermissions() {
        // Step 1: Welcome and launch at login setup
        let welcomeAlert = NSAlert()
        welcomeAlert.messageText = "Welcome to Screenshot for Chat!"
        welcomeAlert.informativeText = "Would you like Screenshot for Chat to launch automatically when you log in? You can change this later in Settings.\n\nAfter this, we'll need to set up screen recording permissions."
        welcomeAlert.alertStyle = .informational
        welcomeAlert.addButton(withTitle: "Launch at Login & Continue")
        welcomeAlert.addButton(withTitle: "Skip Launch at Login & Continue")
        welcomeAlert.addButton(withTitle: "Cancel")
        
        let launchResponse = welcomeAlert.runModal()
        if launchResponse == .alertFirstButtonReturn {
            LaunchAtLogin.isEnabled = true
            // User chose to continue - show permission setup
            if !UserDefaults.standard.bool(forKey: "hasCompletedPermissionSetup") {
                checkAndRequestScreenRecordingPermission()
            }
        } else if launchResponse == .alertSecondButtonReturn {
            // User chose to skip launch at login but continue - show permission setup
            if !UserDefaults.standard.bool(forKey: "hasCompletedPermissionSetup") {
                checkAndRequestScreenRecordingPermission()
            }
        } else {
            // User cancelled - mark as completed to avoid showing again
            UserDefaults.standard.set(true, forKey: "hasCompletedPermissionSetup")
        }
    }
    
    @available(macOS 14.0, *)
    private func checkIfPermissionSetupNeeded() {
        let hasCompletedPermissionSetup = UserDefaults.standard.bool(forKey: "hasCompletedPermissionSetup")
        let isRunningFromApplications = Bundle.main.bundlePath.hasPrefix("/Applications/")
        let hasShownFirstRunPrompt = UserDefaults.standard.bool(forKey: "hasShownFirstRunPrompt")
        
        // Only handle Applications relaunch case (after first run is complete)
        // First run permission setup is handled by showFirstRunWelcome()
        // Don't run if first run flow hasn't been shown yet (it will handle permissions)
        if !hasCompletedPermissionSetup && isRunningFromApplications && hasShownFirstRunPrompt {
            // Mark that we've run from Applications
            UserDefaults.standard.set(true, forKey: "hasRunFromApplications")
            
            // Show permission setup for Applications relaunch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkAndRequestScreenRecordingPermission()
            }
        }
    }
    
    @available(macOS 14.0, *)
    private func checkPermissionsOnStartup() {
        // Don't check permissions on regular startup to avoid triggering system dialogs
        // Let permissions be checked naturally when user actually tries to take a screenshot
        // This prevents unwanted system dialogs on every app launch
        print("🔄 Skipping permission check on startup - will check when needed")
    }
    
    private func showPermissionRequiredDialog() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Screenshot for Chat needs Screen Recording permission to capture your screen.\n\nClick \"Open System Settings\" to grant permission, then return to this app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Remind Me Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Privacy & Security > Screen & System Audio Recording
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @available(macOS 14.0, *)
    private func checkAndRequestScreenRecordingPermission() {
        // First show our custom permission dialog without triggering system dialog
        showScreenRecordingPermissionDialog()
    }
    
    private func showScreenRecordingPermissionDialog() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Screenshot for Chat needs Screen Recording permission to capture your screen.\n\nAfter clicking \"Continue\", macOS will ask for permission. Please click \"Allow\" in the system dialog that appears."
        alert.alertStyle = .informational
        
        // Add buttons in reverse order for proper vertical layout (primary button on top)
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Skip for Now")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Mark permission setup as completed BEFORE triggering system dialog
            // This prevents re-prompting after system relaunch
            UserDefaults.standard.set(true, forKey: "hasCompletedPermissionSetup")
            
            // Now trigger the system permission dialog by trying to access screen content
            triggerSystemPermissionDialog()
        } else {
            // User skipped, show completion message
            showPermissionGrantedMessage()
        }
    }
    
    @available(macOS 14.0, *)
    private func triggerSystemPermissionDialog() {
        // Trigger the system permission dialog and wait for user interaction
        Task {
            // First attempt - this will show the system dialog if permission not granted
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                // If this succeeds immediately, permission was already granted
                await MainActor.run {
                    self.showPermissionGrantedMessage()
                }
            } catch {
                // Permission dialog should have appeared - wait for user to interact with it
                // Then check again after a reasonable delay
                await MainActor.run {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.checkPermissionAfterDialog()
                    }
                }
            }
        }
    }
    
    @available(macOS 14.0, *)
    private func checkPermissionAfterDialog() {
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                // Permission now granted
                await MainActor.run {
                    self.showPermissionGrantedMessage()
                }
            } catch {
                // Still no permission - show completion anyway
                await MainActor.run {
                    self.showPermissionGrantedMessage()
                }
            }
        }
    }
    
    private func showPermissionGrantedMessage() {
        // Note: hasCompletedPermissionSetup flag is set earlier to survive system relaunch
        
        let alert = NSAlert()
        alert.messageText = "All Set!"
        alert.informativeText = "Screenshot for Chat is ready to use. You can:\n\n• Use global keyboard shortcuts (configurable in Settings)\n• Click the camera icon in the menu bar\n• Take window or full-screen captures\n\nScreenshots are saved to your temp folder and the path is copied to your clipboard for easy sharing."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got It!")
        
        alert.runModal()
    }
    
    private func loadCustomAlertIcon() -> NSImage? {
        // Load PNG directly and create NSImage with explicit alpha handling
        guard let resourcePath = Bundle.main.resourcePath else {
            print("⚠️ Could not get resource path")
            return nil
        }
        
        // Try loading PNG directly from iconset folder
        let pngPath = "\(resourcePath)/../../../Resources/ScreenshotForChat.iconset/icon_256x256.png"
        print("🎨 Trying to load PNG directly from: \(pngPath)")
        
        if FileManager.default.fileExists(atPath: pngPath),
           let imageData = NSData(contentsOfFile: pngPath) {
            
            // Create NSImage from data to better preserve alpha
            let image = NSImage(data: imageData as Data)
            
            if let nsImage = image {
                print("✅ Successfully loaded PNG with data method")
                
                // Create new image with explicit alpha support
                let targetSize = NSSize(width: 64, height: 64)
                let newImage = NSImage(size: targetSize)
                
                newImage.lockFocus()
                
                // Set up graphics context for proper alpha blending
                if let context = NSGraphicsContext.current?.cgContext {
                    context.setBlendMode(.normal)
                    context.setShouldAntialias(true)
                    context.setAllowsAntialiasing(true)
                }
                
                // Draw with source-over to preserve transparency
                nsImage.draw(in: NSRect(origin: .zero, size: targetSize),
                           from: NSRect(origin: .zero, size: nsImage.size),
                           operation: .sourceOver,
                           fraction: 1.0)
                
                newImage.unlockFocus()
                
                return newImage
            }
        }
        
        print("❌ Could not load PNG with transparency")
        return nil
    }
}