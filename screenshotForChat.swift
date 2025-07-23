// ABOUTME: macOS menubar app for taking window screenshots with Cmd+Shift+0 hotkey
// ABOUTME: Saves screenshots to temp directory and copies path to pasteboard

import AppKit
import UniformTypeIdentifiers
import ImageIO
import Carbon                                   // for the global hot-key

// MARK: –—————————————————————————  App Delegate  ——————————————————————————————

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!             // so the hot-key callback can reach us

    private var statusItem: NSStatusItem!
    private var hotKeyRef: EventHotKeyRef?
    private var fullScreenHotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ note: Notification) {
        Self.shared = self
        print("🚀 App starting...")

        // Run as agent (no Dock/menu) just in case LSUIElement was forgotten.
        NSApp.setActivationPolicy(.accessory)

        // — 1) STATUS-ITEM ———————————————————————————————————————————
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            // Try system symbol first, fallback to text
            if let image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Capture window") {
                btn.image = image
                print("📷 Menubar icon set with system symbol")
            } else {
                btn.title = "📷"
                print("📷 Menubar icon set with emoji fallback")
            }
        } else {
            print("❌ Failed to get status item button")
        }

        // — 2) MENU ————————————————————————————————————————————————
        let menu = NSMenu()
        let captureItem = NSMenuItem(
            title: "Capture Window (⌘⇧0)",
            action: #selector(startPicking),
            keyEquivalent: ""               // Remove key equivalent from menu
        )
        menu.addItem(captureItem)
        
        let fullScreenItem = NSMenuItem(
            title: "Capture Full Screen (⌘⇧9)",
            action: #selector(captureFullScreen),
            keyEquivalent: ""
        )
        menu.addItem(fullScreenItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q")
        )
        statusItem.menu = menu
        print("📋 Menu created with \(menu.items.count) items")

        // — 3) GLOBAL HOT-KEY  (⌘⇧0) ——————————————————————————————
        registerGlobalHotKey()

        print("✅ App setup complete - using Core Graphics for capture")
    }

    // MARK: – Actions —

    @objc private func startPicking() {
        print("🎯 Starting window picker...")
        WindowPicker.pick { winID in
            guard let winID else { 
                print("❌ No window selected")
                return 
            }
            print("📋 Selected window ID: \(winID)")
            print("🔄 About to create capture task...")
            
            // Call capture function directly - no async context
            print("🔄 Calling capture directly...")
            self.captureSimple(windowID: winID)
        }
    }

    @objc private func captureFullScreen() {
        print("📸 Starting full screen capture...")
        captureEntireScreen()
    }
    
    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: – ScreenCaptureKit work —
    
    private func captureSimple(windowID id: CGWindowID) {
        print("📸 Starting simple capture for window ID: \(id)")
        
        // Fall back to Core Graphics - ScreenCaptureKit segfaults in this execution context
        print("🔄 Using Core Graphics fallback due to ScreenCaptureKit segfaults...")
        
        // Get window info using Core Graphics
        let windowListOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(windowListOptions, kCGNullWindowID) as? [[String: Any]] else {
            print("❌ Failed to get window list")
            return
        }
        
        guard let windowInfo = windowList.first(where: { 
            ($0[kCGWindowNumber as String] as? CGWindowID) == id 
        }) else {
            print("❌ Window not found in window list")
            return
        }
        
        guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
              let x = boundsDict["X"], let y = boundsDict["Y"],
              let width = boundsDict["Width"], let height = boundsDict["Height"] else {
            print("❌ Could not get window bounds")
            return
        }
        
        let windowRect = CGRect(x: x, y: y, width: width, height: height)
        print("✅ Found window at \(windowRect)")
        
        // Use system screenshot tool as fallback since both ScreenCaptureKit and CGWindowListCreateImage are problematic
        print("🔄 Using system screencapture tool as fallback...")
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("screenshot-\(UUID().uuidString)")
            .appendingPathExtension("png")
        
        // Use autorelease pool to ensure proper cleanup
        autoreleasepool {
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = [
                "-l\(id)",  // Capture specific window by ID
                "-x",       // Do not play sound
                tempURL.path
            ]
            
            task.launch()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("✅ Screenshot saved to \(tempURL.path)")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tempURL.path, forType: .string)
                print("📋 Path copied to clipboard")
                print("✅ Capture complete - returning safely")
            } else {
                print("❌ screencapture failed with status \(task.terminationStatus)")
            }
        }
    }
    
    private func captureEntireScreen() {
        print("📸 Starting full screen capture...")
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("screenshot-fullscreen-\(UUID().uuidString)")
            .appendingPathExtension("png")
        
        // Use autorelease pool to ensure proper cleanup
        autoreleasepool {
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = [
                "-x",       // Do not play sound
                tempURL.path
            ]
            
            task.launch()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("✅ Full screen screenshot saved to \(tempURL.path)")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tempURL.path, forType: .string)
                print("📋 Path copied to clipboard")
                print("✅ Full screen capture complete")
            } else {
                print("❌ Full screen screencapture failed with status \(task.terminationStatus)")
            }
        }
    }
    
    private func saveImageSync(_ cgImage: CGImage) {
        print("🔄 Saving image...")
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("screenshot-\(UUID().uuidString)")
            .appendingPathExtension("png")
        
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL,
                                                       UTType.png.identifier as CFString,
                                                       1, nil) else {
            print("❌ Failed to create image destination")
            return
        }
        
        CGImageDestinationAddImage(dest, cgImage, nil)
        
        guard CGImageDestinationFinalize(dest) else {
            print("❌ Failed to finalize image")
            return
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
        print("📸 SUCCESS! \(url.path) (path copied to clipboard)")
    }

    // MARK: – Global hot-key (Carbon) —

    private func registerGlobalHotKey() {
        // Register Cmd+Shift+0 for window picker
        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(bitPattern: Int32("SCAP".fourCharCode))),
                                     id: 1)

        let result = RegisterEventHotKey(UInt32(kVK_ANSI_0),
                                        UInt32(cmdKey | shiftKey),
                                        hotKeyID,
                                        GetEventDispatcherTarget(),
                                        0,
                                        &hotKeyRef)
        
        if result == noErr {
            print("⌨️  Global hotkey (⌘⇧0) registered successfully")
        } else {
            print("❌ Failed to register global hotkey (⌘⇧0), error: \(result)")
        }
        
        // Register Cmd+Shift+9 for full screen capture
        let fullScreenHotKeyID = EventHotKeyID(signature: OSType(UInt32(bitPattern: Int32("SCAP".fourCharCode))),
                                               id: 2)

        let fullScreenResult = RegisterEventHotKey(UInt32(kVK_ANSI_9),
                                                  UInt32(cmdKey | shiftKey),
                                                  fullScreenHotKeyID,
                                                  GetEventDispatcherTarget(),
                                                  0,
                                                  &fullScreenHotKeyRef)
        
        if fullScreenResult == noErr {
            print("⌨️  Global hotkey (⌘⇧9) registered successfully")
        } else {
            print("❌ Failed to register global hotkey (⌘⇧9), error: \(fullScreenResult)")
        }

        // Install handler once.
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let handlerResult = InstallEventHandler(GetApplicationEventTarget(), { (_, evt, _) -> OSStatus in
            print("🔥 Hotkey pressed!")
            var hkID = EventHotKeyID()
            let status = GetEventParameter(evt,
                                         EventParamName(kEventParamDirectObject),
                                         EventParamType(typeEventHotKeyID),
                                         nil,
                                         MemoryLayout.size(ofValue: hkID),
                                         nil,
                                         &hkID)
            if status == noErr {
                if hkID.id == 1 {
                    print("✅ Starting window picker...")
                    DispatchQueue.main.async {
                        AppDelegate.shared?.startPicking()
                    }
                } else if hkID.id == 2 {
                    print("✅ Starting full screen capture...")
                    DispatchQueue.main.async {
                        AppDelegate.shared?.captureFullScreen()
                    }
                }
            }
            return noErr
        }, 1, &eventSpec, nil, nil)
        
        if handlerResult == noErr {
            print("✅ Event handler installed successfully")
        } else {
            print("❌ Failed to install event handler, error: \(handlerResult)")
        }
    }
}

