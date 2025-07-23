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
        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(bitPattern: Int32("SCAP".fourCharCode))),
                                     id: 1)

        // cmdKey | shiftKey
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_0),
                                        UInt32(cmdKey | shiftKey),
                                        hotKeyID,
                                        GetEventDispatcherTarget(),
                                        0,
                                        &hotKeyRef)
        
        if result == noErr {
            print("⌨️  Global hotkey (⌘⇧0) registered successfully")
        } else {
            print("❌ Failed to register global hotkey, error: \(result)")
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
            if status == noErr && hkID.id == 1 {
                print("✅ Starting window picker...")
                DispatchQueue.main.async {
                    AppDelegate.shared?.startPicking()
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
}

// MARK: –——————————————————  Picker overlay window  ——————————————————

final class WindowPicker: NSWindow {
    private var completion: (CGWindowID?) -> Void = { _ in }
    private var currentWinID: CGWindowID = 0
    private var highlightView: HighlightView!

    static func pick(_ handler: @escaping (CGWindowID?) -> Void) {
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
        
        print("🖼️ Created overlay window: \(allFrame)")
        overlay.makeKeyAndOrderFront(nil)
        overlay.makeFirstResponder(hv)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func mouseMoved(with event: NSEvent) {
        let loc = NSEvent.mouseLocation
        currentWinID = 0
        
        // Convert mouse location to view coordinates for debug cursor
        // NSEvent.mouseLocation gives coordinates in screen space with Y=0 at bottom
        // Our overlay window uses view coordinates with Y=0 at top
        guard let mainScreen = NSScreen.main else { return }
        let screenFrame = mainScreen.frame
        
        // Try without Y flip first to see if NSEvent.mouseLocation is already in view coordinates
        let debugCursorInView = CGPoint(
            x: loc.x - frame.minX,  // Adjust for overlay origin
            y: loc.y - frame.minY   // No Y flip - maybe NSEvent.mouseLocation is already correct
        )
        highlightView.debugCursorPos = debugCursorInView
        
        print("🐛 Mouse at screen(\(loc.x), \(loc.y)) -> view(\(debugCursorInView.x), \(debugCursorInView.y))")
        
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
                
                print("🔍 DEBUG: Window \(winID) bounds from CGWindowList: (\(x), \(y), \(w), \(h))")
                print("🔍 DEBUG: Mouse location from NSEvent: (\(loc.x), \(loc.y))")
                print("🔍 DEBUG: Overlay frame: \(frame)")
                
                // Try different Y coordinate conversions to see which works
                let option1 = CGRect(x: x - frame.minX, y: y - frame.minY, width: w, height: h)
                let option2 = CGRect(x: x - frame.minX, y: frame.maxY - (y + h), width: w, height: h) 
                let option3 = CGRect(x: x - frame.minX, y: frame.maxY - y, width: w, height: h)
                
                print("🔍 DEBUG: Option 1 (no Y flip): \(option1)")
                print("🔍 DEBUG: Option 2 (flip with height): \(option2)")  
                print("🔍 DEBUG: Option 3 (flip without height): \(option3)")
                
                // Use option 2 - CGWindowList uses bottom-origin, NSView uses top-origin  
                let convertedRect = option2
                
                highlightView.hoverRect = convertedRect
                print("🎯 Using option 2 for window \(winID)")
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
        close()  // Close immediately, don't defer
        completion(selectedID)
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            print("⎋ Escape pressed - canceling")
            completion(nil)
            close()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func cancelOperation(_ sender: Any?) { 
        print("❌ Operation canceled")
        completion(nil)
        close() 
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
