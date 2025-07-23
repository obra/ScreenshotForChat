// ABOUTME: Core screenshot capture functionality using ScreenCaptureKit API
// ABOUTME: Handles window picker integration and modern screen capture with hardware acceleration

import AppKit
import ScreenCaptureKit
import UniformTypeIdentifiers

@available(macOS 14.0, *)
class CaptureManager: ObservableObject {
    private let settings = AppSettings.shared
    
    func startWindowPicker() {
        print("🎯 Starting window picker...")
        WindowPicker.pick { [weak self] windowID in
            guard let windowID = windowID else {
                print("❌ No window selected")
                return
            }
            print("📋 Selected window ID: \(windowID)")
            Task {
                await self?.captureWindow(windowID: windowID)
            }
        }
    }
    
    func captureFullScreen() {
        print("📸 Starting full screen capture...")
        Task {
            await captureAllScreens()
        }
    }
    
    private func captureWindow(windowID: CGWindowID) async {
        print("📸 Starting ScreenCaptureKit window capture for ID: \(windowID)")
        
        do {
            // Get available content
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // Find the target window
            guard let targetWindow = availableContent.windows.first(where: { $0.windowID == windowID }) else {
                print("❌ Could not find window with ID \(windowID)")
                return
            }
            
            print("✅ Found window: \(targetWindow.title ?? "Untitled")")
            
            // Create content filter for the specific window
            let contentFilter = SCContentFilter(desktopIndependentWindow: targetWindow)
            
            // Configure stream settings
            let config = SCStreamConfiguration()
            
            // Apply HiDPI scaling setting
            if settings.disableHiDPI {
                // Scale down to non-retina resolution
                config.scalesToFit = true
                config.width = Int(targetWindow.frame.width)
                config.height = Int(targetWindow.frame.height)
            } else {
                // Use native resolution
                config.scalesToFit = false
            }
            
            // Flash the window before capture
            await flashWindow(windowID: windowID)
            
            // Capture the screenshot
            let image = try await SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: config)
            
            // Save to file
            let success = await saveImage(image, prefix: "screenshot")
            if success {
                print("✅ Window capture complete")
            }
            
        } catch {
            print("❌ ScreenCaptureKit window capture failed: \(error)")
            print("💡 Make sure Screen Recording permission is enabled in System Preferences")
        }
    }
    
    private func captureAllScreens() async {
        print("📸 Starting ScreenCaptureKit full screen capture...")
        
        do {
            // Get available content
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let primaryDisplay = availableContent.displays.first else {
                print("❌ No displays found")
                return
            }
            
            print("✅ Found display: \(primaryDisplay.width)x\(primaryDisplay.height)")
            
            // Create content filter for the display (exclude nothing to capture everything)
            let contentFilter = SCContentFilter(display: primaryDisplay, excludingWindows: [])
            
            // Configure stream settings
            let config = SCStreamConfiguration()
            
            // Apply HiDPI scaling setting
            if settings.disableHiDPI {
                // Scale down to non-retina resolution
                config.scalesToFit = true
                config.width = Int(primaryDisplay.width / 2) // Assume 2x retina scaling
                config.height = Int(primaryDisplay.height / 2)
            } else {
                // Use native resolution
                config.scalesToFit = false
                config.width = Int(primaryDisplay.width)
                config.height = Int(primaryDisplay.height)
            }
            
            // Flash the screen before capture
            await flashScreen()
            
            // Capture the screenshot
            let image = try await SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: config)
            
            // Save to file
            let success = await saveImage(image, prefix: "screenshot-fullscreen")
            if success {
                print("✅ Full screen capture complete")
            }
            
        } catch {
            print("❌ ScreenCaptureKit full screen capture failed: \(error)")
            print("💡 Make sure Screen Recording permission is enabled in System Preferences")
        }
    }
    
    private func saveImage(_ cgImage: CGImage, prefix: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("\(prefix)-\(UUID().uuidString)")
                    .appendingPathExtension("png")
                
                guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                    print("❌ Failed to create image destination")
                    continuation.resume(returning: false)
                    return
                }
                
                CGImageDestinationAddImage(destination, cgImage, nil)
                
                guard CGImageDestinationFinalize(destination) else {
                    print("❌ Failed to finalize image")
                    continuation.resume(returning: false)
                    return
                }
                
                DispatchQueue.main.async {
                    print("✅ Screenshot saved to \(tempURL.path)")
                    self?.copyToClipboard(path: tempURL.path)
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    private func copyToClipboard(path: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
        print("📋 Path copied to clipboard")
    }
    
    @MainActor
    private func flashWindow(windowID: CGWindowID) async {
        // Get window bounds from Core Graphics
        let windowListInfo = CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID)
        guard let windowInfo = windowListInfo as? [[String: Any]],
              let windowDict = windowInfo.first,
              let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else {
            print("❌ Could not get window bounds for flash effect")
            return
        }
        
        let x = boundsDict["X"] as? CGFloat ?? 0
        let y = boundsDict["Y"] as? CGFloat ?? 0
        let width = boundsDict["Width"] as? CGFloat ?? 100
        let height = boundsDict["Height"] as? CGFloat ?? 100
        
        // Convert from CG coordinates (bottom-left origin) to NSScreen coordinates (top-left origin)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let windowRect = NSRect(x: x, y: screenHeight - y - height, width: width, height: height)
        
        await createFlashEffect(frame: windowRect)
    }
    
    @MainActor
    private func flashScreen() async {
        // Flash all screens
        for screen in NSScreen.screens {
            await createFlashEffect(frame: screen.frame)
        }
    }
    
    @MainActor
    private func createFlashEffect(frame: NSRect) async {
        // Create a borderless window that covers the target area
        let flashWindow = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        // Configure the flash window for more visibility
        flashWindow.backgroundColor = NSColor.white
        flashWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        flashWindow.isOpaque = true
        flashWindow.hasShadow = false
        flashWindow.ignoresMouseEvents = true
        flashWindow.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        
        // Start with the flash window fully opaque
        flashWindow.alphaValue = 1.0
        flashWindow.orderFrontRegardless()
        
        // Animate the flash effect with a more pronounced fade
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            // Hold the full flash for a brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    flashWindow.animator().alphaValue = 0.0
                } completionHandler: {
                    // Ensure cleanup happens on main thread
                    DispatchQueue.main.async {
                        flashWindow.orderOut(nil)
                        continuation.resume()
                    }
                }
            }
        }
    }
}