// MARK: –——————————————————  Highlight view  ——————————————————————

final class HighlightView: NSView {
    var hoverRect: CGRect = .zero { didSet { needsDisplay = true } }
    var debugCursorPos: CGPoint = .zero { didSet { needsDisplay = true } }
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw window highlight
        if hoverRect != .zero {
            NSColor.systemRed.set()
            let p = NSBezierPath(rect: hoverRect)
            p.lineWidth = 2
            p.stroke()
        }
        
        // Draw debug cursor - small blue circle to show where we think the mouse is
        NSColor.systemBlue.set()
        let cursorRect = CGRect(
            x: debugCursorPos.x - 5,
            y: debugCursorPos.y - 5,
            width: 10,
            height: 10
        )
        let cursorPath = NSBezierPath(ovalIn: cursorRect)
        cursorPath.fill()
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        print("🔍 HIGHLIGHT VIEW: Key pressed with code: \(event.keyCode)")
        // Forward key events to the window
        window?.keyDown(with: event)
    }
}

// MARK: –——————————————————  Picker overlay window  ——————————————————

final class WindowPicker: NSWindow {
    private var completion: (CGWindowID?) -> Void = { _ in }
    private var currentWinID: CGWindowID = 0
    private var highlightView: HighlightView!
    private var selfRetain: WindowPicker? // Keep self alive until completion
    private var previouslyFocusedApp: NSRunningApplication? // App to restore focus to
    private var previouslyFocusedWindowID: CGWindowID? // Window to restore focus to
    private var keyEventMonitor: Any? // Global key event monitor

