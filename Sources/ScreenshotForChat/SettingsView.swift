// ABOUTME: SwiftUI settings panel with keyboard shortcuts and HiDPI toggle
// ABOUTME: Uses KeyboardShortcuts.Recorder for native macOS key binding UI

import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    // App icon from bundle
                    if let appIcon = loadAppIcon() {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    } else {
                        // Fallback to system icons
                        HStack(spacing: 2) {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(.accentColor)
                                .font(.title)
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                                .font(.footnote)
                                .offset(x: -6, y: -6)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screenshot for Chat")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Modern macOS screenshot tool for chat sharing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            
            Divider()
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // General Settings
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            Text("General")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 14) {
                            LaunchAtLogin.Toggle()
                                .toggleStyle(.checkbox)
                            
                            Toggle("Disable HiDPI scaling", isOn: $settings.disableHiDPI)
                                .toggleStyle(.checkbox)
                                .help("When enabled, screenshots will not be scaled for retina displays")
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Screenshot Location")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text(NSTemporaryDirectory().replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.leading, 24)
                    }
                    
                    // Keyboard Shortcuts
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            Text("Keyboard Shortcuts")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Window Capture")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Select and capture a specific window")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    KeyboardShortcuts.Recorder(for: .windowCapture)
                                }
                            }
                            
                            Divider()
                                .padding(.horizontal, 12)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Full Screen Capture")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Capture the entire screen")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    KeyboardShortcuts.Recorder(for: .fullScreenCapture)
                                }
                            }
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text("Global shortcuts work from any application")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.leading, 24)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Divider()
                .padding(.horizontal, 24)
            
            // Copyright and License
            VStack(alignment: .leading, spacing: 6) {
                Text("Copyright 2025 Jesse Vincent <jesse@fsck.com>")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Distributed under the MIT License. You're free to use, modify, and share this software.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Link("GitHub Repository", destination: URL(string: "https://github.com/obra/screenshotForChat")!)
                    .font(.caption)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 520, height: 548)
    }
    
    private func loadAppIcon() -> NSImage? {
        // Try to load the app icon from the bundle
        if let appIcon = NSApp.applicationIconImage {
            return appIcon
        }
        
        // Fallback: try to load directly from resources
        guard let resourcePath = Bundle.main.resourcePath else {
            return nil
        }
        
        let iconPath = "\(resourcePath)/ScreenshotForChat.icns"
        return NSImage(contentsOfFile: iconPath)
    }
}


#Preview {
    SettingsView()
}