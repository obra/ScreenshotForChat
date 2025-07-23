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
}