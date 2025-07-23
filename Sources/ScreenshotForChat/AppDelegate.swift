// ABOUTME: AppDelegate handles global hotkeys, menubar, and application lifecycle
// ABOUTME: Creates NSStatusItem menubar and manages keyboard shortcuts

import AppKit
import SwiftUI
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    private let captureManager: CaptureManager = {
        if #available(macOS 14.0, *) {
            return CaptureManager()
        } else {
            fatalError("ScreenCaptureKit requires macOS 14.0 or later")
        }
    }()
    private var statusItem: NSStatusItem!
    private var settingsWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Screenshot for Chat starting...")
        
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
            if let image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Screenshot") {
                button.image = image
            } else {
                button.title = "📷"
            }
        }
        
        let menu = NSMenu()
        
        // Get current shortcuts for display
        let windowShortcut = KeyboardShortcuts.getShortcut(for: .windowCapture)
        let fullScreenShortcut = KeyboardShortcuts.getShortcut(for: .fullScreenCapture)
        
        let windowItem = NSMenuItem(title: "Capture Window", action: #selector(captureWindow), keyEquivalent: "")
        if let shortcut = windowShortcut {
            windowItem.title = "Capture Window (\(shortcut.description))"
        }
        menu.addItem(windowItem)
        
        let fullScreenItem = NSMenuItem(title: "Capture Full Screen", action: #selector(captureFullScreen), keyEquivalent: "")
        if let shortcut = fullScreenShortcut {
            fullScreenItem.title = "Capture Full Screen (\(shortcut.description))"
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
        if settingsWindowController == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.contentViewController = hostingController
            window.center()
            
            settingsWindowController = NSWindowController(window: window)
        }
        
        settingsWindowController?.showWindow(nil)
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
}