    static func pick(_ handler: @escaping (CGWindowID?) -> Void) {
        // FIRST: Capture the current focus state BEFORE doing anything else
        let previousApp = NSWorkspace.shared.frontmostApplication
        let previousWindowID = getCurrentlyFocusedWindowID()
        
        if let app = previousApp {
            print("📝 INITIAL: Frontmost app is: \(app.localizedName ?? "Unknown") (bundle: \(app.bundleIdentifier ?? "Unknown"))")
        }
        if let windowID = previousWindowID {
            print("📝 INITIAL: Top window ID: \(windowID)")
        }
        
        // NOW create the overlay
        let allFrame = NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
        let overlay = WindowPicker(contentRect: allFrame,
                                   styleMask: .borderless,
                                   backing: .buffered,
                                   defer: false)

        let hv = HighlightView(frame: CGRect(origin: .zero, size: allFrame.size))
        overlay.contentView = hv
        overlay.highlightView = hv

        overlay.completion = handler
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.level = .modalPanel
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlay.acceptsMouseMovedEvents = true
        overlay.ignoresMouseEvents = false
        overlay.isMovableByWindowBackground = false
        
        // Store the captured focus state
        overlay.previouslyFocusedApp = previousApp
        overlay.previouslyFocusedWindowID = previousWindowID
        
        // Retain self to prevent deallocation during picker operation
        overlay.selfRetain = overlay
        
        // Set up global key event monitor for escape key
        overlay.keyEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            print("🔍 GLOBAL KEY: Key pressed with code: \(event.keyCode)")
            if event.keyCode == 53 { // Escape key
                print("⎋ Global escape detected - canceling picker")
                overlay.handleEscapeKey()
            }
        }
        
        print("🖼️ Created overlay window: \(allFrame)")
        overlay.makeKeyAndOrderFront(nil)
        // Ensure the overlay window becomes key to receive key events
        overlay.becomeKey()
        overlay.makeFirstResponder(hv)
        // Don't activate our app - let the overlay window handle events without stealing app focus
        
