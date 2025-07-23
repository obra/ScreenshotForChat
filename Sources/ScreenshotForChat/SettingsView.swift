// ABOUTME: SwiftUI settings panel with keyboard shortcuts and HiDPI toggle
// ABOUTME: Uses KeyboardShortcuts.Recorder for native macOS key binding UI

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 300)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Disable HiDPI scaling (use -R flag)", isOn: $settings.disableHiDPI)
                    .help("When enabled, screenshots will not be scaled for retina displays")
                
                HStack {
                    Text("Screenshots saved to:")
                    Spacer()
                    Text(NSTemporaryDirectory())
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ShortcutsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
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
            
            Spacer()
            
            Text("Global shortcuts work from any application")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}