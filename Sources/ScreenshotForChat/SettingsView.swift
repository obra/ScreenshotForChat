// ABOUTME: SwiftUI settings panel with keyboard shortcuts and HiDPI toggle
// ABOUTME: Uses KeyboardShortcuts.Recorder for native macOS key binding UI

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Image(systemName: "camera.viewfinder")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                Text("Screenshot for Chat")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // General Settings
            VStack(alignment: .leading, spacing: 16) {
                Text("General")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Disable HiDPI scaling", isOn: $settings.disableHiDPI)
                        .help("When enabled, screenshots will not be scaled for retina displays")
                    
                    HStack {
                        Text("Screenshots saved to:")
                        Spacer()
                        Text(NSTemporaryDirectory())
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            // Keyboard Shortcuts
            VStack(alignment: .leading, spacing: 16) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Window Capture:")
                            .frame(width: 140, alignment: .trailing)
                        KeyboardShortcuts.Recorder(for: .windowCapture)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("Full Screen Capture:")
                            .frame(width: 140, alignment: .trailing)
                        KeyboardShortcuts.Recorder(for: .fullScreenCapture)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Text("Global shortcuts work from any application")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Copyright and License
            VStack(alignment: .leading, spacing: 4) {
                Text("Copyright 2025 Jesse Vincent <jesse@fsck.com>")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Distributed under the MIT License. You're free to use, modify, and share this software.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(width: 500, height: 400)
    }
}


#Preview {
    SettingsView()
}