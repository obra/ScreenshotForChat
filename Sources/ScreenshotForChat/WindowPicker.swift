// ABOUTME: Window picker overlay for selecting specific windows to capture
// ABOUTME: Handles mouse events, window highlighting, and focus restoration

import AppKit

final class WindowPicker: NSWindow {
    private var completion: (CGWindowID?) -> Void = { _ in }
    private var currentWinID: CGWindowID = 0
    private var highlightView: HighlightView!
    private var selfRetain: WindowPicker?
    private var previouslyFocusedApp: NSRunningApplication?
    private var previouslyFocusedWindowID: CGWindowID?
    private var keyEventMonitor: Any?

    static func pick(_ handler: @escaping (CGWindowID?) -> Void) {
        // Capture current focus state before showing overlay
        let previousApp = NSWorkspace.shared.frontmostApplication
        let previousWindowID = getCurrentlyFocusedWindowID()
        
        if let app = previousApp {
            print("📝 INITIAL: Frontmost app is: \(app.localizedName ?? "Unknown")")
        }
        
        // Create overlay window
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
        
        // Store focus state
        overlay.previouslyFocusedApp = previousApp
        overlay.previouslyFocusedWindowID = previousWindowID
        
        // Self-retain to prevent deallocation
        overlay.selfRetain = overlay
        
        // Set up dual key monitoring for maximum reliability
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            print("🔍 Global key event - keyCode: \(event.keyCode)")
            if event.keyCode == 53 { // Escape key
                print("⎋ Global escape detected - canceling picker")
                overlay.handleEscapeKey()
            }
        }
        
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            print("🔍 Local key event - keyCode: \(event.keyCode)")
            if event.keyCode == 53 { // Escape key
                print("⎋ Local escape detected - canceling picker")
                overlay.handleEscapeKey()
                return nil // Don't pass the event along
            }
            return event
        }
        
        overlay.keyEventMonitor = globalMonitor
        
        // Store both monitors for cleanup
        if let global = globalMonitor, let local = localMonitor {
            overlay.keyEventMonitor = [global, local] as Any
        }
        
        print("🖼️ Created overlay window: \(allFrame)")
        overlay.makeKeyAndOrderFront(nil)
        
        // Ensure proper focus and key handling
        DispatchQueue.main.async {
            overlay.becomeKey()
            overlay.makeFirstResponder(hv)
            
            // Force app activation to ensure key events are received
            NSApp.activate(ignoringOtherApps: true)
            print("🎯 Overlay window activated and made key")
        }
    }
    
    private static func getCurrentlyFocusedWindowID() -> CGWindowID? {
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        guard let windows = windowList as? [[String: Any]] else { return nil }
        
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
        
        print("🔄 Restoring focus to: \(app.localizedName ?? "Unknown")")
        app.activate(options: [])
    }
    
    // Allow window to become key for key events
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    func handleEscapeKey() {
        print("⎋ Handling escape key press")
        
        let handler = completion
        completion = { _ in }
        
        if let monitors = keyEventMonitor as? [Any] {
            for monitor in monitors {
                NSEvent.removeMonitor(monitor)
            }
            keyEventMonitor = nil
        } else if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        
        restorePreviousAppFocus()
        close()
        
        DispatchQueue.main.async {
            handler(nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.selfRetain = nil
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let loc = NSEvent.mouseLocation
        currentWinID = 0
        
        
        // Find window under cursor
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        guard let windows = windowList as? [[String: Any]] else { 
            highlightView.hoverRect = .zero
            return 
        }
        
        // Sort by layer (front windows first)
        let sortedWindows = windows.sorted { window1, window2 in
            let layer1 = window1[kCGWindowLayer as String] as? Int ?? 0
            let layer2 = window2[kCGWindowLayer as String] as? Int ?? 0
            return layer1 > layer2
        }
        
        // Find topmost window containing cursor
        for info in sortedWindows {
            guard let winID = info[kCGWindowNumber as String] as? CGWindowID,
                  let b = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"], let w = b["Width"], let h = b["Height"] else { continue }
            
            // Skip our overlay and small windows
            if winID == windowNumber || w < 50 || h < 50 { continue }
            
            // Convert coordinates for hit testing
            guard let mainScreen = NSScreen.main else { continue }
            let screenHeight = mainScreen.frame.height
            let mouseInCGCoords = CGPoint(x: loc.x, y: screenHeight - loc.y)
            let windowRect = CGRect(x: x, y: y, width: w, height: h)
            
            if windowRect.contains(mouseInCGCoords) {
                currentWinID = winID
                
                // Convert to view coordinates for display
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
        
        let handler = completion
        completion = { _ in }
        
        if let monitors = keyEventMonitor as? [Any] {
            for monitor in monitors {
                NSEvent.removeMonitor(monitor)
            }
            keyEventMonitor = nil
        } else if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
        
        restorePreviousAppFocus()
        close()
        
        DispatchQueue.main.async {
            handler(selectedID)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.selfRetain = nil
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            handleEscapeKey()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        handleEscapeKey()
    }
}

// MARK: - Highlight View

final class HighlightView: NSView {
    var hoverRect: CGRect = .zero { didSet { needsDisplay = true } }
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw window highlight
        if hoverRect != .zero {
            NSColor.systemRed.set()
            let path = NSBezierPath(rect: hoverRect)
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        window?.keyDown(with: event)
    }
}