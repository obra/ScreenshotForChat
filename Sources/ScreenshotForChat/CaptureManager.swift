// ABOUTME: Core screenshot capture functionality managing window picker and screen capture
// ABOUTME: Integrates with system screencapture tool and handles file management

import AppKit
import UniformTypeIdentifiers

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
            self?.captureWindow(windowID: windowID)
        }
    }
    
    func captureFullScreen() {
        print("📸 Starting full screen capture...")
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("screenshot-fullscreen-\(UUID().uuidString)")
            .appendingPathExtension("png")
        
        autoreleasepool {
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            
            var arguments = ["-x"] // Do not play sound
            
            // Add HiDPI flag if disabled
            if settings.disableHiDPI {
                arguments.append("-R")
            }
            
            arguments.append(tempURL.path)
            task.arguments = arguments
            
            task.launch()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("✅ Full screen screenshot saved to \(tempURL.path)")
                copyToClipboard(path: tempURL.path)
                print("✅ Full screen capture complete")
            } else {
                print("❌ Full screen screencapture failed with status \(task.terminationStatus)")
            }
        }
    }
    
    private func captureWindow(windowID: CGWindowID) {
        print("📸 Starting window capture for ID: \(windowID)")
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("screenshot-\(UUID().uuidString)")
            .appendingPathExtension("png")
        
        autoreleasepool {
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            
            var arguments = [
                "-l\(windowID)", // Capture specific window by ID
                "-x"             // Do not play sound
            ]
            
            // Add HiDPI flag if disabled
            if settings.disableHiDPI {
                arguments.append("-R")
            }
            
            arguments.append(tempURL.path)
            task.arguments = arguments
            
            task.launch()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("✅ Window screenshot saved to \(tempURL.path)")
                copyToClipboard(path: tempURL.path)
                print("✅ Window capture complete")
            } else {
                print("❌ Window screencapture failed with status \(task.terminationStatus)")
            }
        }
    }
    
    private func copyToClipboard(path: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
        print("📋 Path copied to clipboard")
    }
}