        // Debug: Check what happened to focus after showing overlay
        if let currentApp = NSWorkspace.shared.frontmostApplication {
            print("📝 AFTER OVERLAY: Frontmost app is now: \(currentApp.localizedName ?? "Unknown")")
            if currentApp.bundleIdentifier != previousApp?.bundleIdentifier {
                print("⚠️ WARNING: App focus changed from \(previousApp?.localizedName ?? "Unknown") to \(currentApp.localizedName ?? "Unknown")")
            } else {
                print("✅ App focus remained with: \(currentApp.localizedName ?? "Unknown")")
            }
        }
    }
    
    private static func getCurrentlyFocusedWindowID() -> CGWindowID? {
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        guard let windows = windowList as? [[String: Any]] else { return nil }
        
        // Look for the window with the highest layer (most likely to be focused)
        for window in windows.sorted(by: { 
            let layer1 = $0[kCGWindowLayer as String] as? Int ?? 0
            let layer2 = $1[kCGWindowLayer as String] as? Int ?? 0
            return layer1 > layer2
        }) {
            if let windowID = window[kCGWindowNumber as String] as? CGWindowID {
                return windowID
            }
        }
        return nil
    }
    
    private func restorePreviousAppFocus() {
        guard let app = previouslyFocusedApp else {
            print("⚠️ No previous app to restore focus to")
            return
        }
        
        print("🔄 RESTORE: Starting restoration to: \(app.localizedName ?? "Unknown")")
        
        // Check what's currently frontmost before restoration
        if let currentApp = NSWorkspace.shared.frontmostApplication {
            print("🔄 RESTORE: Currently frontmost: \(currentApp.localizedName ?? "Unknown")")
        }
        
        // Use the most direct approach to activate the app
        app.activate(options: [])
        
        // Check if restoration worked
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let nowApp = NSWorkspace.shared.frontmostApplication {
                print("🔄 RESTORE: After restoration, frontmost is: \(nowApp.localizedName ?? "Unknown")")
            }
        }
        
        // If we have a specific window ID, try to bring it to front
        if let windowID = previouslyFocusedWindowID {
            print("🔄 Attempting to restore window \(windowID)")
            // Try to find and focus the specific window using Core Graphics
            let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            if let windows = windowList as? [[String: Any]] {
                for window in windows {
                    if let wID = window[kCGWindowNumber as String] as? CGWindowID, wID == windowID {
                        // Window still exists, try to bring it to front
                        print("✅ Found target window, attempting to focus")
                        break
                    }
                }
            }
        }
    }
    
    // Allow window to become key to receive key events
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    func handleEscapeKey() {
        print("⎋ Handling escape key press")
        
        // Capture completion handler and nullify to prevent double-call
        let handler = completion
        completion = { _ in }
        
        // Clean up key event monitor
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        
        // Restore focus IMMEDIATELY before doing anything else
        print("🔄 IMMEDIATE ESCAPE: Restoring focus before close")
        restorePreviousAppFocus()
        
        close()
        DispatchQueue.main.async {
            print("🔄 ESCAPE COMPLETION: Calling handler")
            handler(nil)
        }
        
        // Release self-retain after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("🔄 ESCAPE CLEANUP: Releasing self-retain")
            self?.selfRetain = nil
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let loc = NSEvent.mouseLocation
        currentWinID = 0
        
        // Convert mouse location to view coordinates for debug cursor
        // NSEvent.mouseLocation gives coordinates in screen space with Y=0 at bottom
        // Our overlay window uses view coordinates with Y=0 at top
        
        // Try without Y flip first to see if NSEvent.mouseLocation is already in view coordinates
        let debugCursorInView = CGPoint(
            x: loc.x - frame.minX,  // Adjust for overlay origin
            y: loc.y - frame.minY   // No Y flip - maybe NSEvent.mouseLocation is already correct
        )
        highlightView.debugCursorPos = debugCursorInView
        
        // Reduced debug logging to prevent memory pressure
        // print("🐛 Mouse at screen(\(loc.x), \(loc.y)) -> view(\(debugCursorInView.x), \(debugCursorInView.y))")
        
        // Get the window directly under the mouse cursor
        let windowUnderCursor = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        guard let windowList = windowUnderCursor as? [[String: Any]] else { 
            highlightView.hoverRect = .zero
            return 
        }
        
        // Sort windows by layer/level - higher levels (front windows) first
        let sortedWindows = windowList.sorted { window1, window2 in
            let layer1 = window1[kCGWindowLayer as String] as? Int ?? 0
            let layer2 = window2[kCGWindowLayer as String] as? Int ?? 0
            return layer1 > layer2
        }
        
        // Find the topmost window that contains the mouse cursor
        for info in sortedWindows {
            guard let winID = info[kCGWindowNumber as String] as? CGWindowID,
                  let b = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"], let w = b["Width"], let h = b["Height"] else { continue }
            
            // Skip our own overlay window
            if winID == windowNumber { continue }
            
            // Skip windows that are too small (likely system elements)
            if w < 50 || h < 50 { continue }
            
            // For hit testing, we need to convert mouse location to CGWindowList coordinate system
            // CGWindowList uses bottom-origin, NSEvent.mouseLocation uses top-origin
            guard let mainScreen = NSScreen.main else { continue }
            let screenHeight = mainScreen.frame.height
            let mouseInCGCoords = CGPoint(x: loc.x, y: screenHeight - loc.y)
            let windowRect = CGRect(x: x, y: y, width: w, height: h)
            
            if windowRect.contains(mouseInCGCoords) {
                currentWinID = winID
                
                // Convert CGWindowList coordinates (bottom-origin) to NSView coordinates (top-origin)
                let convertedRect = CGRect(
                    x: x - frame.minX, 
                    y: frame.maxY - (y + h), 
                    width: w, 
                    height: h
                )
                
                highlightView.hoverRect = convertedRect
                break
            }
        }
        
        if currentWinID == 0 { 
            highlightView.hoverRect = .zero 
        }
    }

    override func mouseDown(with event: NSEvent) { 
        print("🖱️ Mouse clicked! Window ID: \(currentWinID)")
        let selectedID = currentWinID != 0 ? currentWinID : nil
        
        // Capture completion handler and nullify to prevent double-call
        let handler = completion
        completion = { _ in }
        
        // Clean up key event monitor
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        
        // Restore focus IMMEDIATELY before doing anything else
        print("🔄 IMMEDIATE: Restoring focus before close")
        restorePreviousAppFocus()
        
        // Close window 
        close()
        
        // Call completion handler on next run loop cycle
        DispatchQueue.main.async {
            print("🔄 COMPLETION: Calling handler")
            handler(selectedID)
        }
        
        // Release self-retain after a delay to ensure everything completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("🔄 CLEANUP: Releasing self-retain")
            self?.selfRetain = nil
        }
    }
    
    override func keyDown(with event: NSEvent) {
        print("🔍 KEY DEBUG: Key pressed with code: \(event.keyCode)")
        if event.keyCode == 53 { // Escape key
            print("⎋ Escape pressed - canceling")
            
            // Capture completion handler and nullify to prevent double-call
            let handler = completion
            completion = { _ in }
            
            // Restore focus IMMEDIATELY before doing anything else
            print("🔄 IMMEDIATE ESCAPE: Restoring focus before close")
            restorePreviousAppFocus()
            
            close()
            DispatchQueue.main.async {
                print("🔄 ESCAPE COMPLETION: Calling handler")
                handler(nil)
            }
            
            // Release self-retain after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                print("🔄 ESCAPE CLEANUP: Releasing self-retain")
                self?.selfRetain = nil
            }
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func cancelOperation(_ sender: Any?) { 
        print("❌ Operation canceled")
        
        // Capture completion handler and nullify to prevent double-call
        let handler = completion
        completion = { _ in }
        
        // Clean up key event monitor
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        
        // Restore focus IMMEDIATELY before doing anything else
        print("🔄 IMMEDIATE CANCEL: Restoring focus before close")
        restorePreviousAppFocus()
        
        close()
        DispatchQueue.main.async {
            print("🔄 CANCEL COMPLETION: Calling handler")
            handler(nil)
        }
        
        // Release self-retain after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("🔄 CANCEL CLEANUP: Releasing self-retain")
            self?.selfRetain = nil
        }
    }
}

// ————————————————————————————————————————————————————————————————————————
// Helper to build a four-char code from a String, e.g. "SCAP".
// ————————————————————————————————————————————————————————————————————————
fileprivate extension String {
    var fourCharCode: OSType {
        var result: OSType = 0
        for scalar in unicodeScalars.prefix(4) { result = (result << 8) + OSType(scalar.value) }
        return result
    }
}

// MARK: – Main Entry Point —

func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    
    print("🚀 Starting screenshot app...")
    app.run()
}

main()
